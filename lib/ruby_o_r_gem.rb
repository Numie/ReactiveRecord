require_relative 'sql_object'

class Person < SQLObject
  belongs_to :house

  finalize!
end

class House < SQLObject
  has_many :people, class_name: 'Person'

  finalize!
end

class Region < SQLObject
  finalize!
end
