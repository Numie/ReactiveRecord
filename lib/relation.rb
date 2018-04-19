class Relation
  attr_accessor :model_name, :select_line, :from_line, :joins_line, :where_line, :where_vals, :group_line,
  :having_line, :having_vals, :order_line, :limit_line, :offset_line, :query_string

  def initialize
  end

  def execute
    query_string = "
      SELECT #{@select_line || '*'}
      FROM #{@from_line}
      #{@where_line ? "WHERE #{@where_line}" : nil}
      #{@group_line ? "GROUP BY #{@group_line}" : nil}
      #{@having_line ? "HAVING #{@having_line}" : nil}
    "

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

    return hashes if self.group_line

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
end
