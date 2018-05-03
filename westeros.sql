CREATE TABLE people (
  id INTEGER PRIMARY KEY,
  first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255) NOT NULL,
  age INTEGER,
  sex VARCHAR(255) NOT NULL,
  house_id INTEGER,

  FOREIGN KEY(house_id) REFERENCES house(id)
);

CREATE TABLE pets (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  species VARCHAR(255) NOT NULL,
  owner_id INTEGER,

  FOREIGN KEY(owner_id) REFERENCES person(id)
);

CREATE TABLE houses (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  seat VARCHAR(255) NOT NULL,
  sigil VARCHAR(255) NOT NULL,
  words VARCHAR(255),
  region_id INTEGER,

  FOREIGN KEY(region_id) REFERENCES region(id)
);

CREATE TABLE regions (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL
);

INSERT INTO
  regions (id, name)
VALUES
  (1, "The North"),
  (2, "The Riverlands"),
  (3, "The Vale"),
  (4, "The Iron Islands"),
  (5, "The Westerlands"),
  (6, "The Stormlands"),
  (7, "The Crownlands"),
  (8, "The Reach"),
  (9, "Dorne");

INSERT INTO
  houses (id, name, seat, sigil, words, region_id)
VALUES
  (1, "Stark", "Winterfell", "Direwolf", "Winter is Coming", 1),
  (2, "Bolton", "Dreadfort", "Flayed Man", "Our Blades are Sharp", 1),
  (3, "Mormont", "Bear Island", "Bear", "Here We Stand", 1),
  (4, "Reed", "Greywater Watch", "Lizard", NULL, 1),
  (5, "Tully", "Riverrun", "Trout", "Family, Duty, Honor", 2),
  (6, "Frey", "The Twins", "Two Towers", NULL, 2),
  (7, "Arryn", "The Eyrie", "Falcon", "As High As Honor", 3),
  (8, "Baelish", "The Fingers", "Mockingbird", NULL, 3),
  (9, "Greyjoy", "Pyke", "Kraken", "We Do Not Sow", 4),
  (10, "Lannister", "Casterly Rock", "Lion", "Hear Me Roar", 5),
  (11, "Clegane", "Clegane's Keep", "Three Dogs", NULL, 5),
  (12, "Baratheon", "Storm's End", "Stag", "Ours is the Fury", 6),
  (13, "Targaryen", "Dragonstone", "Three-Headed Dragon", "Fire and Blood", 7),
  (14, "Tyrell", "Highgarden", "Rose", "Growing Strong", 8),
  (15, "Tarly", "Horn Hill", "Hunter", "First in Battle", 8),
  (16, "Martell", "Sunspear", "Red Sun", "Unbowed, Unbent, Unbroken", 9);

INSERT INTO
  people (id, first_name, last_name, age, sex, house_id)
VALUES
  (1, "Eddard", "Stark", 34, 'M', 1),
  (2, "Catelyn", "Stark", 33, 'F', 1),
  (3, "Robb", "Stark", 14, 'M', 1),
  (4, "Sansa", "Stark", 11, 'F', 1),
  (5, "Arya", "Stark", 9, 'F', 1),
  (6, "Bran", "Stark", 7, 'M', 1),
  (7, "Rickon", "Stark", 2, 'M', 1),
  (8, "Jon", "Snow", 14, 'M', 1),
  (9, "Roose", "Bolton", 38, 'M', 2),
  (10, "Ramsay", "Snow", 16, 'M', 2),
  (11, "Jeor", "Mormont", 67, 'M', 3),
  (12, "Jorah", "Mormont", 44, 'M', 3),
  (13, "Howland", "Reed", 33, 'M', 4),
  (14, "Meera", "Reed", 14, 'F', 4),
  (15, "Jojen", "Reed", 11, 'M', 4),
  (16, "Hoster", "Tully", 58, 'M', 5),
  (17, "Edmure", "Tully", 24, 'M', 5),
  (18, "Brynden", "Tully", 53, 'M', 5),
  (19, "Walder", "Frey", 89, 'M', 6),
  (20, "Jon", "Arryn", 78, 'M', 7),
  (21, "Lysa", "Arryn", 30, 'F', 7),
  (22, "Robert", "Arryn", 5, 'M', 7),
  (23, "Petyr", "Baelish", 29, 'M', 8),
  (24, "Balon", "Greyjoy", 37, 'M', 9),
  (25, "Theon", "Greyjoy", 18, 'M', 9),
  (26, "Asha", "Greyjoy", 21, 'F', 9),
  (27, "Euron", "Greyjoy", 30, 'M', 9),
  (28, "Tywin", "Lannister", 55, 'M', 10),
  (29, "Cersei", "Lannister", 31, 'F', 10),
  (30, "Jaime", "Lannister", 31, 'M', 10),
  (31, "Tyrion", "Lannister", 24, 'M', 10),
  (32, "Gregor", "Clegane", 32, 'M', 11),
  (33, "Sandor", "Clegane", 27, 'M', 11),
  (34, "Robert", "Baratheon", 35, 'M', 12),
  (35, "Stannis", "Baratheon", 33, 'M', 12),
  (36, "Renly", "Baratheon", 20, 'M', 12),
  (37, "Joffrey", "Baratheon", 11, 'M', 12),
  (38, "Myrcella", "Baratheon", 7, 'F', 12),
  (39, "Tommen", "Baratheon", 6, 'M', 12),
  (40, "Aemon", "Targaryen", 99, 'M', 13),
  (41, "Daenerys", "Targaryen", 13, 'F', 13),
  (42, "Viserys", "Targaryen", 21, 'M', 13),
  (43, "Olenna", "Tyrell", 69, 'F', 14),
  (44, "Mace", "Tyrell", 41, 'M', 14),
  (45, "Loras", "Tyrell", 15, 'M', 14),
  (46, "Margaery", "Tyrell", 14, 'F', 14),
  (47, "Randyll", "Tarly", 45, 'M', 15),
  (48, "Samwell", "Tarly", 14, 'M', 15),
  (49, "Doran", "Martell", 49, 'M', 16),
  (50, "Oberyn", "Martell", 40, 'M', 16),
  (51, "Ellaria", "Sand", 26, 'F', 16),
  (52, "Trystane", "Martell", 11, 'M', 16);

INSERT INTO
  pets (id, name, species, owner_id)
VALUES
  (1, "Grey Wind", "Dire Wolf", 3),
  (2, "Lady", "Dire Wolf", 4),
  (3, "Nymeria", "Dire Wolf", 5),
  (4, "Summer", "Dire Wolf", 6),
  (5, "Shaggydog", "Dire Wolf", 7),
  (6, "Ghost", "Dire Wolf", 8),
  (7, "Drogon", "Dragon", 40),
  (8, "Rhaegal", "Dragon", 40),
  (9, "Viserion", "Dragon", 40);
