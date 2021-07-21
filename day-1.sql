create temporary table if not exists t (
  a VARCHAR(18), b VARCHAR(18)
);
insert into t (a, b) values ("NY0123", "US28281");
insert into t (a, b) values ("AZ9437", "FR88711");
insert into t (a, b) values ("CA1279", "NG88711");

-- select SubStr(a, 1, 2) as city, SubStr(b, 1, 2) as country from t;

-- NOTE: this works, but only one column of data returned in sub-query
-- select Name from country where code2 in (
--   select SubStr(b, 1, 2) from t
-- );

SELECT ss.State, ss.SCode, c.Name, c.Region FROM (
   SELECT SUBSTR(a, 1, 2) as State,
          SUBSTR(a, 3) as SCode, 
          SUBSTR(b, 1, 2) as Country,
          SUBSTR(b, 3) as CCode from t
) as ss
JOIN country AS c
  ON c.code2 = ss.Country;

-- NOTE: does not work:
-- select Name, Region from country where code2 in (
--    SELECT SUBSTR(a, 1, 2) as State,
--           SUBSTR(a, 3) as SCode, 
--           SUBSTR(b, 1, 2) as Country,
--           SUBSTR(b, 3) as CCode from t
-- );
