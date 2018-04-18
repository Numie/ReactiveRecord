class Relation
  attr_accessor :model_name, :select_line, :from_line, :joins_line, :where_line, :where_vals, :group_line, :having_line, :order_line, :limit_line, :offset_line, :query_string

  def initialize
  end

  def execute
    query_string = "
      SELECT #{@select_line || '*'}
      FROM #{@from_line}
      #{@where_line ? "WHERE #{@where_line}" : nil}
    "

    where_vals = self.where_vals
    hashes = DBConnection.execute(<<-SQL, where_vals)
    #{query_string}
    SQL

    #create array of objects from each hash
    hashes.map { |hash| self.model_name.new(hash) }
  end

  def method_missing(method, *args)
    arr = self.execute
    arr.send(method, *args)
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


end
