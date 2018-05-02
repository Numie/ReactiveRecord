require_relative 'lib/base'

class Person < ReactiveRecord::Base
  validates :first_name, presence: true
  validates :last_name, presence: { message: 'Yes, last name is usally the same as House name, but it still must exist!' }
  validates :age, presence: true, numericality: true

  belongs_to :house
  has_one_through :region, :house, :region
  has_many :pets, foreign_key: :owner_id

  finalize!
end

class Pet < ReactiveRecord::Base
  belongs_to :owner, class_name: 'Person'
  has_one_through :house, :owner, :house
  has_one_through :region, :house, :region

  finalize!
end

class House < ReactiveRecord::Base
  belongs_to :region
  has_many :people, class_name: 'Person'
  has_many_through :pets, :people, :pets

  finalize!
end

class Region < ReactiveRecord::Base
  has_many :houses
  has_many_through :people, :houses, :people
  has_many_through :pets, :people, :pets

  finalize!
end
