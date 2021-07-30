use album;

-- TODO: You have a database with two tables: one has album information (artist, title, etc.) and one has track information (e.g. length of song, title of song). You would like to know the name of any album which has at least one track that is < 90s long.

-- row is going to have album_title, the track_title, and track_duration


-- SELECT * from track where duration < 90;


-- SELECT track.title, track.duration, album.title as name
-- FROM track
-- INNER JOIN album ON track.album_id=album.id
-- WHERE track.duration < 90;

-- TODO: Show me ALL the tracks on ANY album for which there is at least one song of duration < 90s.


-- SELECT * FROM track
-- LEFT JOIN album ON track.album_id = album.id
-- WHERE track.duration < 90
-- UNION
-- SELECT * FROM track
-- RIGHT JOIN album ON track.album_id = album.id
-- WHERE track.duration < 90;

-- VERSION 1:
SELECT a.title as album, a.artist, t.track_number as seq, t.title AS track_title, t.duration as secs
  FROM track AS t 
  JOIN album AS a
    ON t.album_id = a.id
    WHERE a.id IN (
      SELECT DISTINCT album_id from track WHERE duration < 90
    )
  ORDER BY a.title
;

-- VERSION 2:, just the tracks that are short
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