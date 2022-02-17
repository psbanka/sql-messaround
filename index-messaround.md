# We are doing a side exercise here to test out an index in real-life!

- create a multi-megabyte table in mysql using faker data
- or download a [big public data-set](https://learnsql.com/blog/free-online-datasets-to-practice-sql/)
- and fiddle around with indexes and see how that impacts both read and write performance on a local mysql instance?


## Import some data from a CSV file-source

Importing some data from [here](https://data.cdc.gov/api/views/kh8y-3es6/rows.csv?accessType=DOWNLOAD):

1. create the database and table

```sql
CREATE DATABASE IF NOT EXISTS hhs;
DROP TABLE relief_fund;
CREATE TABLE IF NOT EXISTS relief_fund (
  provider_name VARCHAR(100),
  state VARCHAR(2),
  city VARCHAR(50),
  payment VARCHAR(20)
);
```

1.5. restart the server with the right flags:
```
mysqld --secure-file-priv=`pwd`
```

2. Import stuff:

```sql
USE hhs
LOAD DATA INFILE '/Users/peba/play/sql-messaround/HHS_Provider_Relief_Fund.csv'
  INTO TABLE relief_fund 
  FIELDS TERMINATED BY ',' 
  ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 ROWS
;
```

  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,

** NOTE** - we want to add an ID row, we want to transform the payment string into an float.
then we want to time queries with/wo indices

TODO: 
- add the ID field
- backfill the data
- set it to the primary key

```sql
ALTER TABLE relief_fund ADD COLUMN id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT FIRST;
```

## Modify the `payment` field to be an integer

- change payment field to an int instead of a string

1. ADD ID field:

ALTER TABLE relief_fund ADD COLUMN id INT UNSIGNED FIRST ;


```sql
UPDATE relief_fund 
    SET _payment = (SELECT payment 
                 FROM relief_fund
                 WHERE relief_fund.id = relief_fund.id 
                 LIMIT 1);

!-- WHERE relief_fund._payment IS NULL; 
```

```sql
UPDATE relief_fund SET _payment = CAST(SUBSTR(payment, 1, -1) AS DECIMAL(65,2));
```
   SELECT SUBSTR(a, 1, 2) as State,

ANOTHER TRY:
```sql
SELECT ID, CAST(REPLACE(REPLACE(payment,',',''),'$','') AS DECIMAL(65,2)) as _payment
FROM relief_fund LIMIT 10;
!-- WHERE CAST(REPLACE(REPLACE(IFNULL(Amount,0),',',''),'$','') AS DECIMAL(10,2)) > 0
```

UPDATE table 
    SET value = (SELECT value 
                 FROM Table AS T1 
                 WHERE T1.ID = table.ID 
                     and t1.DATE <= table.Date 
                 LIMIT 1)
WHERE table.Value IS NULL; 

```sql
UPDATE relief_fund SET _payment = (
  SELECT _payment (
    SELECT id, CAST(REPLACE(REPLACE(payment,',',''),'$','') AS DECIMAL(65,2)) as _payment
    FROM relief_fund AS my_table
    WHERE my_table.id = relief_fund.id
  ) 
);
```

```sql
UPDATE relief_fund SET _payment = (
  SELECT _payment from (
    SELECT ID, CAST(REPLACE(REPLACE(payment,',',''),'$','') AS DECIMAL(65,2)) as _payment
    FROM relief_fund AS table_x
    WHERE table_x.id = relief_fund.id
  ) as my_table
);
```

Query OK, 414199 rows affected (27.90 sec)
Rows matched: 414199  Changed: 414199  Warnings: 0

```sql

mysql> ALTER TABLE relief_fund DROP COLUMN payment;
Query OK, 0 rows affected (1.21 sec)
Records: 0  Duplicates: 0  Warnings: 0

mysql> select * from relief_fund LIMIT 10;
+----+------------------------------------------------+-------+--------------+----------+
| id | provider_name                                  | state | city         | _payment |
+----+------------------------------------------------+-------+--------------+----------+
|  1 | BRANDON ASTIN DMD LLC                          | AK    | ANCHOR POINT |   113026 |
|  2 | ELIZABETH WATNEY                               | AK    | ANCHOR POINT |      724 |
|  3 | A HAND UP BEHAVIOR SERVICES                    | AK    | ANCHORAGE    |     1191 |
|  4 | ETHOS HEALTH MARYLAND 2                        | MD    | OWINGS MILLS |    26098 |
|  5 | SCOCCIA MEDICAL SERVICES PLLC                  | TX    | KERRVILLE    |      289 |
|  6 | A JOINT EFFORT PHYSICAL THERAPY                | AK    | ANCHORAGE    |    23361 |
|  7 | EYE 4 KIDS VISION CENTER                       | MD    | OWINGS MILLS |    18866 |
|  8 | AA PAIN CLINIC, INC.                           | AK    | ANCHORAGE    |    69976 |
|  9 | FALL PREVENTION STROKE REHAB LLC               | MD    | OWINGS MILLS |   128247 |
| 10 | FAMILY FOOTCARE AMBULATORY SURGERY CENTER, LLC | MD    | OWINGS MILLS |     4662 |
+----+------------------------------------------------+-------+--------------+----------+
10 rows in set (0.00 sec)

mysql> ALTER TABLE relief_fund RENAME COLUMN _payment payment;
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'payment' at line 1
mysql> ALTER TABLE relief_fund RENAME COLUMN _payment TO payment;
Query OK, 0 rows affected (0.01 sec)
Records: 0  Duplicates: 0  Warnings: 0
```

## Add an index and test speeds!

```sql
mysql> select count(id) from relief_fund where city = 'ANCHORAGE';
+-----------+
| count(id) |
+-----------+
|       466 |
+-----------+
1 row in set (0.14 sec)

mysql> CREATE INDEX on relief_fund(city);
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'on relief_fund(city)' at line 1
mysql> CREATE INDEX idx_on_city on relief_fund(city);
Query OK, 0 rows affected (1.23 sec)
Records: 0  Duplicates: 0  Warnings: 0

mysql> select count(id) from relief_fund where city = 'ANCHORAGE';
+-----------+
| count(id) |
+-----------+
|       466 |
+-----------+
1 row in set (0.00 sec)
```