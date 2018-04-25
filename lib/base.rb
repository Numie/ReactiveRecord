require_relative 'db_connection'
require_relative 'searchable'
require_relative 'calculatable'
require_relative 'associatable'
require_relative 'relation'
require_relative 'errors'
require 'active_support/inflector'

module ReactiveRecord
  class Base
    extend Searchable
    extend Calculatable
    extend Associatable

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
          raise ReactiveModel::MissingAttribute.new("Missing attribute: #{col}") unless val
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

    def self.pluck(col)
      hash = DBConnection.execute(<<-SQL, col)
SELECT #{col}
FROM #{self.table_name}
      SQL

      self.parse_all(hash)
    end

    def self.exists?(vals)
      if vals.is_a?(Hash)
        col = vals.keys.first.to_s
        vals = vals.values
      else
        col = id
        vals = [ids] if vals.is_a?(Integer)
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

    def initialize(params = {})
      params.each do |attr_name, value|
        attr_name = attr_name.to_sym

        if self.class.columns.include?(attr_name)
          self.send("#{attr_name}=", value)
        else
          raise "unknown attribute '#{attr_name}'"
        end
      end
    end

    def attributes
      @attributes ||= {}
    end

    def attribute_values
      self.class.columns.map { |col| self.attributes[col] }
    end

    def insert
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
      set_line = self.class.columns[1..-1].map { |col| "#{col} = ?"}.join(", ")

      DBConnection.execute(<<-SQL, *attribute_values.rotate(1))
UPDATE #{self.class.table_name}
SET #{set_line}
WHERE id = ?
      SQL
    end

    def save
      self.id ? self.update : self.insert
    end

    def destroy
      id = self.id

      DBConnection.execute(<<-SQL, id)
DELETE FROM #{self.class.table_name}
WHERE id = ?
      SQL
    end
  end
end
