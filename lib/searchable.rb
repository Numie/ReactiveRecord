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
      vals = nil
    else
      raise 'RubyORGem Error'
    end

    hashes = DBConnection.execute(<<-SQL, vals)
    SELECT *
    FROM #{self.table_name}
    WHERE #{where_line}
    SQL

    #create array of objects from each hash
    hashes.map { |hash| self.new(hash) }
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

    hashes = DBConnection.execute(<<-SQL)
    SELECT *
    FROM #{self.table_name}
    ORDER BY #{order_by_line}
    SQL

    #create array of objects from each hash
    hashes.map { |hash| self.new(hash) }
  end

  def limit(n)
    hashes = DBConnection.execute(<<-SQL)
    SELECT *
    FROM #{self.table_name}
    LIMIT #{n}
    SQL

    #create array of objects from each hash
    hashes.map { |hash| self.new(hash) }
  end
end
