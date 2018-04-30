require_relative 'errors'
require 'byebug'

module ReactiveRecord
  class Relation
    attr_accessor :model_name, :select_line, :distinct_line, :from_line, :joins_line, :joined_models,
    :where_line, :where_vals, :group_line, :having_line, :having_vals, :order_line, :limit_line,
    :offset_line, :query_string, :calc, :included, :null_relation

    def initialize
    end

    def execute
      return [] if self.null_relation
      if !self.query_string
        default_selects = []
        self.joined_models.each do |model|
          table_name = model.table_name
          singular_name = model.to_s.downcase
          model.columns.each do |column|
            default_selects << "#{table_name}.#{column.to_s} AS #{singular_name}_#{column.to_s}"
          end
        end

        default_select_line = (self.group_line || self.joins_line) ? default_selects.join(', ') : '*'

        query_lines = [
          "SELECT #{@distinct ? 'DISTINCT ' : ''}#{@select_line || default_select_line}",
          "FROM #{@from_line}",
          @joins_line ? "#{@joins_line}" : nil,
          @where_line ? "WHERE #{@where_line}" : nil,
          @group_line ? "GROUP BY #{@group_line}" : nil,
          @having_line ? "HAVING #{@having_line}" : nil,
          @order_line ? "ORDER BY #{@order_line}" : nil,
          @limit_line ? "LIMIT #{@limit_line}" : nil,
          @offset_line ? "OFFSET #{@offset_line}" : nil
        ]

        constructed_query_string = ""
        query_lines.each do |line|
          constructed_query_string += "#{line}\n" unless line.nil?
        end

        self.query_string = constructed_query_string.chomp
      end

      where_vals = self.where_vals
      having_vals = self.having_vals

      if having_vals.nil?
        vals = where_vals
      elsif where_vals.nil?
        vals = having_vals
      else
        vals = where_vals + having_vals
      end

      hashes = DBConnection.execute(<<-SQL, vals)
#{query_string}
      SQL

      if self.included
        self.includes_execute(hashes)
      else
        return hashes if self.group_line || self.joins_line || self.calc
        #create array of objects from each hash
        objects = hashes.map { |hash| self.model_name.new(hash) }
      end
    end

    def includes_execute(hashes)
      #create array of objects from each hash
      objects = hashes.map { |hash| self.model_name.new(hash) }

      self.included.each do |assoc, data|
        foreign_key = data[:foreign_key]
        table_name = data[:table_name]
        model = data[:model]
        type = data[:type]

        if type == :belongs_to
          foreign_keys = hashes.map { |hash| hash["#{model.name.downcase}.#{foreign_key.to_s}"] || hash["#{foreign_key.to_s}"] }
        else
          ids = hashes.map { |hash| hash["#{model.name.downcase}_id"] || hash["id"] }
        end

        vals = type == :belongs_to ? foreign_keys.uniq : ids.uniq
        included_where_string = vals.map { |val| '?' }.join(', ')
        where_col = type == :belongs_to ? "#{table_name}.id" : "#{table_name}.#{foreign_key}"

        included_hashes = DBConnection.execute(<<-SQL, vals)
SELECT *
FROM #{table_name}
WHERE #{where_col} IN (#{included_where_string})
        SQL

        hashes = included_hashes
        included_objects = included_hashes.map { |hash| model.new(hash) }

        objects.each do |object|
          if type == :belongs_to
            if object.respond_to?(foreign_key)
              object.send(:association_cache)[assoc] = included_objects.select { |obj| obj.id == object.send(foreign_key) }
            else
              matched_objects = []
              object.send(:association_cache).each do |cached_assoc_name, cached_asoc_vals|
                if cached_asoc_vals.first && cached_asoc_vals.first.respond_to?(foreign_key)
                  cached_foreign_keys = cached_asoc_vals.map { |cached_obj| cached_obj.send(foreign_key) }
                  matched_objects = included_objects.select { |obj| cached_foreign_keys.include?(obj.id) }
                end
              end
              object.send(:association_cache)[assoc] = matched_objects
            end
          else
            object.send(:association_cache)[assoc] = included_objects.select { |obj| obj.send(foreign_key) == object.id }
          end
        end
      end

      objects
    end

    def method_missing(method, *args, &block)
      if Array.method_defined?(method)
        arr = self.execute
        arr.send(method, *args, &block)
      else
        super
      end
    end

    def pluck(*cols)
      return ReactiveRecord::ArgumentError.new("pluck only accepts Symbols as arguments") unless cols.all? { |col| col.is_a?(Symbol) }
      result = self.execute
      if cols.length == 1
        result.map { |obj| obj.send(cols.first) }
      else
        result_arr = []
        result.each do |obj|
          obj_arr = []
          cols.each do |col|
            obj_arr << obj.send(col)
          end
          result_arr << obj_arr
        end
        result_arr
      end
    end

    def distinct
      return if self.null_relation
      self.distinct_line = true
      self
    end

    def joins(association)
      return if self.null_relation
      self.base_joins(association, "INNER JOIN")
    end

    def left_outer_joins(association)
      return if self.null_relation
      self.base_joins(association, "LEFT OUTER JOIN")
    end

    def base_joins(association, join_type)
      joined_model = nil
      source_association = nil
      self.joined_models.each do |model|
        if model.assoc_options[association]
          joined_model = model
        end
      end

      if !joined_model
        self.joined_models.each do |model|
          if model.through_options[association]
            joined_model = model
            source_association = model.through_options[association].source_name
            association = model.through_options[association].through_name
          end
        end
      end

      raise "#{association} is not a valid association." unless joined_model

      join_class_name = joined_model.assoc_options[association].class_name
      join_table_name = join_class_name.constantize.table_name

      foreign_key = joined_model.assoc_options[association].foreign_key
      type = joined_model.columns.include?(foreign_key) ? :belongs_to : :has_many

      if type == :belongs_to
        joins_line = "#{join_type} #{join_table_name} ON #{joined_model.table_name}.#{foreign_key} = #{join_table_name}.id"
      else
        joins_line = "#{join_type} #{join_table_name} ON #{joined_model.table_name}.id = #{join_table_name}.#{foreign_key}"
      end

      if self.joins_line
        self.joins_line += "\n#{joins_line}"
      else
        self.joins_line = "#{joins_line}"
      end

      self.joined_models << join_class_name.constantize
      source_association ? self.base_joins(source_association, join_type) : self
    end

    def where(params=nil, *args)
      return if self.null_relation
      return self unless params
      #create the string of where conditions
      if params.is_a?(Hash)
        vals = []
        where_line = params.map do |param, val|
          if val.is_a?(Range)
            vals += [val.first, val.last]
            "#{param} BETWEEN ? AND ?"
          elsif val.is_a?(Array)
            #create correct number of question marks
            question_marks = val.map { |c| "?" }.join(", ")
            vals += val
            "#{param} IN (#{question_marks})"
          elsif val.is_a?(Hash)
            if val[:>] || val[:<] || val[:>=] || val[:<=]
              vals << val.values.first
              "#{param} #{val.keys.first.to_s} ?"
            else
              raise ReactiveRecord::ArgumentError.new("You passed a key of #{val.keys.first}. Keys may only be comparison operators like :<")
            end
          else
            vals << val
            "#{param} = ?"
          end
        end.join(" AND ")
      elsif args
        where_line = params
        vals = args
      elsif params.is_a?(String)
        where_line = params
        vals = []
      else
        raise 'ReactiveRecord Error'
      end

      self.where_line ? self.where_line += (" AND " + where_line) : self.where_line = where_line
      self.where_vals ? self.where_vals += vals : self.where_vals = vals
      self
    end

    def not(params, *args)
      return if self.null_relation
      #create the string of where conditions
      if params.is_a?(Hash)
        vals = []
        where_line = params.map do |param, val|
          if val.is_a?(Range)
            vals += [val.first, val.last]
            "#{param} NOT BETWEEN ? AND ?"
          elsif val.is_a?(Array)
            #create correct number of question marks
            question_marks = val.map { |c| "?" }.join(", ")
            vals += val
            "#{param} NOT IN (#{question_marks})"
          else
            vals << val
            "#{param} != ?"
          end
        end.join(" AND ")
      elsif args
        where_line = params
        vals = args
      elsif params.is_a?(String)
        where_line = params
        vals = []
      else
        raise 'ReactiveRecord Error'
      end

      self.where_line ? self.where_line += (" AND " + where_line) : self.where_line = where_line
      self.where_vals ? self.where_vals += vals : self.where_vals = vals
      self
    end

    def or(relation)
      return if self.null_relation
      raise ReactiveRecord::ArgumentError.new("You have passed a #{relation.class} object to #or. Pass a ReactiveRecord::Relation object instead.") unless relation.is_a?(ReactiveRecord::Relation)

      self.where_line += (" OR " + relation.where_line)
      self.where_vals += relation.where_vals
      self
    end

    def group(col)
      return if self.null_relation
      if col.is_a?(String)
        group_line = col
      else
        group_line = col.to_s
      end

      self.group_line = group_line
      self
    end

    def having(params, *args)
      return if self.null_relation
      #create the string of having conditions
      if params.is_a?(Hash)
        vals = []
        having_line = params.map do |param, val|
          if val.is_a?(Range)
            vals += [val.first, val.last]
            "#{param} BETWEEN ? AND ?"
          elsif val.is_a?(Array)
            #create correct number of question marks
            question_marks = val.map { |c| "?" }.join(", ")
            vals += val
            "#{param} IN (#{question_marks})"
          else
            vals << val
            "#{param} = ?"
          end
        end.join(" AND ")
      elsif args
        having_line = params
        vals = args
      elsif params.is_a?(String)
        having_line = params
        vals = []
      else
        raise 'ReactiveRecord Error'
      end

      self.having_line ? self.having_line += (" AND " + having_line) : self.having_line = having_line
      self.having_vals ? self.having_vals += vals : self.having_vals = vals
      self
    end

    def order(*cols)
      return if self.null_relation
      if cols.is_a?(String)
        order_by_line = cols
      else
        string_cols = cols.map do |col|
          if col.is_a?(Hash)
            col.flatten(&:to_s).join(" ")
          else
            col.to_s
          end
        end
        order_by_line = string_cols.join(", ")
      end

      self.order_line ? self.order_line += (", " + order_by_line) : self.order_line = order_by_line
      self
    end

    def limit(n)
      return if self.null_relation
      self.limit_line = n
      self
    end

    def offset(n)
      return if self.null_relation
      self.offset_line = n
      self
    end

    def exists?
      result = self.execute
      !result.empty?
    end

    def count(col=nil)
      return if self.null_relation
      if !col
        val = "*"
      elsif col.is_a?(String)
        val = col
      elsif col.is_a?(Symbol)
        val = "#{self.from_line}.#{col.to_s}"
      else
        raise ReactiveRecord::ArgumentError.new("You have passed a #{col.class} object to #count. Pass a String or a Symbol instead.")
      end

      self.select_line ? self.select_line += ", COUNT(#{val})" : self.select_line = "COUNT(#{val})"
      self.calc = true
      self
    end

    def average(col)
      return if self.null_relation
      if col.is_a?(String)
        val = col
      elsif col.is_a?(Symbol)
        val = "#{self.from_line}.#{col.to_s}"
      else
        raise ReactiveRecord::ArgumentError.new("You have passed a #{col.class} object to #average. Pass a String or a Symbol instead.")
      end

      self.select_line ? self.select_line += ", AVG(#{val})" : self.select_line = "AVG(#{val})"
      self.calc = true
      self
    end

    def minimum(col)
      return if self.null_relation
      if col.is_a?(String)
        val = col
      elsif col.is_a?(Symbol)
        val = "#{self.from_line}.#{col.to_s}"
      else
        raise ReactiveRecord::ArgumentError.new("You have passed a #{col.class} object to #minimum. Pass a String or a Symbol instead.")
      end

      self.select_line ? self.select_line += ", MIN(#{val})" : self.select_line = "MIN(#{val})"
      self.calc = true
      self
    end

    def maximum(col)
      return if self.null_relation
      if col.is_a?(String)
        val = col
      elsif col.is_a?(Symbol)
        val = "#{self.from_line}.#{col.to_s}"
      else
        raise ReactiveRecord::ArgumentError.new("You have passed a #{col.class} object to #maximum. Pass a String or a Symbol instead.")
      end

      self.select_line ? self.select_line += ", MAX(#{val})" : self.select_line = "MAX(#{val})"
      self.calc = true
      self
    end

    def sum(col)
      return if self.null_relation
      if col.is_a?(String)
        val = col
      elsif col.is_a?(Symbol)
        val = "#{self.from_line}.#{col.to_s}"
      else
        raise ReactiveRecord::ArgumentError.new("You have passed a #{col.class} object to #sum. Pass a String or a Symbol instead.")
      end

      self.select_line ? self.select_line += ", SUM(#{val})" : self.select_line = "SUM(#{val})"
      self.calc = true
      self
    end
  end
end
