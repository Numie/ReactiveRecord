require_relative 'db_connection'
require_relative 'sql_object'

module Searchable
  def select(*cols)
    #create the string of select fields
    if cols.is_a?(String)
      vals = cols
    else
      vals = cols.map(&:to_s).join(", ")
    end

    hashes = DBConnection.execute(<<-SQL)
    SELECT #{vals}
    FROM #{self.table_name}
    SQL

    #create array of objects from each hash
    hashes.map { |hash| self.new(hash) }
  end

  def where(params)
    #create the string of where conditions
    if params.is_a?(String)
      where_line = params
      vals = nil
    elsif params.is_a?(Hash)
      where_line = params.keys.map { |param| "#{param} = ?"}.join(" AND ")
      vals = params.values
    end

    hashes = DBConnection.execute(<<-SQL, vals)
    SELECT *
    FROM #{self.table_name}
    WHERE #{where_line}
    SQL

    #create array of objects from each hash
    hashes.map { |hash| self.new(hash) }
  end
end
