-- LOOK AT OUR BAD ASS SQL!
use album;

DROP VIEW trackTime;
CREATE view trackTime AS
  SELECT album_id, id AS track_id, title, duration DIV 60 as m, duration MOD 60 as s
    FROM track; -- DIV does INT()


SELECT t.title, CONCAT(tt.m, ":", LPAD(tt.s, 2, 0)) AS time
  FROM TRACK as t
  JOIN tracktime as tt
    ON t.id = tt.track_id
  ;