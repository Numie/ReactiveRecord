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
      raise ReactiveRecord::ArgumentError.new("You have passed a #{col.class} object to #count. Pass a String or a Symbol instead.")
    end

    relation = ReactiveRecord::Relation.new
    relation.select_line ? relation.select_line += ", COUNT(#{val})" : relation.select_line = "COUNT(#{val})"
    relation.from_line, relation.joined_models, relation.calc = self.table_name, [self.name.constantize], true
    hashes = relation.execute
    hashes.first["COUNT(#{val})"]
  end

  def average(col)
    if col.is_a?(String)
      val = col
    elsif col.is_a?(Symbol)
      val = "#{self.table_name}.#{col.to_s}"
    else
      raise ReactiveRecord::ArgumentError.new("You have passed a #{col.class} object to #average. Pass a String or a Symbol instead.")
    end

    relation = ReactiveRecord::Relation.new
    relation.select_line ? relation.select_line += ", AVG(#{val})" : relation.select_line = "AVG(#{val})"
    relation.from_line, relation.joined_models, relation.calc = self.table_name, [self.name.constantize], true
    hashes = relation.execute
    hashes.first["AVG(#{val})"]
  end

  def minimum(col)
    if col.is_a?(String)
      val = col
    elsif col.is_a?(Symbol)
      val = "#{self.table_name}.#{col.to_s}"
    else
      raise ReactiveRecord::ArgumentError.new("You have passed a #{col.class} object to #minimum. Pass a String or a Symbol instead.")
    end

    relation = ReactiveRecord::Relation.new
    relation.select_line ? relation.select_line += ", MIN(#{val})" : relation.select_line = "MIN(#{val})"
    relation.from_line, relation.joined_models, relation.calc = self.table_name, [self.name.constantize], true
    hashes = relation.execute
    hashes.first["MIN(#{val})"]
  end

  def maximum(col)
    if col.is_a?(String)
      val = col
    elsif col.is_a?(Symbol)
      val = "#{self.table_name}.#{col.to_s}"
    else
      raise ReactiveRecord::ArgumentError.new("You have passed a #{col.class} object to #maximum. Pass a String or a Symbol instead.")
    end

    relation = ReactiveRecord::Relation.new
    relation.select_line ? relation.select_line += ", MAX(#{val})" : relation.select_line = "MAX(#{val})"
    relation.from_line, relation.joined_models, relation.calc = self.table_name, [self.name.constantize], true
    hashes = relation.execute
    hashes.first["MAX(#{val})"]
  end

  def self.sum(col)
    if col.is_a?(String)
      val = col
    elsif col.is_a?(Symbol)
      val = "#{self.table_name}.#{col.to_s}"
    else
      raise ReactiveRecord::ArgumentError.new("You have passed a #{col.class} object to #sum. Pass a String or a Symbol instead.")
    end

    relation = ReactiveRecord::Relation.new
    relation.select_line ? relation.select_line += ", SUM(#{val})" : relation.select_line = "SUM(#{val})"
    relation.from_line, relation.joined_models, relation.calc = self.table_name, [self.name.constantize], true
    hashes = relation.execute
    hashes.first["SUM(#{val})"]
  end
end
