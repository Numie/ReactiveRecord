class Relation
  attr_accessor :model_name, :select, :from, :joins, :where, :where_vals, :group, :having, :order, :limit, :offset, :query_string

  def initialize
  end

  def execute
    query_string = "
      SELECT #{@select || '*'}
      FROM #{@from}
      #{@where ? "WHERE #{@where}" : nil}
    "

    where_vals = self.where_vals
    hashes = DBConnection.execute(<<-SQL, where_vals)
    #{query_string}
    SQL

    #create array of objects from each hash
    hashes.map { |hash| self.model_name.new(hash) }
  end

  def where(params)

  end


end
