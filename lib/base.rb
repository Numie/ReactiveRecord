require_relative 'db_connection'
require_relative 'searchable'
require_relative 'calculatable'
require_relative 'associatable'
require_relative 'relation'
require_relative 'validatable'
require_relative 'errors'
require 'active_support/inflector'

module ReactiveRecord
  class Base
    extend Searchable
    extend Calculatable
    extend Associatable
    include Validatable

    def self.columns
      return @columns if @columns

      #returns a nested array, the first element of which is an array of column names
      table_info = DBConnection.execute2(<<-SQL)
SELECT *
FROM #{self.table_name}
      SQL

      #returns a list of column names as symbols
      @columns = table_info.first.map(&:to_sym)
    end

    def self.finalize!
      cols = self.columns

      cols.each do |col|
        #define getter
        define_method(col) do
          val = self.attributes[col]
          # raise ReactiveModel::MissingAttribute.new("Missing attribute: #{col}") unless val
          val
        end

        #define setter
        #attributes will return a hash of column names and values
        define_method("#{col}=") do |val|
          self.attributes[col] = val
        end
      end
      #finalize will be called at end of sublcass definitions to define getters and setters
    end

    #sets table name
    #use to overwrite built in pluralize method (e.g. human => humen)
    def self.table_name=(table_name)
      @name = table_name
    end

    #gets table name or converts it to snake case
    def self.table_name
      @name || self.name.underscore.pluralize
    end

    def self.parse_all(results)
      #creates a new object from each hash
      results.map { |hash| self.new(hash) }
    end

    def self.all
      relation = ReactiveRecord::Relation.new
      relation.model_name, relation.from_line, relation.joined_models = self.name.constantize, self.table_name, [self.name.constantize]
      relation
    end

    def self.find(ids)
      ids = [ids] if ids.is_a?(Integer)
      result = []
      ids.each do |id|
        hash = DBConnection.execute(<<-SQL, id)
SELECT *
FROM #{self.table_name}
WHERE id = ?
        SQL
        raise ReactiveRecord::RecordNotFound.new("Couldn't find #{self.name} with 'id'=#{id}") if hash.empty?
        result.concat(hash)
      end

      result.length == 1 ? self.parse_all(result).first : self.parse_all(result)
    end

    def self.take(n=1)
      relation = ReactiveRecord::Relation.new
      relation.model_name, relation.from_line, relation.joined_models, relation.limit_line = self.name.constantize, self.table_name, [self.name.constantize], n
      n == 1 ? relation.first : relation
    end

    def self.first
      self.find(1)
    end

    def self.last
      last_id = self.all.length
      self.find(last_id)
    end

    def self.find_by(params)
      self.where(params).first || nil
    end

    def self.find_by!(params)
      self.where(params).first || raise(ReactiveRecord::RecordNotFound.new("Couldn't find #{self.name}"))
    end

    def self.pluck(*cols)
      return ReactiveRecord::ArgumentError.new("pluck only accepts Symbols as arguments") unless cols.all? { |col| col.is_a?(Symbol) }

      select_line = cols.map { |col| col.to_s }.join(', ')

      hashes = DBConnection.execute(<<-SQL)
SELECT #{select_line}
FROM #{self.table_name}
      SQL

      cols.length == 1 ? hashes.map { |hash| hash.values.first } : hashes.map { |hash| hash.values }
    end

    def self.exists?(vals)
      if vals.is_a?(Hash)
        col = vals.keys.first.to_s
        vals = vals.values
      else
        col = 'id'
        vals = [vals] if vals.is_a?(Integer)
      end
      vals.each do |val|
        hash = DBConnection.execute(<<-SQL, val)
SELECT *
FROM #{self.table_name}
WHERE #{col} = ?
        SQL
        return true unless hash.empty?
      end

      false
    end

    def self.includes(*associations)
      included = {}

      associations.each do |assoc|
        if self.assoc_options.keys.include?(assoc)
          included[assoc] = self.association_hash(assoc, self.name.constantize)
        elsif self.through_options.keys.include?(assoc)
          through_assoc = self.through_options[assoc].through_name
          through_model = self.assoc_options[through_assoc].class_name.constantize

          source_assoc = self.through_options[assoc].source_name
          source_model = through_model.assoc_options[source_assoc].class_name.constantize

          included[through_assoc] = self.association_hash(through_assoc, self.name.constantize)
          included[source_assoc] = self.association_hash(source_assoc, through_model)
        else
          raise ReactiveRecord::ArgumentError.new("#{assoc} is not a valid association of #{self.name}")
        end
      end

      relation = ReactiveRecord::Relation.new
      relation.model_name, relation.from_line, relation.joined_models, relation.included = self.name.constantize, self.table_name, [self.name.constantize], included
      relation
    end

    def self.association_hash(assoc, model)
      table_name = model.assoc_options[assoc].class_name.constantize.table_name
      foreign_key = model.assoc_options[assoc].foreign_key
      model_name = model.assoc_options[assoc].class_name.constantize
      type = model.assoc_options[assoc].type

      assoc_hash = {}
      assoc_hash[:table_name] = table_name
      assoc_hash[:foreign_key] = foreign_key
      assoc_hash[:model] = model_name
      assoc_hash[:type] = type

      assoc_hash
    end

    def self.none
      relation = ReactiveRecord::Relation.new
      relation.model_name, relation.from_line, relation.null_relation = self.name.constantize, self.table_name, true
      relation
    end

    def self.readonly
      relation = ReactiveRecord::Relation.new
      relation.model_name, relation.from_line, relation.joined_models, relation.is_readonly = self.name.constantize, self.table_name, [self.name.constantize], true
      relation
    end

    def self.create(params)
      object = self.new(params)
      object.insert
    end

    def self.create!(params)
      object = self.new(params)
      object.perform_validations
      object.insert!
    end

    def initialize(params = {})
      @association_cache = {}

      columns = self.class.columns
      params.each do |attr_name, value|
        attr_name = attr_name.to_sym

        if columns.include?(attr_name)
          self.send("#{attr_name}=", value)
        else
          raise "unknown attribute '#{attr_name}'"
        end
      end

      columns.each do |col|
        unless self.attributes[col]
          self.send("#{col}=", nil)
        end
      end

    end

    def attributes
      @attributes ||= {}
    end

    def attribute_values
      self.class.columns.map { |col| self.attributes[col] }
    end

    def readonly
      @is_readonly = true
      self
    end

    def insert
      raise ReactiveRecord::ReadOnlyRecord.new("#{self.class} is marked as readonly") if self.send(:is_readonly)

      begin
        self.perform_validations
      rescue ReactiveRecord::RecordInvalid
        return false
      end

      #return all columns except id
      col_names = self.class.columns[1..-1].join(", ")

      #create correct number of question marks
      question_marks = col_names.split(", ").map { |c| "?" }.join(", ")

      DBConnection.execute(<<-SQL, *attribute_values[1..-1])
INSERT INTO #{self.class.table_name} (#{col_names})
VALUES (#{question_marks})
      SQL

      self.id = DBConnection.last_insert_row_id
    end

    def insert!
      raise ReactiveRecord::ReadOnlyRecord.new("#{self.class} is marked as readonly") if self.send(:is_readonly)

      self.perform_validations

      #return all columns except id
      col_names = self.class.columns[1..-1].join(", ")

      #create correct number of question marks
      question_marks = col_names.split(", ").map { |c| "?" }.join(", ")

      DBConnection.execute(<<-SQL, *attribute_values[1..-1])
INSERT INTO #{self.class.table_name} (#{col_names})
VALUES (#{question_marks})
      SQL

      self.id = DBConnection.last_insert_row_id
    end

    def update
      raise ReactiveRecord::ReadOnlyRecord.new("#{self.class} is marked as readonly") if self.send(:is_readonly)

      begin
        self.perform_validations
      rescue ReactiveRecord::RecordInvalid
        return false
      end

      set_line = self.class.columns[1..-1].map { |col| "#{col} = ?"}.join(", ")

      DBConnection.execute(<<-SQL, *attribute_values.rotate(1))
UPDATE #{self.class.table_name}
SET #{set_line}
WHERE id = ?
      SQL
    end

    def update!
      raise ReactiveRecord::ReadOnlyRecord.new("#{self.class} is marked as readonly") if self.send(:is_readonly)

      self.perform_validations

      set_line = self.class.columns[1..-1].map { |col| "#{col} = ?"}.join(", ")

      DBConnection.execute(<<-SQL, *attribute_values.rotate(1))
UPDATE #{self.class.table_name}
SET #{set_line}
WHERE id = ?
      SQL
    end

    def save
      raise ReactiveRecord::ReadOnlyRecord.new("#{self.class} is marked as readonly") if self.send(:is_readonly)
      self.id ? self.update : self.insert
    end

    def save!
      raise ReactiveRecord::ReadOnlyRecord.new("#{self.class} is marked as readonly") if self.send(:is_readonly)
      self.id ? self.update! : self.insert!
    end

    def destroy
      raise ReactiveRecord::ReadOnlyRecord.new("#{self.class} is marked as readonly") if self.send(:is_readonly)
      id = self.id

      DBConnection.execute(<<-SQL, id)
DELETE FROM #{self.class.table_name}
WHERE id = ?
      SQL
    end

    private

    attr_reader :association_cache
    attr_accessor :is_readonly
  end
end
