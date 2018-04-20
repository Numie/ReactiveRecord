CREATE TABLE people (
  id INTEGER PRIMARY KEY,
  first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255) NOT NULL,
  house_id INTEGER,

  FOREIGN KEY(house_id) REFERENCES house(id)
);

CREATE TABLE pets (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  species VARCHAR(255) NOT NULL,
  person_id INTEGER,

  FOREIGN KEY(person_id) REFERENCES person(id)
);

CREATE TABLE houses (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  sigil VARCHAR(255) NOT NULL,
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
  (1, "The North"), (2, "The South");

INSERT INTO
  houses (id, name, sigil, region_id)
VALUES
  (1, "Stark", "Direwolf", 1),
  (2, "Lannister", "Lion", 2),
  (3, "Baratheon", "Stag", 2),
  (4, "Tully", "Fish", 2),
  (5, "Tyrell", "Rose", 2),
  (6, "Greyjoy", "Kraken", 2),
  (7, "Targaryen", "Three-Headed Dragon", 2);

INSERT INTO
  people (id, first_name, last_name, house_id)
VALUES
  (1, "Eddard", "Stark", 1),
  (2, "Catelyn", "Stark", 1),
  (3, "Robb", "Stark", 1),
  (4, "Sansa", "Stark", 1),
  (5, "Arya", "Stark", 1),
  (6, "Bran", "Stark", 1),
  (7, "Rickon", "Stark", 1),
  (8, "Jon", "Snow", 1),
  (9, "Tywin", "Lannister", 2),
  (10, "Tyrion", "Lannister", 2),
  (11, "Cersei", "Lannister", 2),
  (12, "Jaime", "Lannister", 2),
  (13, "Robert", "Baratheon", 3),
  (14, "Stannis", "Baratheon", 3),
  (15, "Renly", "Baratheon", 3),
  (16, "Joffrey", "Baratheon", 3),
  (17, "Myrcella", "Baratheon", 3),
  (18, "Tommen", "Baratheon", 3),
  (19, "Hoster", "Tully", 4),
  (20, "Edmure", "Tully", 4),
  (21, "Brynden", "Tully", 4),
  (22, "Olenna", "Tyrell", 5),
  (23, "Mace", "Tyrell", 5),
  (24, "Loras", "Tyrell", 5),
  (25, "Margaery", "Tyrell", 5),
  (26, "Balon", "Greyjoy", 6),
  (27, "Theon", "Greyjoy", 6),
  (28, "Asha", "Greyjoy", 6),
  (29, "Euron", "Greyjoy", 6),
  (30, "Daenerys", "Targaryen", 7);

INSERT INTO
  pets (id, name, species, person_id)
VALUES
  (1, "Grey Wind", "Dire Wolf", 3),
  (2, "Lady", "Dire Wolf", 4),
  (3, "Nymeria", "Dire Wolf", 5),
  (4, "Summer", "Dire Wolf", 6),
  (5, "Shaggydog", "Dire Wolf", 7),
  (6, "Ghost", "Dire Wolf", 8),
  (7, "Drogon", "Dragon", 30),
  (8, "Rhaegal", "Dragon", 30),
  (9, "Viserion", "Dragon", 30);
