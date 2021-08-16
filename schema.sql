CREATE TABLE lists(
  id serial PRIMARY KEY,
  name text NOT NULL UNIQUE
);

CREATE TABLE todos(
  id serial PRIMARY KEY,
  list_id int REFERENCES lists(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  completed boolean NOT NULL DEFAULT(false)
);