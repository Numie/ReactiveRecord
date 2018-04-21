# README

## Setup Instructions

1. Clone the repo.
2. Navigate into the ReactiveRecord directory in the terminal.
3. Run:
```
bundle install
cat westeros.sql | sqlite3 westeros.db
 ```
4. Start pry and load the entry file:
```
load 'reactiverecord.rb'
```

## Classes and Their ReactiveRecord Associations

1. Person
1. House
1. Region

A Person belongs to a House and a Region.
A House belongs to a Region and has many People.
A Region has many Houses.

## General Methods

### ::all
See a list of the houses of Westeros.
```
House.all
```

### ::find(ids)
Identify 'The North'.
```
Region.find(1)
```
Can also take an array of IDs:
```
Region.find([1, 2])
```

### ::find_by(params)
Returns the first result that matches the query.
```
Region.find_by(name: 'The North')
```

### ::find_by!(params)
Same as ::find_by but returns an error when no results are found:
```
Region.find_by!(name: 'The West')
>> RubyORGem::RecordNotFound
```

### ::take(n)
Return Eddard, Catelyn and Robb Stark.
```
Person.take(3)
```

### ::first
Find the first house in the database, House Stark.
```
House.first
```

### ::last
Find the last house in the database, House Targaryen.
```
House.last
```

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

### #insert
Insert Lancel Lannister.
```
lancel = Person.new(first_name: 'Lancel', last_name: 'Lannister', house_id: 2)
lancel.insert
```

### #update
Update Theon Greyjoy.
```
theon = Person.find(27)
theon.house_id = 1
theon.update
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

### House#people
Find all people in House Stark.
```
stark = House.find(1)
stark.people
```

### House#region
Find the region of House Stark.
```
stark = House.find(1)
stark.region
```

### Region#houses
Find all the houses in the South.
```
south = Region.find(2)
south.houses
```
