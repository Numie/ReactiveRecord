# README

## Setup Instructions

1. Navigate into the Ruby_O_R_Gem directory in the terminal.
1. Run 'cat westeros.sql | sqlite3 westeros.db'.
1. Stars pry and load 'lib/rubyorgem.rb'.

## Classes and Their Ruby ORGem Associations

1. Person
1. House
1. Region

A Person belongs to a House and a Region.
A House belongs to a Region and has many People.
A Region has many Houses.

## General Methods

### 1. class.all
*Try it Out*
Run 'House.all' to see a list of the houses of Westeros.

### 1. class.find(id)
*Try it Out*
Run 'Region.find(1)' to identify 'The North'.

### 1. class.where(params)
*Try it Out*
Run "Person.where(last_name: 'Stark')" to find the members of House Stark.

### 1. instance.insert
*Try it Out*
Run:
'tommen = Person.new(first_name: 'Tommen', last_name: 'Baratheon', house_id: 2)'
'tommen.insert'

### 1. instance.update
*Try it Out*
Run:
'theon = Person.find(27)'
'theon.house_id = 1'
'theon.update'

### 1. instance.save
*Try it Out*
Use 'save' in lieu of either 'insert' or 'update'.

## Association Methods

### Person#house
*Try it Out*
Run:
'jon = Person.find(10)'
'jon.house'

### Person#region
*Try it Out*
Run:
'eddard = Person.find(1)'
eddard.regiom

### House#people
*Try it Out*
Run:
'stark = House.find(1)'
'stark.people'


### House#region
*Try it Out*
Run:
'stark = House.find(1)'
'stark.region'

### Region#houses
*Try it Out*
Run:
'south = Region.find(2)'
'south.houses'
