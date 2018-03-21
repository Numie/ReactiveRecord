# README

## Setup Instructions

1. Navigate into the Ruby_O_R_Gem directory in the terminal.
1. Run 'cat westeros.sql | sqlite3 westeros.db'.
1. Start pry and load 'lib/rubyorgem.rb'.

## Classes and Their Ruby ORGem Associations

1. Person
1. House
1. Region

A Person belongs to a House and a Region.
A House belongs to a Region and has many People.
A Region has many Houses.

## General Methods

### ::all
Run 'House.all' to see a list of the houses of Westeros.

### ::find(id)
Run 'Region.find(1)' to identify 'The North'.

### ::where(params)
Run "Person.where(last_name: 'Stark')" to find the members of House Stark.

### #insert
Run:
'tommen = Person.new(first_name: 'Tommen', last_name: 'Baratheon', house_id: 2)'
'tommen.insert'

### #update
Run:
'theon = Person.find(27)'
'theon.house_id = 1'
'theon.update'

### #save
Use 'save' in lieu of either 'insert' or 'update'.

## Association Methods

### Person#house
Run:
'jon = Person.find(10)'
'jon.house'

### Person#region
Run:
'eddard = Person.find(1)'
eddard.regiom

### House#people
Run:
'stark = House.find(1)'
'stark.people'

### House#region
Run:
'stark = House.find(1)'
'stark.region'

### Region#houses
Run:
'south = Region.find(2)'
'south.houses'
