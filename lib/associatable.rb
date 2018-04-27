require_relative 'assoc_options'
require_relative 'searchable'

module Associatable
  def assoc_options
    #hash of associations
    @assoc_options ||= {}
  end

  def through_options
    @through_options ||= {}
  end

  def belongs_to(name, options = {})

    #create instance of BelongsToOptions, setting defaults if necessary
    self.assoc_options[name] = BelongsToOptions.new(name, options)

    #create the association method
    define_method(name) do
      #fetch data from association_cache if it includes was called
      included_data = self.send(:association_cache)[name]
      return included_data.first if included_data

      options = self.class.assoc_options[name]

      #get value of instance's foreign key
      foreign_key_val = self.send(options.foreign_key)

      #return the first object from the array returned by .where
      options
        .model_class
        .where(options.primary_key => foreign_key_val)
        .first
    end
  end

  def has_many(name, options = {})

      #create instance of HasManyOptions, setting defaults if necessary
      self.assoc_options[name] = HasManyOptions.new(name, self.name, options)

      #create the association method
      define_method(name) do
        #fetch data from association_cache if it includes was called
        included_data = self.send(:association_cache)[name]
        return included_data if included_data

        options = self.class.assoc_options[name]

        #get value of instance's primary key
        foreign_key_val = self.send(options.primary_key)

        #return the array of objects returned by .where
        options
          .model_class
          .where(options.foreign_key => foreign_key_val)
      end
  end

  def has_one_through(name, through_name, source_name)
    self.through_options[name] = ThroughOptions.new(name, through_name, source_name)

    define_method(name) do
      #associations have presumably been created already
      #fetch them from assoc_options

      #fetch through belongs_to options
      through_options = self.class.assoc_options[through_name]
      #fetch source belongs_to options
      source_options = through_options.model_class.assoc_options[source_name]

      through_table_name = through_options.table_name
      through_primary_key = through_options.primary_key
      through_foreign_key = through_options.foreign_key

      source_table_name = source_options.table_name
      source_primary_key = source_options.primary_key
      source_foreign_key = source_options.foreign_key

      foreign_key_val = self.send(through_foreign_key)

      results = DBConnection.execute(<<-SQL, foreign_key_val)
SELECT #{source_table_name}.*
FROM #{through_table_name}
JOIN #{source_table_name}
ON #{through_table_name}.#{source_foreign_key} = #{source_table_name}.#{source_primary_key}
WHERE #{through_table_name}.#{through_primary_key} = ?
      SQL

      source_options.model_class.parse_all(results).first
    end
  end

  def has_many_through(name, through_name, source_name)
    self.through_options[name] = ThroughOptions.new(name, through_name, source_name)

    define_method(name) do
      #associations have presumably been created already
      #fetch them from assoc_options

      #fetch through belongs_to options
      through_options = self.class.assoc_options[through_name]
      #fetch source belongs_to options
      source_options = through_options.model_class.assoc_options[source_name]

      through_table_name = through_options.table_name
      through_primary_key = through_options.primary_key
      through_foreign_key = through_options.foreign_key

      source_table_name = source_options.table_name
      source_primary_key = source_options.primary_key
      source_foreign_key = source_options.foreign_key

      foreign_key_val = self.id

      results = DBConnection.execute(<<-SQL, foreign_key_val)
SELECT #{source_table_name}.*
FROM #{through_table_name}
JOIN #{source_table_name}
ON #{source_table_name}.#{source_foreign_key} = #{through_table_name}.#{source_primary_key}
WHERE #{through_table_name}.#{through_foreign_key} = ?
      SQL

      source_options.model_class.parse_all(results)
    end
  end
end
