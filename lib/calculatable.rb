require_relative 'relation'
require_relative 'errors'

module Calculatable
  def count(col=nil)
    if !col
      val = "*"
    elsif col.is_a?(String)
      val = col
    elsif col.is_a?(Symbol)
      val = "#{self.table_name}.#{col.to_s}"
    else
      raise ReactiveRecord::ArgumentError.new("You have passed a #{col.class} object to ::count. Pass a String or a Symbol instead.")
    end

    relation = ReactiveRecord::Relation.new
    relation.model_name, relation.from_line, relation.joined_models, relation.select_line, relation.calc = self.name.constantize, self.table_name, [self.name.constantize], "COUNT(#{val})", true
    relation
  end
end
