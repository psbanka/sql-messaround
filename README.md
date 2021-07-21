We are basing this off of [a specific linked-in learning tutorial](https://www.linkedin.com/learning/advanced-sql-for-query-tuning-and-performance-optimization/reduce-query-reponse-time-with-query-tuning?u=83558730).


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
          SUBSTR(b, 3) as CCode from t
) as ss
JOIN country AS c
  ON c.code2 = ss.Country;
```

We added a join

### Questions

1. What is the purpose of a sub-select

Pulling out a smaller portion of data to then reference in a larger select statement. Pulling a couple of different tables together to pull it into its own table to query against. 

The internet says: A subquery is used to return data that will be used in the main query as a condition to further restrict the data to be retrieved.


from the tutorial: "sub-selects are a convenient way of making your data available in different forms while keeping your database schema simple and well-organized"

2. When is a subselect particularly useful

What about our certificates table with a couple million rows? Maybe you could limit that?


3. How does a sub-select optimize a query?

Cool, I can limit the certificates, why is that different than chaining?



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





