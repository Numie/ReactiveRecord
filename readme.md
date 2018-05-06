# README

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

## Understanding Method Chaining

The ReactiveRecord pattern implements Method Chaining, which allows you to use multiple ReactiveRecord methods together.

You can chain methods in a statement when the previous method called returns a ReactiveRecord::Relation object, like `all`, `where`, and `joins`. Methods that return a single object (see Retrieving Objects from the Database Section) have to be at the end of the statement.

When a ReactiveRecord method is called, the query is *not immediately generated*. A query only hits the database when the data is actually needed. You may also force a ReactiveRecord::Relation to query the database by calling `execute` on it.

Find people with 3 pets:
```
mother_of_dragons =
  Person.select('people.first_name, people.last_name, COUNT(*) as pet_count')
  .joins(:pets)
  .group(:last_name)
  .having(pet_count: 3)

mother_of_dragons.class
>> ReactiveRecord::Relation
```
The query returns a ReactiveRecord::Relation and does not hit the database because the data is not yet needed.
```
mother_of_dragons.first
>> {"first_name"=>"Daenerys", "last_name"=>"Targaryen", "pet_count"=>3}
```
Now the query is executed.


## Retrieving Objects from the Database

To retrieve objects from the database, ReactiveRecord provides several finder methods. Each finder method allows you to pass arguments into it to perform certain queries on your database without writing raw SQL.

Methods that find a single entity, such as `find` and `first`, return a single instance of the model. Methods that return a collection, such as `where` and `group`, return an instance of `ReactiveRecord::Relation`.

### ::all
See a list of the regions of Westeros. Returns a ReactiveRecord::Relation.
```
regions = Region.all
regions.execute
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
Region.find_by!(name: 'The Dothraki Sea')
>> ReactiveRecord::RecordNotFound: Couldn't find Region
```

### ::take(n)
Return Grey Wind, Lady and Nymeria. Returns a ReactiveRecord::Relation if n is greater than 1.
```
three_pets = Pet.take(3)
three_pets.execute
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

By default, ReactiveRecord::Relations objects select all the fields from a table. To select only a subset of fields, you can specify the subset via the `select` method.

### ::select(column_names)
Find the name and sigil of each House.
```
House.select(:name, :sigil)
```
Also accepts a string:
```
House.select('name, sigil')
```

### ::distinct
If you would like to only grab a single record per unique value in a certain field, you can use `distinct`:
```
Pet.select(:species).distinct
```
This produces:
```
SELECT DISTINCT species
FROM pets
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

**NOT Conditions**

`NOT` SQL queries can be built by `where.not`:
```
Pet.where.not(species: 'Dragon')
```
You may also chain `not` after a previous where clause:
```
Person.where(last_name: 'Lannister').not(first_name: 'Tyrion')
```

**OR Conditions**

`OR` conditions between two relations can be built by calling `or` on the first relation, and passing the second one as an argument.
```
Person.where(first_name: 'Bran').or(Person.where(first_name: 'Rickon'))
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

## Null Relation

The `none` method returns a chainable ReactiveRecord::Relation with no records. Any subsequent conditions chained to the returned relation will continue generating empty relations. This is useful in scenarios where you need a chainable response to a method or a scope that could return zero results.
```
null = House.none
null.class
>> ReactiveRecord::Relation
```
The above code returns an empty relation and fires no queries. If a null relation is forcibly executed, the database will not be queried and an empty array will be returned.

## Readonly Objects

ReactiveRecord provides the `readonly` method on an object to explicitly disallow modification of it. Any attempt to alter a readonly record will not succeed, raising an ReactiveRecord::ReadOnlyRecord error.
```
eddard = Person.readonly.first
eddard.first_name = 'Ned'
eddard.save
>> ReactiveRecord::ReadOnlyRecord: Person is marked as readonly
```
`readonly` may also be called on a relation, rendering each object returned by the relation readonly.

## Joining Tables

ReactiveRecord lets you use the associations defined on a model as a shortcut for specifying `JOIN` clauses for those associations with the `joins` and `left_outer_joins` methods.

### ::joins
Join people to their pets:
```
Person.joins(:pets)
```
This produces:
```
SELECT *
FROM people
INNER JOIN pets ON people.id = pets.owner_id
```
Only people who own pets will be returned. People with no pets will be omitted.

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

### ::left_outer_joins
```
Person.left_outer_joins(:pets)
```
This produces:
```
SELECT *
FROM people
LEFT OUTER JOIN pets ON people.id = pets.owner_id
```
All people and pets will be returned, even if a person does not own any pets.

## Eager Loading Associations

ReactiveRecord allows you to solve the "N + 1 Queries Problem" with `includes`.

**N + 1 Queries Problem**

Consider the following code, which finds 5 pets and prints their owners:
```
pets = Pet.limit(5)

pets.each do |pet|
  puts pet.owner.first_name
end
```
This code looks fine at first sight, but too many queries are executed. The above code executes 1 (to find 5 pets) + 5 (one per each pet to load the owner) = **6** queries in total.

**Solution to the N + 1 Queries Problem**

ReactiveRecord lets you specify in advance all the associations that are going to be loaded using `includes`. With `includes`, ReactiveRecord ensures that all of the specified associations are loaded using the minimum possible number of queries.

Revisiting the above case, we could rewrite `Pet.limit(5)` to eager load owners:
```
pets = Pet.includes(:owner).limit(5)

pets.each do |pet|
  puts pet.owner.first_name
end
```
The above code will execute just **2** queries, as opposed to **6** queries in the previous case:
```
SELECT * FROM pets LIMIT 5
SELECT * FROM people WHERE people.id IN (3, 4, 5, 6, 7)
```

### Eager Loading Multiple Associations

This will load the house and all of the pets of each person:
```
Person.includes(:house, :pets)
```

## Finding By SQL

If you'd like to use your own SQL to find records in a table you can use `find_by_sql`. The `find_by_sql` method will return an array of objects even if the underlying query returns just a single record.

### ::find_by_sql
Find Drogon with your own SQL:
```
Pet.find_by_sql("SELECT * FROM pets WHERE name = 'Drogon'")
```

### ::pluck
`pluck` can be used to query one or more columns from a table of a model. It accepts a list of column names as an argument and returns an array of values of the specified columns.

`pluck` makes it possible to replace code like:
```
Region.select(:name).map(&:name)

Region.select(:id, :name).map { |region| [region.id, region.name] }
```
with:
```
Region.pluck(:name)

Region.pluck(:id, :name)
```
Unlike `select` and other `Relation` scopes, `pluck` triggers an immediate query, and thus cannot be chained with any further scopes, although it can work with scopes already constructed earlier:
```
Person.pluck(:first_name).limit(1)
>> NoMethodError: undefined method `limit' for #<Array:0x007fa388944430>

Person.limit(1).pluck(:first_name)
>> ["Eddard"]
```

## Existence of Objects

If you simply want to check for the existence of the object, use `exists?`. This method will query the database using the same query as `find`, but instead of returning an object or collection of objects it will return either true or false.
```
Person.exists?(41)
>> true

Person.exists?([98, 99])
>> false
```
If `exists?` is passes an integer or an array of integers, it will default to checking the table's id column. However, you may also pass `exists?` a Hash in order to check if a record exists in any other column:
```
Person.exists?(first_name: 'Asha')
>> true

Person.exists?(first_name: 'Yara')
>> false
```
`exists?` may also be called on a ReactiveRecord::Relation. Calling `exists?` this way will cause the relation to execute a query.
```
Region.where(name: 'The Reach').exists?
>> true
```

## Calculations

ReactiveRecord provides a number of methods to make calculations within database queries: `count`, `average`, `minimum`, `maximum` and `sum`.

### ::count
To see the total number of records in a table, use count:
```
House.count
```
`count` may also take a column name as an argument, and will return the number of records for which the column is not `NULL`.

The query below will return only the houses that have words, e.g. 'Winter is Coming'.
```
House.count(:words)
```

### ::average
Find the average of all people:
```
Person.average(:age)
```

### ::minimum
Find the youngest person's age:
```
Person.minimum(:age)
```

### ::maximum
Find the oldest person's age:
```
Person.maximum(:age)
```

### ::sum
Find the sum of the ages of the Baratheon/Lannister children:
```
Person.where(first_name: ['Joffrey', 'Myrcella', 'Tommen']).sum(:age)
```

## Make Changes to the Database

### #insert
Insert Lancel Lannister.
```
lancel = Person.new(first_name: 'Lancel', last_name: 'Lannister', age: 16, sex: 'M', house_id: 10)
lancel.insert

Person.find_by(first_name: 'Lancel')
```

### #create
Initialize and insert a record into the database with a single method call:
```
Person.create(first_name: 'Kevan', last_name: 'Lannister', age: 52, sex: 'M', house_id: 10)

Person.find_by(first_name: 'Kevan')
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

### #destroy
Delete Walder Frey.
```
walder = Person.find_by(first_name: 'Walder')
walder.destroy

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
dany = Person.find(41)
dany.pets
```

### Pet#owner
Find the owner of Grey Wind.
```
grey_wind = Pet.find(1)
grey_wind.owner
```

###Pet#house
Find the house of Summer.
```
summer = Pet.find(4)
summer.house
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

### House#pets
Find the pets of House Targaryen.
```
targaryen = House.find(13)
targaryen.pets
```

### Region#houses
Find the houses in the North.
```
north = Region.find(1)
north.houses
```

### Region#people
Find the people of Dorne.
```
dorne = Region.find(9)
dorne.people
```

## Validations

Model-level validations are used to ensure that only valid data is saved into your database.

Creating and saving a new record will send an `SQL INSERT` operation to the database. Updating an existing record will send an `SQL UPDATE` operation instead. Validations are typically run before these commands are sent to the database. If any validations fail, ReactiveRecord will not perform the `INSERT` or `UPDATE` operation. This avoids storing an invalid object in the database.

### When Does Validation Happen?

The following methods trigger validations, and will save the object to the database only if the object is valid:

* `create`
* `create!`
* `insert`
* `insert!`
* `update`
* `update!`
* `save`
* `save!`

The bang versions (e.g. save!) raise an exception if the record is invalid. The non-bang versions don't: create, insert and update return false, and save just returns the object.

### Errors

To see all of the errors messages from attempting to save an object, use `errors`.

This method is only useful after validations have been run, because it only inspects the errors collection and does not trigger validations itself.

```
p = Person.new
p.errors.any?
>> false

p.save
p.errors.any?
>> true
```

## Validation Helpers

ReactiveRecord offers many pre-defined validation helpers that you can use directly inside your class definitions. These helpers provide common validation rules. Every time a validation fails, an error message is added to the object's `errors` collection.

Each helper accepts an arbitrary number of attribute names, so with a single line of code you can add the same kind of validation to several attributes.

All of them accept the `:message` option, which defines what message should be added to the `errors` collection if it fails. There is a default error message for each one of the validation helpers. These messages are used when the :message option isn't specified.

Additionally, all but `presence` accept the `:allow_nil` option. When set to `true`, it allows `nil` values to be accepted regardless of other conditions.

### Presence

This helper validates that the specified attributes are not empty. It uses the `blank?` method to check if the value is either nil or a blank string.
```
class Person < ReactiveRecord::Base
  validates :first_name, presence: true
  validates :last_name, presence: { message: 'Yes, last name is usually the same as House name, but it still must exist!' }
end
```
In the example above, `first_name` and `last_name` are validated for presence, the latter of which with a custom error message.

Foreign keys of `belongs_to` associations are automatically validated for presence. There is no need validate foreign keys manually.
```
brienne = Person.new(first_name: 'Brienne', last_name: 'Tarth', age: 19, sex: 'F')
brienne.save!
>> ReactiveRecord::RecordInvalid: Validation failed: house_id must exist
```

### Uniqueness

This helper validates that the attribute's value is unique. The validation happens by performing an SQL query into the model's table, searching for an existing record with the same value in that attribute.
```
class House < ReactiveRecord::Base
  validates :name, :seat, :sigil, presence: true, uniqueness: true
end

impostor_stark = House.new(name: 'Impostor Stark', seat: 'Winterfell', sigil: 'Impostor', region_id: 1)
impostor_stark.save!
>> ReactiveRecord::RecordInvalid: Validation failed: seat has already been taken
```

### Format

This helper validates the attributes' values by testing whether they match a given regular expression, which is specified using the `:with` or `:without` options.
```
class Pet < ReactiveRecord::Base
  validates :name, presence: true, uniqueness: true, format: { without: /\d+/ }
end

clone = Pet.new(name: 'Shaggydog2', species: 'Dire Wolf', owner_id: 7)
clone.save!
>> ReactiveRecord::RecordInvalid: Validation failed: name is invalid
```
The operation fails in the above example because Pet names cannot include numbers.

### Inclusion

This helper validates that the attributes' values are included in a given set. The inclusion helper has an option `:in` that receives the set of values that will be accepted.
```
class Pet < ReactiveRecord::Base
  validates :species, presence: true, inclusion: { in: ['Dire Wolf', 'Dragon'] }
end

hedwig = Pet.new(name: 'Hedwig', species: 'Owl', owner_id: 12)
hedwig.save!
>> ReactiveRecord::RecordInvalid: Validation failed: species is invalid
```

### Length

This helper validates the length of the attributes' values. It provides a variety of options, so you can specify length constraints in different ways.

The possible length constraint options are:

* `:minimum` - The attribute cannot have less than the specified length.
* `:maximum` - The attribute cannot have more than the specified length.
* `:in` - The attribute length must be included in a given interval.
* `:is` - The attribute length must be equal to the given value.

```
class House < ReactiveRecord::Base
  validates :words, length: { minimum: 6, allow_nil: true }
end

house_hodor = House.new(name: 'Hodor', seat: 'Hodor', sigil: 'Hodor', words: 'Hodor', region_id: 1)
house_hodor.save!
>> ReactiveRecord::RecordInvalid: Validation failed: words length must be at least 6
```

### Numericality

This helper validates that your attributes have only numeric values. By default, it will match an optional sign followed by an integral or floating point number. To specify that only integral numbers are allowed set `:only_integer` to `true`.

Besides `:only_integer`, this helper also accepts the following options:

* `:greater_than` - Specifies the value must be greater than the supplied value.
* `:greater_than_or_equal_to` - Specifies the value must be greater than or equal to the supplied value.
* `:equal_to` - Specifies the value must be equal to the supplied value.
* `:less_than` - Specifies the value must be less than the supplied value.
* `:less_than_or_equal_to` - Specifies the value must be less than or equal to the supplied value.
* `:other_than` - Specifies the value must be other than the supplied value.
* `:odd` - Specifies the value must be an odd number if set to true.
* `:even` - Specifies the value must be an even number if set to true.

```
class Person < ReactiveRecord::Base
  validates :age, presence: true, numericality: { only_integer: true, less_than: 100 }
end

old_nan = Person.new(first_name: 'Old', last_name: 'Nan', age: 100, sex: 'F', house_id: 1)
old_nan.save!
>> ReactiveRecord::RecordInvalid: Validation failed: age must be less than 100
```

## Callbacks

Callbacks are methods that get called at certain moments of an object's life cycle. With callbacks it is possible to write code that will run whenever an ReactiveRecord object is created, saved, updated, deleted, validated, or loaded from the database.

### Callback Registration

In order to use the available callbacks, you need to register them. You can implement the callbacks as ordinary methods and use a macro-style class method to register them as callbacks:
```
class Person < ReactiveRecord::Base
  after_create :age_plus_one

  private

  def age_plus_one
    self.age += 1
  end
end

davos = Person.create(first_name: 'Davos', last_name: 'Seaworth', age: 45, sex: 'M', house_id: 12)
davos.age
>> 46
```

### Available Callbacks

Here is a list of the available ReactiveRecord callbacks:

* before_validation
* after_validation
* before_create
* after_create
* before_update
* after_update
* before_save
* after_save
* before_destroy
* after_destroy
* after_initialize
* after_commit/after_rollback
