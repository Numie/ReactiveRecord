CREATE TABLE people (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL,
  house_id INTEGER,

  FOREIGN KEY(house_id) REFERENCES house(id)
);

CREATE TABLE houses (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
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
  houses (id, name, region_id)
VALUES
  (1, "Stark", 1),
  (2, "Lannister", 2),
  (3, "Baratheon", 2),
  (4, "Tyrell", 2);

INSERT INTO
  people (id, fname, lname, house_id)
VALUES
  (1, "Jon", "Snow", 1),
  (2, "Arya", "Stark", 1),
  (3, "Tyrion", "Lannister", 2);
