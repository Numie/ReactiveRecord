require_relative 'sql_object'

class Person < SQLObject
  belongs_to :house
  has_one_through :region, :house, :region

  has_many :pets

  finalize!
end

class Pet < SQLObject
  belongs_to :person
  has_one_through :house, :person, :house

  finalize!
end

class House < SQLObject
  belongs_to :region
  has_many :people, class_name: 'Person'

  finalize!
end

class Region < SQLObject
  has_many :houses

  finalize!
end
