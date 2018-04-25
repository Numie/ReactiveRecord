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

  def average(col)
  if col.is_a?(String)
    val = col
  elsif col.is_a?(Symbol)
    val = "#{self.table_name}.#{col.to_s}"
  else
    raise ReactiveRecord::ArgumentError.new("You have passed a #{col.class} object to ::average. Pass a String or a Symbol instead.")
  end

  relation = ReactiveRecord::Relation.new
  relation.model_name, relation.from_line, relation.joined_models, relation.select_line, relation.calc = self.name.constantize, self.table_name, [self.name.constantize], "AVG(#{val})", true
  relation
  end

  def minimum(col)
  if col.is_a?(String)
    val = col
  elsif col.is_a?(Symbol)
    val = "#{self.table_name}.#{col.to_s}"
  else
    raise ReactiveRecord::ArgumentError.new("You have passed a #{col.class} object to ::minimum. Pass a String or a Symbol instead.")
  end

  relation = ReactiveRecord::Relation.new
  relation.model_name, relation.from_line, relation.joined_models, relation.select_line, relation.calc = self.name.constantize, self.table_name, [self.name.constantize], "MIN(#{val})", true
  relation
  end

  def maximum(col)
  if col.is_a?(String)
    val = col
  elsif col.is_a?(Symbol)
    val = "#{self.table_name}.#{col.to_s}"
  else
    raise ReactiveRecord::ArgumentError.new("You have passed a #{col.class} object to ::maximum. Pass a String or a Symbol instead.")
  end

  relation = ReactiveRecord::Relation.new
  relation.model_name, relation.from_line, relation.joined_models, relation.select_line, relation.calc = self.name.constantize, self.table_name, [self.name.constantize], "MAX(#{val})", true
  relation
  end

  def sum(col)
  if col.is_a?(String)
    val = col
  elsif col.is_a?(Symbol)
    val = "#{self.table_name}.#{col.to_s}"
  else
    raise ReactiveRecord::ArgumentError.new("You have passed a #{col.class} object to ::sum. Pass a String or a Symbol instead.")
  end

  relation = ReactiveRecord::Relation.new
  relation.model_name, relation.from_line, relation.joined_models, relation.select_line, relation.calc = self.name.constantize, self.table_name, [self.name.constantize], "SUM(#{val})", true
  relation
  end
end
