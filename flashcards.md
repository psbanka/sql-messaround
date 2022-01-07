### What is a sub-query?

Also known as a sub-select. The `SELECT` keyword in SQL identifies what columns you would like to pull from which table/database. A sub-query can generate another table for data to be pulled from as if it were an actual table in the database. 


### Why would you use a sub-query?

You could also use a view. One of the purposes is to minimize the number of calls to the database. You could also use it to do some manipulation.

It can also help simplify queries across different tables.


### Give a simple example of what a sub-query would look like?

Let's say we have a database like this:

CREATE DATABASE books;
mysql> show tables;
+-----------------+
| Tables_in_store |
+-----------------+
| authors         |
| books           |
| genres          |
| total_sales     |
+-----------------+

mysql> describe authors;
+----------+--------------+------+-----+---------+----------------+
| Field    | Type         | Null | Key | Default | Extra          |
+----------+--------------+------+-----+---------+----------------+
| id       | int          | NO   | PRI | NULL    | auto_increment |
| f_name   | varchar(255) | YES  |     | NULL    |                |
| l_name   | varchar(255) | YES  |     | NULL    |                |
| pronoun  | varchar(255) | YES  |     | NULL    |                |
| birthday | date         | YES  |     | NULL    |                |
+----------+--------------+------+-----+---------+----------------+

CREATE TABLE authors (
  id INT NOT NULL AUTO_INCREMENT,
  f_name VARCHAR(255) NOT NULL,
  l_name VARCHAR(255) NOT NULL,
  pronoun VARCHAR(32) NOT NULL,
  birthday DATE,
  PRIMARY KEY ( id )
);

;-- BUNCH OF TEST DATA!
INSERT INTO authors (f_name, l_name, pronoun, birthday )
  VALUES ( 'Steven', 'King', 'he/him', '1947-09-24' );
INSERT INTO authors ( f_name, l_name, pronoun, birthday )
  VALUES ( 'James', 'Baldwin', 'he/him', '1974-07-02' );
INSERT INTO authors ( f_name, l_name, pronoun, birthday )
  VALUES ( 'Octavia', 'Butler', 'she/her', '1947-06-27' );
INSERT INTO authors ( f_name, l_name, pronoun, birthday )
  VALUES ( 'Ann', 'Leckie', 'she/her', '1966-03-02' );

mysql> describe genres;
+----------+--------------+------+-----+---------+----------------+
| Field    | Type         | Null | Key | Default | Extra          |
+----------+--------------+------+-----+---------+----------------+
| id       | int          | NO   | PRI | NULL    | auto_increment |
| name     | varchar(255) | YES  |     | NULL    |                |
+----------+--------------+------+-----+---------+----------------+

CREATE TABLE genres (
  id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255),
  PRIMARY KEY ( id )
);

INSERT INTO genres (name) VALUES ('horror');
INSERT INTO genres (name) VALUES ('sci-fi');
INSERT INTO genres (name) VALUES ('essay');

mysql> describe books;
+----------+--------------+------+-----+---------+----------------+
| Field    | Type         | Null | Key | Default | Extra          |
+----------+--------------+------+-----+---------+----------------+
| id       | int          | NO   | PRI | NULL    | auto_increment |
| title    | varchar(255) | YES  |     | NULL    |                |
| genre_id | int          | YES  |     | NULL    |                |
| pub_date | date         | YES  |     | NULL    |                |
| cost     | float        | YES  |     | NULL    |                |
| pages    | int          | YES  |     | NULL    |                |
+----------+--------------+------+-----+---------+----------------+

CREATE TABLE books (
  id INT NOT NULL AUTO_INCREMENT,
  title VARCHAR(255),
  genre_id INT,
  author_id INT,
  pub_date DATE,
  cost FLOAT,
  pages int,
  PRIMARY KEY ( id )
);

INSERT INTO books (title, genre_id, author_id, pub_date, cost, pages) VALUES (
  'No Name in the Street', 3, 3, '1972-01-01', 12.5, 123
);
INSERT INTO books (title, genre_id, author_id, pub_date, cost, pages) VALUES (
  'Dawn', 2, 2, '1987-01-01', 15.0, 223
);
INSERT INTO books (title, genre_id, author_id, pub_date, cost, pages) VALUES (
  'Rita Hayworth and Shawshank Redemption', 1, 1, '1982-01-01', 23.0, 340
);
INSERT INTO books (title, genre_id, author_id, pub_date, cost, pages) VALUES (
  'Fledgling', 1, 2, '2007-01-01', 16.33, 310
);
INSERT INTO books (title, genre_id, author_id, pub_date, cost, pages) VALUES (
  'Ancillary Justice', 2, 4, '2013-01-01', 10.19, 416
);


> We actually don't need this to be a separate table...

mysql> describe total_sales;
+----------+--------------+------+-----+---------+----------------+
| Field    | Type         | Null | Key | Default | Extra          |
+----------+--------------+------+-----+---------+----------------+
| id       | int          | NO   | PRI | NULL    | auto_increment |
| author_id| int          | YES  |     | NULL    |                |
| book_id  | int          | YES  |     | NULL    |                |
| units_sold int          | YES  |     | NULL    |                |
+----------+--------------+------+-----+---------+----------------+

CREATE TABLE total_sales (
  id INT NOT NULL AUTO_INCREMENT,
  book_id INT,
  units_sold INT,
  PRIMARY KEY ( id )
);

INSERT INTO total_sales (book_id, units_sold) VALUES (1, 882771);
INSERT INTO total_sales (book_id, units_sold) VALUES (2, 3509339);
INSERT INTO total_sales (book_id, units_sold) VALUES (3, 5582771);
INSERT INTO total_sales (book_id, units_sold) VALUES (4, 1102210);
INSERT INTO total_sales (book_id, units_sold) VALUES (5, 7283311);


Let's say, you want to do the following: 
- return a table of net profit by author for everything in the YA-FANTASY genre


SELECT net_profit from ( 
  SELECT ts.units_sold, b.cost FROM total_sales AS ts
  JOIN books as b on ts.book_id = b.id
  SELECT person.id from sales where SALES > 10000; 
)

SELECT person from authors where SALES > 10000; 
