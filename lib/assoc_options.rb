require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    #use predefined custom 'table-name' method
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})

    #set defaults if values are not present
    defaults = {
      :class_name => name.to_s.capitalize.singularize.camelcase,
      :primary_key => :id,
      :foreign_key => "#{name.to_s.singularize.underscore}_id".to_sym
    }

    defaults.keys.each do |key|
      self.send("#{key}=", options[key] || defaults[key])
    end

  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})

    #set defaults if values are not present
    defaults = {
      :class_name => name.to_s.capitalize.singularize.camelcase,
      :primary_key => :id,
      :foreign_key => "#{self_class_name.to_s.singularize.underscore}_id".to_sym
    }

    defaults.keys.each do |key|
      self.send("#{key}=", options[key] || defaults[key])
    end

  end
end
