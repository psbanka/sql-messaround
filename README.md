We are basing this off of [this](https://www.linkedin.com/learning/mysql-advanced-topics/creating-an-index?autoAdvance=true&autoSkip=false&autoplay=true&resume=true&u=83558730)

BTW: there is [SQL fiddle!](http://sqlfiddle.com/#!2/8ea00/1)

Maybe we will also do this one in the future:
[a specific linked-in learning tutorial](https://www.linkedin.com/learning/advanced-sql-for-query-tuning-and-performance-optimization/reduce-query-reponse-time-with-query-tuning?u=83558730).

## General setup notes

1. install mysql on your macbook with `brew install mysql`

2. set up your user password (fill in details here because I forgot)

3. run your mysql daemon with `mysqld` in a terminal tab you don't want to use. Note you can't ctrl-c that thing. You need to just close the tab or `kill` the thing.

## Day 1: Messing with sub-queries and temp-tables

> Branch: `day-1`

Get *your* database started with this:

```
mysql -u root -p < Databases/world-mysql.sql
```

This database has some fun country-code data. We then figured out how to do a sub-query.

> aside: Here's a nice alias to be able to run stuff easily from the console:

```
alias sql='mysql -D world -u root --password=my-new-password'
```

to run this query, feed it into the sql command like so:

```
sql < messaround.sql
```

You can do a simple sub-query without a join as long as the sub-query only has
one column, like this:

```
select Name from country where code2 in (
  select SubStr(b, 1, 2) from t
);
```

But as soon as you have a sub-query with more than one column, you'll need a join (especially if you want to pull data from that sub-query):

```
SELECT ss.State, ss.SCode, c.Name, c.Region FROM (
   SELECT SUBSTR(a, 1, 2) as State,
          SUBSTR(a, 3) as SCode, 
          SUBSTR(b, 1, 2) as Country,
          SUBSTR(b, 3) as CCode
   FROM t
) as ss
JOIN country AS c
  ON c.code2 = ss.Country;
```

We added a join

### Questions

1. What is the purpose of a sub-select

Pulling out a smaller portion of data to then reference in a larger select
statement. Pulling a couple of different tables together to pull it into its own
table to query against. 

Pulling out a smaller portion of data to then reference in a larger select
statement. Pulling a couple of different tables together to pull it into its own
table to query against. 

from the tutorial: "sub-selects are a convenient way of making your data
available in different forms while keeping your database schema simple and
well-organized"

2. When is a sub-select particularly useful

What about our certificates table with a couple million rows? Maybe you could
limit that?

3. How does a sub-select optimize a query?

Cool, I can limit the certificates, why is that different than chaining?

## Day 2: MORE with sub-selects!

> Branch: `day-2`

We want to see album-title, album-artist, track-number and track-title for every
track in an album which has at least one track which is < 90s.

### Can we do this without using a sub-query?

Well, at least *we* can't! IN `day-2.sql` we saw the video, and we tried to
accomplish the same thing through "simpler" sql statements (i.e. not using a
sub-select). We couldn't do it! 

Our approach was to do left-outer-join. Note that MySQL can't really do a l-o-j,
but it can sort of be simulated with this UNION trick:

```sql
SELECT * FROM track
  LEFT JOIN album ON track.album_id = album.id
  WHERE track.duration < 90
UNION
  SELECT * FROM track
  RIGHT JOIN album ON track.album_id = album.id
  WHERE track.duration < 90;
```
Output:

```
id	album_id	title	track_number	duration	id	title	artist	label	released
19	11	Sgt. Pepper's Lonely Hearts Club Band	6	76	11	Hendrix in the West	Jimi Hendrix	Polydor	1972-01-01
40	13	Sapphire Bullets of Pure Love	4	24	13	Birds of Fire	Mahavishnu Orchestra	Columbia	1973-03-01
```

Hey, that didn't display every track!

### use sub-queries

Start with a join between the album table and the track table as follows:

```sql
SELECT *
  FROM track AS t 
  JOIN album AS a
    ON t.album_id = a.id
;
```

NEXT, we need a `WHERE` clause to only return the album-information that contain
tracks < 90s

```sql
SELECT *
  FROM track AS t 
  JOIN album AS a
    ON t.album_id = a.id
    WHERE a.id IN (
      SELECT DISTINCT album_id from track WHERE duration < 90
    )
;
```

Finally, clean up the data and only show what we care about:

```sql
SELECT a.title as album, a.artist, t.track_number as seq, t.title AS track_title, t.duration as secs
  FROM track AS t 
  JOIN album AS a
    ON t.album_id = a.id
    WHERE a.id IN (
      SELECT DISTINCT album_id from track WHERE duration < 90
    )
  ORDER BY album
;
```

Also, if we run the select inside the join, we get only the tracks that have <
90s (same as what we did at the beginning with the two joins):

```sql
SELECT a.title as album, a.artist, t.track_number as seq, t.title AS track_title, t.duration as secs
  FROM album AS a 
  JOIN (
    SELECT DISTINCT album_id, track_number, duration, title
           FROM track
           WHERE duration < 90
  ) as t
  ON t.album_id = a.id
  ORDER BY a.title
;
```

### Flash-cards

> What is the syntax of a sub-query?


```
SELECT ss.State, ss.SCode, c.Name, c.Region FROM (
   SELECT SUBSTR(a, 1, 2) as State,
          SUBSTR(a, 3) as SCode, 
          SUBSTR(b, 1, 2) as Country,
          SUBSTR(b, 3) as CCode from t
) as ss
JOIN country AS c
  ON c.code2 = ss.Country;
```

## Day 3: Turning your sub-selects into views!

> Branch: `day-3`

First of all, you can do cool math shit in SQL! Check this out:

```sql
 -- LOOK AT OUR BAD ASS SQL!
use album;
SELECT duration, duration / 60 as m, duration MOD 60 as s from track; -- NOTE THAT / gives decimals
SELECT *, duration DIV 60 as m, duration MOD 60 as s from track; -- DIV does INT()
```
 
 You can create views! They get stored in the DB as if they were a normal table:

```sql
 CREATE view trackTime AS
SELECT *, duration DIV 60 as m, duration MOD 60 as s from track; -- DIV does INT()

mysql> show tables;
+-----------------+
| Tables_in_album |
+-----------------+
| album           |
| track           |
| tracktime       |
+-----------------+
3 rows in set (0.00 sec)

mysql> describe tracktime;
+--------------+--------------+------+-----+---------+-------+
| Field        | Type         | Null | Key | Default | Extra |
+--------------+--------------+------+-----+---------+-------+
| id           | int          | NO   |     | 0       |       |
| album_id     | int          | YES  |     | NULL    |       |
| title        | varchar(255) | YES  |     | NULL    |       |
| track_number | int          | YES  |     | NULL    |       |
| duration     | int          | YES  |     | NULL    |       |
| m            | bigint       | YES  |     | NULL    |       |
| s            | bigint       | YES  |     | NULL    |       |
+--------------+--------------+------+-----+---------+-------+
```

> NOTE: This view is not a table, but it shows in the table list above. If you
try to make a new one, mysql will get pissy. You have to do a `drop view
tracktime` first!

```sql
mysql> CREATE view trackTime AS
    -> SELECT album_id, title, duration DIV 60 as m, duration MOD 60 as s from track; -- DIV does INT()
ERROR 1050 (42S01): Table 'trackTime' already exists
mysql>
mysql> drop table trackTime;
ERROR 1051 (42S02): Unknown table 'album.tracktime'
mysql> drop view trackTime;
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE view trackTime AS
    -> SELECT album_id, title, duration DIV 60 as m, duration MOD 60 as s from track; -- DIV does INT()
Query OK, 0 rows affected (0.01 sec)

mysql>
mysql> describe trackTime;
+----------+--------------+------+-----+---------+-------+
| Field    | Type         | Null | Key | Default | Extra |
+----------+--------------+------+-----+---------+-------+
| album_id | int          | YES  |     | NULL    |       |
| title    | varchar(255) | YES  |     | NULL    |       |
| m        | bigint       | YES  |     | NULL    |       |
| s        | bigint       | YES  |     | NULL    |       |
+----------+--------------+------+-----+---------+-------+
```

> SIDE-BAR: You can do cool string formatting shit like this:

```sql
SELECT t.title, CONCAT(tt.m, ":", LPAD(tt.s, 2, 0)) AS time
  FROM TRACK as t
  JOIN tracktime as tt
    ON t.id = tt.track_id
```

What happens if we try to update a view manually?

```sql
mysql> INSERT INTO tracktime (album_id, track_id, title) VALUES (123, 123343, "FOO");
ERROR 1471 (HY000): The target table tracktime of the INSERT is not insertable-into
```

Q & A: 
- is it permanently saved, this view?

  YES - you can exit the session and re-enter

- what happens if underlying tables are updated?

  that shit is updated in real-time, yo

- what happens if I make another view with the same name: does it replace it? does it make a new one?

  can't do it. drop it first if you don't like it

- where is this thing stored? memory? db? how do I get rid of it?

  DB. kill it with `drop view`

- when is a view better to use than a longer SQL statement?

  maybe you have lower-skill SQL users, maybe you don't want to keep typing
  complex joins, maybe you want different permissions
  
  
## Indexes

> Branch: `1-indexes`

1. What is an index?

A tool that allows for faster lookups of data in large data-sets. Typically a
Binary-tree structure that has to be stored AS PART of the table. If you drop
the table, the index is gonna disappear too.

2. When do you use an index?

- When you have a PRIMARY KEY for a field
- Columns used for ORDER BY
- Columns used in WHERE clauses (WHERE col = value; WHERE col > value;)

> DBA Note! When you have columns that are used regularly with a limited amount
of data (e.g. enums!). Allows you to avoid needing to query each row.

3. What are the costs/benefits of an index?

- Cost: Increased write time (cuz you have to write the index value also!)
- Cost: Increased database storage needs.
- Benefit: decreased search time!

4. How do you make an index?

- when you create a field, if it has a UNIQUE constraint, it will automatically create the index!
- CREATE INDEX <index-name> on <table-name> ( <column-1>, <column-2> );
- ALTER TABLE <table-name> ADD INDEX ( <column-1>, <column-2> ); !-- NOTE, this names your index for you!

> NOTE: you can add a UNIQUE index, and if you do, you might not be able to add
duplicate data any more!

5. How do you get rid of an index?

- ALTER TABLE <table-name> DROP INDEX <index-name>

6. Can we EDIT an existing index?? 🤔

Looks like all you can do is change the name of an index. Kinda crappy, if you
ask me.

- ALTER TABLE <table-name> RENAME INDEX <index-name> TO <new-index-name>;

7. Can you index on multiple columns?

Yes, but an index on `customer_id`, `source`, `created_at` can be used for `customer_id`
alone, but it cannot be used for `source` or `created_at` alone.

This reduces write-time, because it uses uses one "index-entry" for the combined index. (Squee to confirm?)

https://df.secretcdn.net/docs/teams/data_reliability/storage/mysql/best-practices/#indexing-strategies-more-power-more-speeeeeed

## Indexes

1. What is an index?

A tool that allows for faster lookups of data in large data-sets. Typically a Binary-tree structure that has to be stored AS PART of the table. If you drop the table, the index is gonna disappear too.

2. When do you use an index?

- When you have a PRIMARY KEY for a field
- Columns used for ORDER BY
- Columns used in WHERE clauses (WHERE col = value; WHERE col > value;)

> DBA Note! When you have columns that are used regularly with a limited amount
of data (e.g. enums!). Allows you to avoid needing to query each row. Notice 

3. What are the costs/benefits of an index?

- Cost: Increased write time (cuz you have to write the index value also!)
- Cost: Increased database storage needs.
- Benefit: decreased search time!

### Making Indexes

> Branch: `2-indexes`

1. How do you make an index?

- when you create a field, if it has a UNIQUE constraint, it will automatically create the index!
- CREATE INDEX <index-name> on <table-name> ( <column-1>, <column-2> );
- ALTER TABLE <table-name> ADD INDEX ( <column-1>, <column-2> ); !-- NOTE, this names your index for you!

> NOTE: you can add a UNIQUE index, and if you do, you might not be able to add duplicate data any more!

2. How do you get rid of an index?

- ALTER TABLE <table-name> DROP INDEX <index-name>

3. Can we EDIT an existing index?? 🤔

Looks like all you can do is change the name of an index. Kinda crappy, if you ask me.

- ALTER TABLE <table-name> RENAME INDEX <index-name> TO <new-index-name>;

4. Can you index twice on the same column?

One can create an index in any way your imagination will lead you. But we have discovered at least five ways:

1. set the primary key (e.g.

```sql
USE scratch;
DROP TABLE IF EXISTS test;
CREATE TABLE test (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY
);
```

OUTPUT
```
SHOW INDEX FROM TEST;
+-------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| Table | Non_unique | Key_name | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment | Visible | Expression |
+-------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| test  |          0 | PRIMARY  |            1 | id          | A         |           0 |     NULL |   NULL |      | BTREE      |         |               | YES     | NULL       |
+-------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
```

2. Add the `UNIQUE` constraint to a column:
```sql
USE scratch;
DROP TABLE IF EXISTS test;
CREATE TABLE test (
  string1 VARCHAR(128) UNIQUE
);
```

```
mysql> SHOW INDEX FROM TEST;
+-------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| Table | Non_unique | Key_name | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment | Visible | Expression |
+-------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| test  |          0 | string1  |            1 | string1     | A         |           0 |     NULL |   NULL | YES  | BTREE      |         |               | YES     | NULL       |
+-------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
```

3. use the SQL command `INDEX`  or (`UNIQUE INDEX`) as part of the `CREATE TABLE` command
```sql
USE scratch;
DROP TABLE IF EXISTS test;
CREATE TABLE test (
  string1 VARCHAR(128),
  INDEX i_str2 (string1)
);
```

```
SHOW INDEX FROM TEST;
+-------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| Table | Non_unique | Key_name | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment | Visible | Expression |
+-------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| test  |          1 | i_str2   |            1 | string1     | A         |           0 |     NULL |   NULL | YES  | BTREE      |         |               | YES     | NULL       |
+-------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
```

4. alter table...
```sql
ALTER TABLE TEST ADD INDEX `i_str3` (string1);
```

5. `CREATE INDEX`:

```sql
CREATE INDEX i_str4 ON test(string1);
```

### QUESTIONS:

Can you add two indexes on the same row? 
- you bet your ass. SQL don't care.


### EXPERIMENT!

[Index messaround](./index-messaround.md) 
  - imports a big file from csv
  - changes data-types
  - plays around with index-query speeds


## SHOWING INDEXES

- Hey, did you know that there is a special database in mysql that has lots of interesting things?
- it looks like you could *really hose* your whole system by messing around with it!
- it's called `information_schema`
```
mysql> use information_schema;
```
- among other things, it stores index information 
```
mysql> select distinct TABLE_NAME, INDEX_NAME from information_schema.statistics limit 10;
+-----------------------------------------+------------+
| TABLE_NAME                              | INDEX_NAME |
+-----------------------------------------+------------+
| innodb_table_stats                      | PRIMARY    |
| innodb_index_stats                      | PRIMARY    |
| users                                   | PRIMARY    |
| City                                    | PRIMARY    |
| Country                                 | PRIMARY    |
| CountryLanguage                         | PRIMARY    |
| track                                   | PRIMARY    |
| emails                                  | PRIMARY    |
| replication_group_configuration_version | PRIMARY    |
| album                                   | PRIMARY    |
+-----------------------------------------+------------+
10 rows in set (0.02 sec)
```


or, from a particular database:
```
mysql> select distinct TABLE_NAME, INDEX_NAME from information_schema.statistics where table_schema = 'hhs';
+-------------+-------------+
| TABLE_NAME  | INDEX_NAME  |
+-------------+-------------+
| relief_fund | idx_on_city |
| relief_fund | PRIMARY     |
+-------------+-------------+
2 rows in set (0.01 sec)
```

## Dropping indexes

This is just running the `drop index` command as follows:

```sql
mysql> show indexes in relief_fund;
+-------------+------------+-------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| Table       | Non_unique | Key_name    | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment | Visible | Expression |
+-------------+------------+-------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| relief_fund |          0 | PRIMARY     |            1 | id          | A         |      412128 |     NULL |   NULL |      | BTREE      |         |               | YES     | NULL       |
| relief_fund |          1 | idx_on_city |            1 | city        | A         |       14363 |     NULL |   NULL | YES  | BTREE      |         |               | YES     | NULL       |
+-------------+------------+-------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
2 rows in set (0.03 sec)

mysql> drop index idx_on_city on relief_fund;
Query OK, 0 rows affected (0.09 sec)
Records: 0  Duplicates: 0  Warnings: 0

mysql> show indexes in relief_fund;
+-------------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| Table       | Non_unique | Key_name | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment | Visible | Expression |
+-------------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| relief_fund |          0 | PRIMARY  |            1 | id          | A         |      412128 |     NULL |   NULL |      | BTREE      |         |               | YES     | NULL       |
+-------------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
1 row in set (0.00 sec)
```

## Multi-column indexes

Questions:

- can you dump an index raw to the console?

- when I do a query, how do know what indexes get used? (Answered below)

- RELATING TO THE VIDEO ITSELF: what's up with this example? we don't really
need an index in order to do an ORDER BY, right? Why was he relating that the
index had anything to do with the output when it was clearly the ORDER BY that
had to do with the output? Can you remove the ORDER BY and it still does it in
that order because of something to do with the indexing?

example:

```sql
USE scratch;
DROP TABLE IF EXISTS test;
CREATE TABLE test (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  string1 VARCHAR(128),
  string2 VARCHAR(128),
  INDEX twostrs (string1,string2)
);

INSERT INTO test (string1, string2) VALUES ('foo', 'bar'), ('this', 'that'), ('another', 'row'), ('foo', 'alpha');
SELECT string1, string2 FROM test ORDER BY string1, string2;

SHOW INDEX FROM test;
```

Check this out:

```sql
mysql> SELECT string1, string2 FROM test ORDER BY string1, string2;
+---------+---------+
| string1 | string2 |
+---------+---------+
| another | row     |
| foo     | alpha   |
| foo     | bar     |
| this    | that    |
+---------+---------+
4 rows in set (0.00 sec)

mysql> SELECT string1, string2 FROM test;
+---------+---------+
| string1 | string2 |
+---------+---------+
| another | row     |
| foo     | alpha   |
| foo     | bar     |
| this    | that    |
+---------+---------+
4 rows in set (0.00 sec)

mysql> show indexes in test;
+-------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| Table | Non_unique | Key_name | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment | Visible | Expression |
+-------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| test  |          0 | PRIMARY  |            1 | id          | A         |           4 |     NULL |   NULL |      | BTREE      |         |               | YES     | NULL       |
| test  |          1 | twostrs  |            1 | string1     | A         |           3 |     NULL |   NULL | YES  | BTREE      |         |               | YES     | NULL       |
| test  |          1 | twostrs  |            2 | string2     | A         |           4 |     NULL |   NULL | YES  | BTREE      |         |               | YES     | NULL       |
+-------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
3 rows in set (0.01 sec)

mysql> drop index twostrs on test;
Query OK, 0 rows affected (0.01 sec)
Records: 0  Duplicates: 0  Warnings: 0

mysql> SELECT string1, string2 FROM test;
+---------+---------+
| string1 | string2 |
+---------+---------+
| foo     | bar     |
| this    | that    |
| another | row     |
| foo     | alpha   |
+---------+---------+
4 rows in set (0.00 sec)
```

ANSWER:
- order-by was not necessary. when the index existed, the output was ordered for us. when the index was removed, the ordering went away.

- NOTE that indexes are applied sequentially. if you have a two-column index and you search for things on the first column, the index will be used.

- ALSO, if you have a single-column index and you do a two-column select, that index will NOT be used.


Look at this. We have an index on ONLY string1 and we do a query for string1, string2:

```sql
mysql> SELECT string1, string2 FROM test;
+---------+---------+
| string1 | string2 |
+---------+---------+
| foo     | bar     |
| this    | that    |
| another | row     |
| foo     | alpha   |
+---------+---------+
4 rows in set (0.00 sec)
```

NOT sorted.

Then we do a query for *ONLY* string1:

```sql

mysql> SELECT string1 FROM test;
+---------+
| string1 |
+---------+
| another |
| foo     |
| foo     |
| this    |
+---------+
4 rows in set (0.00 sec)
```

SORTED. This indicates that the index for string1 was *not* used for the query
for string1,string2. It was only used for the single-column query.

Now, re-create the two-column index:
```sql
mysql> drop index one_str on test;
Query OK, 0 rows affected (0.00 sec)
Records: 0  Duplicates: 0  Warnings: 0

mysql> create index twostr ON test(string1,string2);
Query OK, 0 rows affected (0.01 sec)
Records: 0  Duplicates: 0  Warnings: 0
```

When we select `string1` from test by itself without also selecting string1, it's still alphabetized.

```
mysql> select string1,string2 from test;
+---------+---------+
| string1 | string2 |
+---------+---------+
| another | row     |
| foo     | alpha   |
| foo     | bar     |
| this    | that    |
+---------+---------+
4 rows in set (0.00 sec)

mysql> select string1 from test;
+---------+
| string1 |
+---------+
| another |
| foo     |
| foo     |
| this    |
+---------+
4 rows in set (0.00 sec)
```

CHECK THIS OUT: if you have an index string1,string2 and only query for string2, you get the order that was imposed by sorting string1 first from the index.

```sql
mysql> select string2 from test;
+---------+
| string2 |
+---------+
| row     |
| alpha   |
| bar     |
| that    |
+---------+
4 rows in set (0.00 sec)
```

ALSO! HOT TIP! You can see exactly what mysql is up to by putting `EXPLAIN` in front of any query. It will tell you what indexes were applied in your query:

```sql
mysql> explain select string2 from test;
+----+-------------+-------+------------+-------+---------------+--------+---------+------+------+----------+-------------+
| id | select_type | table | partitions | type  | possible_keys | key    | key_len | ref  | rows | filtered | Extra       |
+----+-------------+-------+------------+-------+---------------+--------+---------+------+------+----------+-------------+
|  1 | SIMPLE      | test  | NULL       | index | NULL          | twostr | 1030    | NULL |    4 |   100.00 | Using index |
+----+-------------+-------+------------+-------+---------------+--------+---------+------+------+----------+-------------+
1 row in set, 1 warning (0.00 sec)
```

# Stored Routines

```sql
USE album;
DROP FUNCTION IF EXISTS testfunc;
DELIMITER //
CREATE FUNCTION testfunc(s VARCHAR(255))
RETURNS VARCHAR(255)
NO SQL
  BEGIN
    RETURN CONCAT("Hello, ", s, "!");
  END //
DELIMITER ;
```

this works:
```sql
USE album;
DROP FUNCTION IF EXISTS track_len;

DELIMITER //
CREATE FUNCTION track_len(seconds INT)
RETURNS VARCHAR(16)
DETERMINISTIC
BEGIN
    RETURN CONCAT_WS(':', seconds DIV 60, LPAD(seconds MOD 60, 2, '0' ));
END //
DELIMITER ;
```

## Questions

- What's the difference between a function and a **procedure**?

It would seem that a procedure return "table" instead of a scalar value, but we
haven't really played with procedures yet.

- In the case of a select statement return, is it executing the SQL or is
it just return the select statement for further modification?

- why would you use a function over a view?

It would seem that a function can be a bit more flexible insofar as you don't
have to link it to a particular query. And you can apply say, data transforms
ad-hoc using the function whenever you want. e.g. converting seconds to "MM:SS"
format.

Cleaner to call `trac_len()` in the query than to mash all that SQL in your
query directly.

- would like to have more info on the difference between DETERMINISTIC, NO SQL, READS SQL DATA, etc

?

- Is there new programming syntax for this stuff? Where do we find that documentation?

?

- How does a WHILE loop work in a FUNCTION context?

```sql
USE album;
DROP FUNCTION IF EXISTS foo;

DELIMITER //
CREATE FUNCTION foo(seconds INT)
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
  DECLARE max_value INT UNSIGNED DEFAULT seconds;
  DECLARE int_value INT UNSIGNED DEFAULT 0;
  DECLARE str_value VARCHAR(255) DEFAULT '';
  WHILE int_value < max_value DO
    SET int_value = int_value + 1;
  END WHILE;
  RETURN int_value;
END //
DELIMITER ;
```

- What exactly does mysql do with all this return and function type declaration business?

It seems like it just casts shit for you.

mysql MAKES YOU tell it what the type of the return value is, but it
seems like it doesn't really care, or maybe it just casts it for you without
telling you, which is totally rude and very JavaScript if you ask me.

Look at this stupid shit!:

```sql
mysql> select foo("66");
+-----------+
| foo("66") |
+-----------+
| 66        |
+-----------+
```

# Stored procedures

Hey, did you know you can duplicate a table like this?

```sql
mysql> create table new_album select * from album;
```

That just copies both the table definition and all the table data from one table to another!

You can also swap two tables like this:

```
mysql> create table new_album select * from album;
mysql> select *  from new_album where id=20;
+----+-------+--------------+---------+----------+
| id | title | artist       | label   | released |
+----+-------+--------------+---------+----------+
| 20 | test1 | Jimi Hendrix | Homeboy | NULL     |
+----+-------+--------------+---------+----------+
1 row in set (0.00 sec)

mysql> DELETE  from new_album where id=20;
Query OK, 1 row affected (0.01 sec)

mysql> select * from new_album;
+----+------------------------+-----------------------------------+------------+------------+
| id | title                  | artist                            | label      | released   |
+----+------------------------+-----------------------------------+------------+------------+
|  1 | Two Men with the Blues | Willie Nelson and Wynton Marsalis | Blue Note  | 2008-07-08 |
| 11 | Hendrix in the West    | Jimi Hendrix                      | Polydor    | 1972-01-01 |
| 12 | Rubber Soul            | The Beatles                       | Parlophone | 1965-12-03 |
| 13 | Birds of Fire          | Mahavishnu Orchestra              | Columbia   | 1973-03-01 |
| 16 | Live And               | Johnny Winter                     | Columbia   | 1971-05-01 |
| 17 | Apostrophe             | Frank Zappa                       | DiscReet   | 1974-04-22 |
| 18 | Kind of Blue           | Miles Davis                       | Columbia   | 1959-08-17 |
+----+------------------------+-----------------------------------+------------+------------+
7 rows in set (0.00 sec)

mysql> select * from album;
+----+------------------------+-----------------------------------+------------+------------+
| id | title                  | artist                            | label      | released   |
+----+------------------------+-----------------------------------+------------+------------+
|  1 | Two Men with the Blues | Willie Nelson and Wynton Marsalis | Blue Note  | 2008-07-08 |
| 11 | Hendrix in the West    | Jimi Hendrix                      | Polydor    | 1972-01-01 |
| 12 | Rubber Soul            | The Beatles                       | Parlophone | 1965-12-03 |
| 13 | Birds of Fire          | Mahavishnu Orchestra              | Columbia   | 1973-03-01 |
| 16 | Live And               | Johnny Winter                     | Columbia   | 1971-05-01 |
| 17 | Apostrophe             | Frank Zappa                       | DiscReet   | 1974-04-22 |
| 18 | Kind of Blue           | Miles Davis                       | Columbia   | 1959-08-17 |
| 20 | test1                  | Jimi Hendrix                      | Homeboy    | NULL       |
+----+------------------------+-----------------------------------+------------+------------+
8 rows in set (0.00 sec)

mysql> RENAME TABLE album to album_old, new_album to album;
Query OK, 0 rows affected (0.02 sec)
```

And now `album` does not have id `20`


Stored procedures are used in the "statement" context and stored functions are used in the "expression" context. Bill Weinman thinks this is in an important distiction.


# MORE with stored procedures

Q: 6s into the video on language extensions, we see:

```sql

DELIMITER //
CREATE PROCEDURE str_count()
BEGIN
  DECLARE max_value INT UNSIGNED DEFAULT 5;
  DECLARE int_value INT UNSIGNED DEFAULT 0;
  DECLARE str_value VARCHAR(255) DEFAULT '';
  
  WHILE int_value < max_value DO
    SET int_value = int_value + 1;
    SET str_value = CONCAT(str_value, int_value, ' ');
  END WHILE;
  SELECT str_value;
END //
DELIMITER ;

CALL str_count();

DROP PROCEDURE IF EXISTS str_count;
```

SO what's the deal with Stored procedures? Why is this not a function? What indeed is the fucking difference?

```sql
DROP FUNCTION IF EXISTS str_count;

DELIMITER //
CREATE FUNCTION str_count()
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
  DECLARE max_value INT UNSIGNED DEFAULT 5;
  DECLARE int_value INT UNSIGNED DEFAULT 0;
  DECLARE str_value VARCHAR(255) DEFAULT '';
  
  WHILE int_value < max_value DO
    SET int_value = int_value + 1;
    SET str_value = CONCAT(str_value, int_value, ' ');
  END WHILE;
  RETURN str_value;
END //
DELIMITER ;
```

A: This is annoying. It looks like functions have to `RETURN`, but Stored
Procedures have to end in a `SELECT`. Also, functions have `DETERMINISTIC`. But,
as you can see from the above examples, you can do pretty-much the same kinda
shit in both things. Not sure why it's helpful to distinguish them.


# Transactions

Transactions allow you to keep a DB in sync by "storing" a db state, making changes, and -- if one of them fails, going back to stored DB state.

What happens if someone else tries writing to the same row that you're modifying when you're doing a transaction? What happens in a race-condition?

1. Here's a thing which should fail inside a transaction. What happens?

Setup:

```sql
USE scratch;
DROP TABLE IF EXISTS widgetInventory;
DROP TABLE IF EXISTS widgetSales;

CREATE TABLE widgetInventory (
  id INTEGER AUTO_INCREMENT PRIMARY KEY,
  description TEXT,
  onhand INTEGER NOT NULL
);

CREATE TABLE widgetSales (
  id INTEGER AUTO_INCREMENT PRIMARY KEY,
  inv_id INTEGER,
  quan INTEGER,
  price INTEGER
);

INSERT INTO widgetInventory ( description, onhand ) VALUES ( 'rock', 25 );
INSERT INTO widgetInventory ( description, onhand ) VALUES ( 'paper', 25 );
INSERT INTO widgetInventory ( description, onhand ) VALUES ( 'scissors', 25 );

SELECT * FROM widgetInventory;
```

1a. Something that WORKS:

```sql
START TRANSACTION;
INSERT INTO widgetSales ( inv_id, quan, price ) VALUES ( 1, 5, 500 );
UPDATE widgetInventory SET onhand = ( onhand - 5 ) WHERE id = 1;
COMMIT;
```

1b. Something that BREAKS:

```sql
START TRANSACTION;
INSERT INTO widgetSales ( inv_id, quan, price ) VALUES ( 5, 5, 500 );
UPDATE widgetInventory SET onhand = ( onhand - 5 ) WHERE id = 5;
COMMIT;
```

NOTE that this *actually doesn't break* and the transaction goes through because
`WHERE id = 5` just gives you zero rows affected. SO we end up getting a sales
entry for something that doesn't exist:

Here's the state of our DB after our bad thing:

```
mysql> select * from widgetInventory;
+----+-------------+--------+
| id | description | onhand |
+----+-------------+--------+
|  1 | rock        |     20 | <- still have ROCKS!
|  2 | paper       |     25 |
|  3 | scissors    |     25 |
+----+-------------+--------+
3 rows in set (0.00 sec)

mysql> select * from widgetSales;
+----+--------+------+-------+
| id | inv_id | quan | price |
+----+--------+------+-------+
|  1 |      1 |    5 |   500 |
|  2 |      5 |    5 |   500 | <- Sold a thing that doesn't exist!
+----+--------+------+-------+
2 rows in set (0.00 sec)
```

1c. Q: What kinds of errors does SQL notice by itself?

okay, so there's a thing called `ROLLBACK` that you can call instead of
`COMMIT`, but that requires you to manually notice somehow that things didn't go
the way you wanted them to. Does SQL notice sometimes on its own? AND, if you're
getting thousands-of-requests-per-small-time-unit, then you can't just do that!

```sql
START TRANSACTION;
INSERT INTO widgetSales ( inv_id, quan, price ) VALUES ( 5, 5, 500 );
UPDATE widgetInventory SET onhand = ( onhand - 5 ) WHERE poop = 5;
COMMIT;
```

Here's the output:
```
mysql> START TRANSACTION;
Query OK, 0 rows affected (0.00 sec)

mysql> INSERT INTO widgetSales ( inv_id, quan, price ) VALUES ( 5, 5, 500 );
Query OK, 1 row affected (0.00 sec)

mysql> UPDATE widgetInventory SET onhand = ( onhand - 5 ) WHERE poop = 5;
ERROR 1054 (42S22): Unknown column 'poop' in 'where clause'
mysql> COMMIT;
Query OK, 0 rows affected (0.00 sec)

mysql> select * from widgetSales;
+----+--------+------+-------+
| id | inv_id | quan | price |
+----+--------+------+-------+
|  1 |      1 |    5 |   500 |
|  2 |      5 |    5 |   500 |
|  3 |      5 |    5 |   500 |
+----+--------+------+-------+
3 rows in set (0.00 sec)
```

A: Nothing. SQL doesn't care if your statements succeed or fail. You either `COMMIT` or `ROLLBACK` on your own.

SO! Sql will commit it or roll it back, as you specify. But it's up to you to notice when you should call each thing.

HOMEWORK: Is there a rollback-if-error?


## Performance—

Q: the claim is that a transaction is more performant. But from what we saw, it
seems that the DB is doing exactly what you want every step of the way and then
somehow committing it all at the end. How does that increase performance? Isn't
it the case that the DB has to do all the work all the time?

Okay, so here is some SQL that takes some time to execute (from the video):

```sql
-- 03 Performance 

USE scratch;
DROP TABLE IF EXISTS test;
DROP PROCEDURE IF EXISTS insert_loop;
CREATE TABLE test ( id INTEGER AUTO_INCREMENT PRIMARY KEY, data TEXT );

DELIMITER //
CREATE PROCEDURE insert_loop( IN count INT UNSIGNED )
BEGIN
    DECLARE accum INT UNSIGNED DEFAULT 0;
    DECLARE start_time VARCHAR(32);
    DECLARE end_time VARCHAR(32);
    SET start_time = SYSDATE(6);
    WHILE accum < count DO
        SET accum = accum + 1;
        INSERT INTO test ( data ) VALUES ( 'this is a good sized line of text.' );
    END WHILE;
    SET end_time = SYSDATE(6);
    SELECT TIME_FORMAT(start_time, '%T.%f') AS `Start`,
        TIME_FORMAT(end_time, '%T.%f') AS `End`,
        TIME_FORMAT(TIMEDIFF(end_time, start_time), '%s.%f') AS `Elapsed Secs`;
END //
DELIMITER ;

START TRANSACTION;
CALL insert_loop(10000);
START TRANSACTION;

SELECT * FROM test ORDER BY id DESC LIMIT 10;

DROP TABLE IF EXISTS test;
DROP PROCEDURE IF EXISTS insert_loop;
```

Sure enough, if you don't have the transaction, it takes like 10x longer than if you do! 😳

Bill says that this speed is attributed to it using its "buffer" for these calls
rather than making individual calls. What is the MYSQL buffer?


# Triggers

What is a trigger?

it's like a callback. Some SQL that gets executed on every row insert? (is it ONLY row inserts?)

```sql
USE scratch;
DROP TABLE IF EXISTS widgetCustomer;
DROP TABLE IF EXISTS widgetSale;

CREATE TABLE widgetCustomer ( id INTEGER AUTO_INCREMENT PRIMARY KEY, name VARCHAR(64), last_order_id INT );
CREATE TABLE widgetSale ( id INTEGER AUTO_INCREMENT PRIMARY KEY, item_id INT, customer_id INT, quan INT, price INT );

INSERT INTO widgetCustomer (name) VALUES ('Bob');
INSERT INTO widgetCustomer (name) VALUES ('Sally');
INSERT INTO widgetCustomer (name) VALUES ('Fred');

SELECT * FROM widgetCustomer;

DROP TRIGGER IF EXISTS newWidgetSale;
DELIMITER //
CREATE TRIGGER newWidgetSale AFTER INSERT ON widgetSale 
    FOR EACH ROW
    BEGIN
         UPDATE widgetCustomer SET last_order_id = NEW.id WHERE widgetCustomer.id = NEW.customer_id;
    END //
DELIMITER ;

INSERT INTO widgetSale (item_id, customer_id, quan, price) VALUES (1, 3, 5, 1995);
INSERT INTO widgetSale (item_id, customer_id, quan, price) VALUES (2, 2, 3, 1495);
INSERT INTO widgetSale (item_id, customer_id, quan, price) VALUES (3, 1, 1, 2995);
SELECT * FROM widgetSale;
SELECT * FROM widgetCustomer;

```

What else can we make a trigger for? can we do BEFORE INSERT ON? or BEFORE UPDATE ON? or BEFORE DELETE ON?

```sql
DROP TRIGGER IF EXISTS deleteCustomer;
DELIMITER //
CREATE TRIGGER deleteCustomer BEFORE DELETE ON widgetCustomer 
    FOR EACH ROW
    BEGIN
         DELETE FROM widgetSale WHERE widgetSale.customer_id = OLD.id;
    END //
DELIMITER ;

DELETE FROM widgetCustomer WHERE name="Sally";
SELECT * FROM widgetSale;
SELECT * FROM widgetCustomer;
```

How about update?


> SIDE QUESTION: what's the difference between INT and INTEGER in the table def?

answer: it don't care. it's the same thing.

```sql
CREATE TABLE deadName (id INTEGER AUTO_INCREMENT PRIMARY KEY, old_name VARCHAR(64), new_name VARCHAR(64), customer_id INT);

DROP TRIGGER IF EXISTS keepTrackOfCustomerRenames;
DELIMITER //
CREATE TRIGGER keepTrackOfCustomerRenames BEFORE UPDATE ON widgetCustomer 
    FOR EACH ROW
    BEGIN
         INSERT INTO deadName (old_name, new_name, customer_id) VALUES (OLD.name, NEW.name, NEW.id);
    END //
DELIMITER ;

UPDATE widgetCustomer SET name = 'Robert' where name = "Bob";
SELECT * FROM widgetCustomer;
SELECT * FROM deadName;
```

## Preventing an update

Note the extremely esoteric call to abort the stuff:

`SIGNAL SQLSTATE '45000' set message_text = 'cannot update reconciled row: "widgetSale"';`

Bill says that this can't be used to roll a transaction back. Let's see what happens if we try:

```sql
USE scratch;
DROP TABLE IF EXISTS widgetCustomer;
DROP TABLE IF EXISTS widgetSale;

CREATE TABLE widgetCustomer ( id INTEGER AUTO_INCREMENT PRIMARY KEY, name VARCHAR(64), last_order_id INT );
CREATE TABLE widgetSale ( id INTEGER AUTO_INCREMENT PRIMARY KEY, item_id INT, customer_id INTEGER, quan INT, price INT,
    reconciled INT );
INSERT INTO widgetSale (item_id, customer_id, quan, price, reconciled) VALUES (1, 3, 5, 1995, 0);
INSERT INTO widgetSale (item_id, customer_id, quan, price, reconciled) VALUES (2, 2, 3, 1495, 1);
INSERT INTO widgetSale (item_id, customer_id, quan, price, reconciled) VALUES (3, 1, 1, 2995, 0);
SELECT * FROM widgetSale;

DROP TRIGGER IF EXISTS updateWidgetSale;
DELIMITER //
CREATE TRIGGER updateWidgetSale BEFORE UPDATE ON widgetSale
    FOR EACH ROW
    BEGIN
        IF OLD.id = NEW.id AND OLD.reconciled = 1 THEN
            SIGNAL SQLSTATE '45000' set message_text = 'cannot update reconciled row: "widgetSale"';
        END IF;
    END //
DELIMITER ;

START TRANSACTION;
UPDATE widgetSale SET quan = 9 WHERE id = 1;
UPDATE widgetSale SET quan = 9 WHERE id = 2;
COMMIT;

SELECT * FROM widgetSale;
```

so, in this case, it did throw an error to the screen, and made a little beeping
sound. But it went right ahead and commit the change but only to id 1 (not id
2).

```sql
mysql> START TRANSACTION;
Query OK, 0 rows affected (0.00 sec)

mysql> UPDATE widgetSale SET quan = 9 WHERE id = 1;
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0

mysql> UPDATE widgetSale SET quan = 9 WHERE id = 2;
ERROR 1644 (45000): cannot update reconciled row: "widgetSale"
mysql> COMMIT;
Query OK, 0 rows affected (0.00 sec)

mysql>
mysql> SELECT * FROM widgetSale;
+----+---------+-------------+------+-------+------------+
| id | item_id | customer_id | quan | price | reconciled |
+----+---------+-------------+------+-------+------------+
|  1 |       1 |           3 |    9 |  1995 |          0 |
|  2 |       2 |           2 |    3 |  1495 |          1 |
|  3 |       3 |           1 |    1 |  2995 |          0 |
+----+---------+-------------+------+-------+------------+
```

HOMEWORK: Is there a rollback-if-error?

Apparently we can set an exception handler like this:

```sql
USE scratch;
DROP TABLE IF EXISTS widgetCustomer;
DROP TABLE IF EXISTS widgetSale;

CREATE TABLE widgetCustomer ( id INTEGER AUTO_INCREMENT PRIMARY KEY, name VARCHAR(64), last_order_id INT );
CREATE TABLE widgetSale ( id INTEGER AUTO_INCREMENT PRIMARY KEY, item_id INT, customer_id INTEGER, quan INT, price INT,
    reconciled INT );
INSERT INTO widgetSale (item_id, customer_id, quan, price, reconciled) VALUES (1, 3, 5, 1995, 0);
INSERT INTO widgetSale (item_id, customer_id, quan, price, reconciled) VALUES (2, 2, 3, 1495, 1);
INSERT INTO widgetSale (item_id, customer_id, quan, price, reconciled) VALUES (3, 1, 1, 2995, 0);
SELECT * FROM widgetSale;

DROP TRIGGER IF EXISTS updateWidgetSale;
DELIMITER //
CREATE TRIGGER updateWidgetSale BEFORE UPDATE ON widgetSale
    FOR EACH ROW
    BEGIN
        IF OLD.id = NEW.id AND OLD.reconciled = 1 THEN
            SIGNAL SQLSTATE '45000' set message_text = 'cannot update reconciled row: "widgetSale"';
        END IF;
    END //
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_fail;
DELIMITER $$
CREATE PROCEDURE `sp_fail`()
BEGIN
  DECLARE `_rollback` BOOL DEFAULT 0;
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET `_rollback` = 1;
  START TRANSACTION;
  UPDATE widgetSale SET quan = 9 WHERE id = 1;
  UPDATE widgetSale SET quan = 9 WHERE id = 2;
  IF `_rollback` THEN
      ROLLBACK;
  ELSE
      COMMIT;
  END IF;
END$$
DELIMITER ;

CALL sp_fail();
SELECT * FROM widgetSale;
```

## Example: timestamp triggers!

Here's something we wanted to know: do we need a transaction around this stuff? Like, if the second trigger has two
things that happen (two inserts, say). And the first insert fails, then do we need to ROLLBACK ? 

We engineered a little test to see!

```sql
USE scratch;
DROP TABLE IF EXISTS widgetSale;
DROP TABLE IF EXISTS widgetCustomer;
DROP TABLE IF EXISTS widgetLog;

CREATE TABLE widgetCustomer ( id INTEGER AUTO_INCREMENT PRIMARY KEY, name VARCHAR(64), last_order_id INT, stamp VARCHAR(24) );
CREATE TABLE widgetSale ( id INTEGER AUTO_INCREMENT PRIMARY KEY, item_id INT, customer_id INTEGER, quan INT, price INT, stamp VARCHAR(24));
CREATE TABLE widgetLog ( id INTEGER AUTO_INCREMENT PRIMARY KEY, stamp VARCHAR(24) NOT NULL, event VARCHAR(64), username VARCHAR(64), tablename VARCHAR(64), table_id INT);

INSERT INTO widgetCustomer (name) VALUES ('Bob');
INSERT INTO widgetCustomer (name) VALUES ('Sally');
INSERT INTO widgetCustomer (name) VALUES ('Fred');
SELECT * FROM widgetCustomer;

DROP TRIGGER IF EXISTS stampSale;
DROP TRIGGER IF EXISTS newWidgetSale;
DELIMITER //
CREATE TRIGGER stampSale BEFORE INSERT ON widgetSale
    FOR EACH ROW
    BEGIN
        DECLARE nowstamp VARCHAR(24) DEFAULT NOW();
        IF NEW.customer_id > 2 THEN
           SET NEW.stamp = NULL;
        ELSE
            SET NEW.stamp = nowstamp;
        END IF;
    END //

CREATE TRIGGER newWidgetSale AFTER INSERT ON widgetSale 
    FOR EACH ROW
    BEGIN
        INSERT INTO widgetLog (stamp, event, username, tablename, table_id)
            VALUES (NEW.stamp, 'INSERT', USER(), 'widgetSale', NEW.id);
        UPDATE widgetCustomer SET last_order_id = NEW.id, stamp = NEW.stamp
             WHERE widgetCustomer.id = NEW.customer_id;
    END //
DELIMITER ;

INSERT INTO widgetSale (item_id, customer_id, quan, price) VALUES (1, 3, 5, 1995);
INSERT INTO widgetSale (item_id, customer_id, quan, price) VALUES (2, 2, 3, 1495);
INSERT INTO widgetSale (item_id, customer_id, quan, price) VALUES (3, 1, 1, 2995);

SELECT * FROM widgetSale;
SELECT * FROM widgetCustomer;
SELECT * FROM widgetLog;
```

The output of this thing (limiting to the INSERT and SELECT statements) is:

```sql
mysql> INSERT INTO widgetSale (item_id, customer_id, quan, price) VALUES (1, 3, 5, 1995);
ERROR 1048 (23000): Column 'stamp' cannot be null
mysql> INSERT INTO widgetSale (item_id, customer_id, quan, price) VALUES (2, 2, 3, 1495);
Query OK, 1 row affected (0.01 sec)

mysql> INSERT INTO widgetSale (item_id, customer_id, quan, price) VALUES (3, 1, 1, 2995);
Query OK, 1 row affected (0.00 sec)

mysql> SELECT * FROM widgetSale;
+----+---------+-------------+------+-------+---------------------+
| id | item_id | customer_id | quan | price | stamp               |
+----+---------+-------------+------+-------+---------------------+
|  2 |       2 |           2 |    3 |  1495 | 2022-06-03 10:42:13 |
|  3 |       3 |           1 |    1 |  2995 | 2022-06-03 10:42:14 |
+----+---------+-------------+------+-------+---------------------+
2 rows in set (0.00 sec)

mysql> SELECT * FROM widgetCustomer;
+----+-------+---------------+---------------------+
| id | name  | last_order_id | stamp               |
+----+-------+---------------+---------------------+
|  1 | Bob   |             3 | 2022-06-03 10:42:14 |
|  2 | Sally |             2 | 2022-06-03 10:42:13 |
|  3 | Fred  |          NULL | NULL                |
+----+-------+---------------+---------------------+
3 rows in set (0.00 sec)

mysql> SELECT * FROM widgetLog;
+----+---------------------+--------+----------------+------------+----------+
| id | stamp               | event  | username       | tablename  | table_id |
+----+---------------------+--------+----------------+------------+----------+
|  1 | 2022-06-03 10:42:13 | INSERT | root@localhost | widgetSale |        2 |
|  2 | 2022-06-03 10:42:14 | INSERT | root@localhost | widgetSale |        3 |
+----+---------------------+--------+----------------+------------+----------+
2 rows in set (0.00 sec)

```

SO YOU CAN SEE! that the failed insert (first one) DID NOT result in an entry in
widgetSale. That means that the entire INSERT operation got "rolled back" and we
did not have to do anything ourselves.


# Foreign key constraints

```sql

USE scratch;
DROP TABLE IF EXISTS widgetSale;
DROP TABLE IF EXISTS widgetCustomer;

CREATE TABLE widgetCustomer ( id INTEGER AUTO_INCREMENT PRIMARY KEY, name VARCHAR(64) );
CREATE TABLE widgetSale ( 
    id INTEGER AUTO_INCREMENT PRIMARY KEY, 
    item_id INT, 
    customer_id INT,
    quan INT,
    price INT,
    INDEX custid (customer_id),
    CONSTRAINT custid FOREIGN KEY custid(customer_id) REFERENCES widgetCustomer(id)
        ON UPDATE RESTRICT
        ON DELETE SET NULL
);

INSERT INTO widgetCustomer (name) VALUES ('Bob'), ('Sally'), ('Fred'), ('Squee');
INSERT INTO widgetSale (item_id, customer_id, quan, price) VALUES (1, 3, 5, 1995), (2, 2, 3, 1495), (3, 1, 1, 2995);
SELECT * FROM widgetSale;
SELECT * FROM widgetCustomer;

update widgetCustomer set id = 5 where id = 4;
UPDATE widgetCustomer SET id = 9 WHERE id = 2;
```

The values that you can constrain to are RESTRICT, CASCADE and SET NULL:

- RESTRICT means that mysql will NOT allow changes to that value on the parent
  table at all (will throw an error) unless there is NO ENTRY on the child table
  (example is changing the id of "Squee" above. mysql is okay with that because
  there is no sale entry for that customer.

- CASCADE will propagate changes from the parent table into the child table.
  Therefore changing Sally's customer ID in the widgetCustomer table ALSO changes
  it in the widgetSale table.

- SET NULL will null-out the entry in the child table if the parent table gets
  fucked with.

Also note that in line 1456, that index would have been created for us anyway
because in order to form this constraint it needs to do a lookup on that
constraint.

NOTE that we named the foreign key constraint because you can then fiddle with it. If not, 
then you have to do something like this:

```sql
SELECT * FROM information_schema.TABLE_CONSTRAINTS 
WHERE information_schema.TABLE_CONSTRAINTS.CONSTRAINT_TYPE = 'FOREIGN KEY' 
AND information_schema.TABLE_CONSTRAINTS.TABLE_NAME = 'widgetSale';
```

and you get this:

```sql
mysql> SELECT * FROM information_schema.TABLE_CONSTRAINTS
    -> WHERE information_schema.TABLE_CONSTRAINTS.CONSTRAINT_TYPE = 'FOREIGN KEY'
    -> AND information_schema.TABLE_CONSTRAINTS.TABLE_NAME = 'widgetSale';
+--------------------+-------------------+-------------------+--------------+------------+-----------------+----------+
| CONSTRAINT_CATALOG | CONSTRAINT_SCHEMA | CONSTRAINT_NAME   | TABLE_SCHEMA | TABLE_NAME | CONSTRAINT_TYPE | ENFORCED |
+--------------------+-------------------+-------------------+--------------+------------+-----------------+----------+
| def                | scratch           | widgetsale_ibfk_1 | scratch      | widgetSale | FOREIGN KEY     | YES      |
+--------------------+-------------------+-------------------+--------------+------------+-----------------+----------+
1 row in set (0.00 sec)
```

Then if you want to get rid of the foreign key, you would do this:

```sql
mysql> ALTER TABLE widgetSale DROP FOREIGN KEY widgetsale_ibfk_1;
Query OK, 0 rows affected (0.01 sec)
Records: 0  Duplicates: 0  Warnings: 0
```