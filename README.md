We are basing this off of [this](https://www.linkedin.com/learning/mysql-advanced-topics/creating-an-index?autoAdvance=true&autoSkip=false&autoplay=true&resume=true&u=83558730)

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






















