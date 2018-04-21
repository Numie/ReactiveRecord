class Relation
  attr_accessor :model_name, :select_line, :from_line, :joins_line, :joined_models, :where_line, :where_vals,
  :group_line, :having_line, :having_vals, :order_line, :limit_line, :offset_line, :query_string

  def initialize
  end

  def execute
    query_lines = [
      "SELECT #{@select_line || '*'}",
      "FROM #{@from_line}",
      "#{@joins_line}",
      @where_line ? "WHERE #{@where_line}" : nil,
      @group_line ? "GROUP BY #{@group_line}" : nil,
      @having_line ? "HAVING #{@having_line}" : nil,
      @order_line ? "ORDER BY #{@order_line}" : nil,
      @limit_line ? "LIMIT #{@limit_line}" : nil,
      @offset_line ? "OFFSET #{@offset_line}" : nil
    ]

    constructed_query_string = ""
    query_lines.each do |line|
      constructed_query_string += "#{line}\n" unless line.nil? || line == "    "
    end

    query_string = self.query_string || constructed_query_string.chomp

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

    return hashes if self.group_line || self.joins_line

    #create array of objects from each hash
    hashes.map { |hash| self.model_name.new(hash) }
  end

  def method_missing(method, *args)
    arr = self.execute

    if (Array.instance_methods - Object.instance_methods).include?(method)
      arr.send(method, *args)
    else
      super
    end
  end

  def joins(association)
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
      joins_line = "INNER JOIN #{join_table_name} ON #{joined_model.table_name}.#{foreign_key} = #{join_table_name}.id"
    else
      joins_line = "INNER JOIN #{join_table_name} ON #{joined_model.table_name}.id = #{join_table_name}.#{foreign_key}"
    end

    if self.joins_line
      self.joins_line += "\n#{joins_line}"
    else
      self.joins_line = "#{joins_line}"
    end

    self.joined_models << join_class_name.constantize
    source_association ? self.joins(source_association) : self
  end

  def where(params, *args)
    #create the string of where conditions
    if params.is_a?(Hash)
      where_line = params.keys.map { |param| "#{param} = ?"}.join(" AND ")
      vals = params.values
    elsif args
      where_line = params
      vals = args
    elsif params.is_a?(String)
      where_line = params
      vals = []
    else
      raise 'RubyORGem Error'
    end

    self.where_line ? self.where_line += (" AND " + where_line) : self.where_line = where_line
    self.where_vals ? self.where_vals += vals : self.where_vals = vals
    self
  end

  def group(col)
    if col.is_a?(String)
      group_line = col
    else
      group_line = col.to_s
    end

    self.group_line = group_line
    self
  end

  def having(params, *args)
    #create the string of having conditions
    if params.is_a?(Hash)
      having_line = params.keys.map { |param| "#{param} = ?"}.join(" AND ")
      vals = params.values
    elsif args
      having_line = params
      vals = args
    elsif params.is_a?(String)
      having_line = params
      vals = []
    else
      raise 'RubyORGem Error'
    end

    self.having_line ? self.having_line += (" AND " + having_line) : self.having_line = having_line
    self.having_vals ? self.having_vals += vals : self.having_vals = vals
    self
  end

  def order(*cols)
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
    self.limit_line = n
    self
  end

  def offset(n)
    self.offset_line = n
    self
  end
end
