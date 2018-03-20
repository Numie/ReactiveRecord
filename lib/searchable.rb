require_relative 'db_connection'
require_relative 'sql_object'

module Searchable
  def where(params)
    #create the string of where conditions
    where_line = params.keys.map { |param| "#{param} = ?"}.join(" AND ")
    vals = params.values

    hashes = DBConnection.execute(<<-SQL, vals)
    SELECT *
    FROM #{self.table_name}
    WHERE #{where_line}
    SQL

    #create array of objects from each hash
    hashes.map { |hash| self.new(hash) }
  end
end
