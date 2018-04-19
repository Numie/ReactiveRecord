require_relative 'db_connection'
require_relative 'sql_object'
require_relative 'relation'

module Searchable
  def find_by_sql(query)
    relation = Relation.new
    relation.model_name = self
    relation.query_string = query
    relation.execute
  end

  def select(*cols)
    #create the string of select fields
    if cols.is_a?(String)
      vals = cols
    else
      vals = cols.map(&:to_s).join(", ")
    end

    relation = Relation.new
    relation.model_name, relation.from_line, relation.joined_models, relation.select_line = self.name.constantize, self.table_name, [self.name.constantize], vals
    relation
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

    relation = Relation.new
    relation.model_name, relation.from_line, relation.joined_models, relation.where_line, relation.where_vals = self.name.constantize, self.table_name, [self.name.constantize], where_line, vals
    relation
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

    relation = Relation.new
    relation.model_name, relation.from_line, relation.joined_models, relation.order_line = self.name.constantize, self.table_name, [self.name.constantize], order_by_line
    relation
  end

  def limit(n)
    relation = Relation.new
    relation.model_name, relation.from_line, relation.joined_models, relation.limit_line = self.name.constantize, self.table_name, [self.name.constantize], n
    relation
  end
end
