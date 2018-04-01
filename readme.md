# README

## Setup Instructions

1. Clone the repo.
2. Navigate into the Ruby_O_R_Gem directory in the terminal.
3. Run:
```
bundle install
cat westeros.sql | sqlite3 westeros.db
 ```
5. Start pry and load the entry file:
```
load 'lib/rubyorgem.rb'
```

## Classes and Their Ruby ORGem Associations

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

### #insert
Insert Tommen Baratheon.
```
tommen = Person.new(first_name: 'Tommen', last_name: 'Baratheon', house_id: 2)
tommen.insert
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
jon = Person.find(10)
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