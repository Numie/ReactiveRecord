# README

ReactiveRecord is a custom-built version of ActiveRecord.

## Setup Instructions

1. Clone the repo.
2. Navigate into the ReactiveRecord directory in the terminal.
3. Run `bundle install` and create the database file:
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

This guide will use a sample database called Westeros.db. Code examples will refer to one or more of the following models:

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

To retrieve objects from the database, ReactiveRecord provides several finder methods. Each finder method allows you to pass arguments into it to perform certain queries on your database without writing raw SQL.

Methods that find a single entity, such as `find` and `first`, return a single instance of the model. Methods that return a collection, such as `where` and `group`, return an instance of `ReactiveRecord::Relation`.

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
The find method will raise a `ReactiveRecord::RecordNotFound` exception unless a matching record is found for all of the supplied primary keys.

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

## Selecting Specific Fields

By default, `Model.find` selects all the fields from the result. To select only a subset of fields from the result set, you can specify the subset via the `select` method.

### ::select(column_names)
Find the name and sigil of each House.
```
House.select(:name, :sigil)
```
Also accepts a string:
```
House.select('name, sigil')
```
Be careful: `select` allows you to initialize a model object with only the fields that you've selected. If you attempt to access a field that is not in the initialized record you'll receive a `ReactiveModel::MissingAttribute` error.
```
stark = House.select(:name).first
stark.sigil
>> ReactiveModel::MissingAttribute: Missing attribute: sigil
```

## Conditions

The `where` method allows you to specify conditions to limit the records returned. Conditions can either be specified as a string, array, or hash.

### ::where(params)

**Pure String Conditions**

Conditions may be specified with standard SQL syntax.
```
Person.where("last_name = 'Stark'")
Person.where("last_name = 'Stark' AND first_name = 'Arya'")
```
Building conditions as pure strings can leave you vulnerable to SQL injection attacks. See below for the preferred way to handle conditions using an array.

**Array Conditions**

ReactiveRecord will take the first argument as the conditions string and any additional arguments will replace the question marks (?) in it.
```
Person.where('last_name = ?', 'Stark')
```
If you want to specify multiple conditions:
```
Person.where('last_name = ? AND first_name = ?', 'Stark', 'Arya')
```

**Hash Conditions**

ReactiveRecord also allows you to pass in hash conditions with keys of the fields you want qualified and the values of how you want to qualify them.

\*Only equality, range and subset checking are possible with Hash conditions.

*Equality Conditions*
```
Person.where(last_name: 'Stark', first_name: 'Arya')
```
This produces:
```
SELECT *
FROM people
WHERE last_name = 'Stark' AND first_name = 'Arya'
```

*Range Conditions*
To find records using the `BETWEEN` expression, pass a range to the conditions hash:
```
Person.where(first_name: ('Arya'..'Jon'))
```
This produces:
```
SELECT *
FROM people
WHERE first_name BETWEEN 'Arya' AND 'Jon'
```

*Subset Conditions*
To find records using the `IN` expression, pass an array to the conditions hash:
```
Person.where(first_name: ['Robert', 'Stannis', 'Renly'])
```
This produces:
```
SELECT *
FROM people
WHERE first_name IN ('Robert', 'Stannis', 'Renly')
```

## Ordering

To retrieve records from the database in a specific order, you can use the `order` method. You can specify `ASC` (default) or `DESC`,  as well as order by multiple fields.

### ::order(column_names)
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

## Limit and Offset

You can use `limit` to specify the number of records to be retrieved, and use `offset` to specify the number of records to skip before starting to return the records.

### ::limit(n)
Return the first 3 people:
```
Person.limit(3)
```

### ::offset(n)
Return the 5th-7th people:
```
Person.limit(3).offset(4)
```

## Group

To apply a `GROUP BY` clause to the SQL query, you can use the `group` method.

### ::group(columns_names)
Return the last names in the database, and the count of people with each last name:
```
Person.select('last_name, COUNT(*) AS count').group(:last_name)
```

## Having

You can add a `HAVING` clause to specify conditions on the `GROUP BY` fields with the `having` method.

### ::having(params)
Same as the example above. but only for last names with greater than 2 people:
```
Person.select('last_name, COUNT(*) AS count').group(:last_name).having('count > 2')
```
The `having` method can also except equality, range and subset conditions as a hash just like `where`. To find last names with between 3 and 6 people:
```
Person.select('last_name, COUNT(*) AS count').group(:last_name).having(count: (3..6))
```

## Joining Tables

ReactiveRecord lets you use the names of the associations defined on a model as a shortcut for specifying `JOIN` clauses for those associations with the `joins` method.

### ::joins
Join people to their house:
```
Person.joins(:house)
```
This produces:
```
SELECT *
FROM people
INNER JOIN houses ON people.house_id = houses.id
```
You may also use a through association, which will produce multiple `JOIN` clauses:
```
Person.joins(:region)
```
This produces:
```
SELECT *
FROM people
INNER JOIN houses ON people.house_id = houses.id
INNER JOIN regions ON houses.region_id = regions.id
```

## Finding By SQL

If you'd like to use your own SQL to find records in a table you can use `find_by_sql`. The `find_by_sql` method will return an array of objects even if the underlying query returns just a single record.

### ::find_by_sql
Find Drogon with your own SQL:
```
Pet.find_by_sql("SELECT * FROM pets WHERE name = 'Drogon'")
```

## Make Changes to the Database

### #insert
Insert Lancel Lannister.
```
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

### #delete
Delete Walder Frey.
```
walder = Person.find_by(first_name: 'Walder')
walder.delete

Person.find_by(first_name: 'Walder')
```

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
