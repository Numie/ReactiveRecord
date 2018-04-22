# README

ReactiveRecord is a custom-built version of ActiveRecord.

Methods that find a single entity, such as find and first, return a single instance of the model.
Methods that return a collection, such as where and group, return an instance of ReactiveRecord::Relation. 

## Setup Instructions

1. Clone the repo.
2. Navigate into the ReactiveRecord directory in the terminal.
3. Run 'bundle install' and create the database file:
```
bundle install
cat westeros.sql | sqlite3 westeros.db
 ```
4. Start pry and load the entry file:
```
pry
load 'reactiverecord.rb'
```

## Example ReactiveRecord Models and Associations

Code examples throughout this guide will refer to one or more of the following models:

```
class Person < ReactiveRecord::Base
  belongs_to :house
  has_one_through :region, :house, :region
  has_many :pets, foreign_key: :owner_id
end
```

```
class Pet < ReactiveRecord::Base
  belongs_to :owner, class_name: 'Person'
  has_one_through :house, :owner, :house
  has_one_through :region, :house, :region
end
```

```
class House < ReactiveRecord::Base
  belongs_to :region
  has_many :people, class_name: 'Person'
  has_many_through :pets, :people, :pets
end
```

```
class Region < ReactiveRecord::Base
  has_many :houses
  has_many_through :people, :houses, :people
  has_many_through :pets, :people, :pets
end
```

## Retrieving Objects from the Database

### ::all
See a list of the regions of Westeros.
```
Region.all
```

### ::find(ids)
Identify 'The Vale'.
```
Region.find(3)
```
Can also take an array of IDs:
```
Region.find([3, 4])
```
The find method will raise a ReactiveRecord::RecordNotFound exception unless a matching record is found for all of the supplied primary keys.

### ::find_by(params)
Returns the first result that matches the query.
```
Region.find_by(name: 'The Reach')
```

### ::find_by!(params)
Same as ::find_by but returns an error when no results are found:
```
Region.find_by!(name: 'The West')
>> ReactiveRecord::RecordNotFound: Couldn't find Region
```

### ::take(n)
Return Grey Wind, Lady and Nymeria.
```
Pet.take(3)
```

### ::first
Find the first house in the database, House Stark.
```
House.first
```

### ::last
Find the last house in the database, House Martell.
```
House.last
```

## ReactiveRecord Relations

### ::select(column_names)
Find the ID and name of each House.
```
House.select(:id, :name)
```
Also accepts a string:
```
House.select('id, name')
```

### ::where(params)
Find the members of House Stark.
```
Person.where(last_name: 'Stark')
```
Also accepts a string with standard SQL syntax:
```
Person.where("last_name = 'Stark'")
```
Or syntax to protect against SQL injection attacks:
```
Person.where('last_name = ?', 'Stark')
```
And multiple conditions:
```
Person.where(last_name: 'Stark', first_name: 'Arya')
Person.where("last_name = 'Stark' AND first_name = 'Arya'")
Person.where('last_name = ? AND first_name = ?', 'Stark', 'Arya')
```

### ::order(column_name)
Order the houses by name or by multiple columns:
```
House.order(:name)
House.order(name: :desc)
House.order(:region_id, name: :desc)
```
Also accepts a string:
```
House.order('name')
House.order('name DESC')
House.order('region_id, name DESC')
```

### ::limit(n)
Return the first 3 people:
```
Person.limit(3)
```

## Make Changes to the Database

### #insert
Insert Lancel Lannister.
```
Person.find_by(first_name: 'Lancel')
>> nil

lancel = Person.new(first_name: 'Lancel', last_name: 'Lannister', house_id: 10)
lancel.insert

Person.find_by(first_name: 'Lancel')
```

### #update
Update Theon Greyjoy.
```
theon = Person.find(25)
theon.house

theon.house_id = 1
theon.update

Person.find(25).house
```

### #save
Use 'save' in lieu of either 'insert' or 'update'.

## Association Methods

### Person#house
Find Jon Snow's house.
```
jon = Person.find(8)
jon.house
```

### Person#region
Find Eddard Stark's region.
```
eddard = Person.find(1)
eddard.region
```

### Person#pets
Find Daenerys Targaryen's dragons.
```
dany = Person.find(40)
dany.pets
```

### Pet#owner
Find the owner of Grey Wind.
```
grey_wind = Pet.find(1)
grey_wind.owner
```

### House#people
Find all people in House Baratheon.
```
baratheon = House.find(12)
baratheon.people
```

### House#region
Find the region of House Tully.
```
tully = House.find(5)
tully.region
```

### Region#houses
Find the houses in the North.
```
north = Region.find(1)
north.houses
```
