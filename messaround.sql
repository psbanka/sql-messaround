create temporary table if not exists t (
  a VARCHAR(18), b VARCHAR(18)
);
insert into t (a, b) values ("DE228", "US28281");
insert into t (a, b) values ("PA2974", "FR88711");
insert into t (a, b) values ("LA228", "NG88711");

-- select SubStr(a, 1, 2) as city, SubStr(b, 1, 2) as country from t;

select Name from country where code2 in (
  select SubStr(b, 1, 2) from t
);

-- select ss.CCode from (
--	select SubStr(b, 1, 2) as CCode from t
-- ) as ss;
