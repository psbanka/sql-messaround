We are basing this off of [a specific linked-in learning tutorial](https://www.linkedin.com/learning/advanced-sql-for-query-tuning-and-performance-optimization/reduce-query-reponse-time-with-query-tuning?u=83558730).


## General setup notes

1. install mysql on your macbook with `brew install mysql`

2. set up your user password (fill in details here because I forgot)

3. run your mysql daemon with `mysqld` in a terminal tab you don't want to use. Note you can't ctrl-c that thing. You need to just close the tab or `kill` the thing.

## Day 1: Messing with sub-queries and temp-tables

Branch: `day-1`

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


