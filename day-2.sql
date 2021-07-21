use album;

-- TODO: You have a database with two tables: one has album information (artist, title, etc.) and one has track information (e.g. length of song, title of song). You would like to know the name of any album which has at least one track that is < 90s long.

-- row is going to have album_title, the track_title, and track_duration


-- SELECT * from track where duration < 90;


-- SELECT track.title, track.duration, album.title as name
-- FROM track
-- INNER JOIN album ON track.album_id=album.id
-- WHERE track.duration < 90;

-- TODO: Show me ALL the tracks on ANY album for which there is at least one song of duration < 90s.


SELECT * FROM track
LEFT JOIN album ON track.album_id = album.id
WHERE track.duration < 90
UNION
SELECT * FROM track
RIGHT JOIN album ON track.album_id = album.id
WHERE track.duration < 90;

