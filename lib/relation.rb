class Relation
  attr_accessor :model_name, :select, :from, :joins, :where, :group, :having, :order, :limit, :offset, :query_string

  def initialize
  end

  def execute
    query_string = "
      SELECT #{@select || '*'}
      FROM #{@from}
    "

    hashes = DBConnection.execute(<<-SQL)
    #{query_string}
    SQL

    #create array of objects from each hash
    hashes.map { |hash| self.model_name.new(hash) }
  end

  def where(params)
    #{@where ? "WHERE #{@where}" : nil}
  end


end
