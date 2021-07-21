-- 02 Creating a stored function

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

SELECT title, duration AS secs, track_len(duration) AS len
  FROM track ORDER BY duration DESC;

SELECT a.artist AS artist,
    a.title AS album,
    t.title AS track,
    t.track_number AS trackno,
    track_len(t.duration) AS length
  FROM track AS t
  JOIN album AS a
    ON a.id = t.album_id
  ORDER BY artist, album, trackno
;

SELECT a.artist AS artist,
    a.title AS album,
    track_len(SUM(duration)) AS length
  FROM track AS t
  JOIN album AS a
    ON a.id = t.album_id
  GROUP BY a.id
  ORDER BY artist, album
;

SHOW FUNCTION STATUS WHERE DEFINER LIKE 'admin%';

-- to drop function: DROP FUNCTION IF EXISTS track_len;

-- 03 Creating a stored procedure

USE album;

-- simple procedure
DROP PROCEDURE IF EXISTS list_albums;
DELIMITER //
CREATE PROCEDURE list_albums ()
BEGIN
    SELECT * FROM album;
    SELECT * FROM track;
END //
DELIMITER ;

CALL list_albums();


DROP PROCEDURE IF EXISTS list_albums;
DELIMITER //
CREATE PROCEDURE list_albums (param VARCHAR(255))
  BEGIN
    SELECT a.artist AS artist,
        a.title AS album,
        t.title AS track,
        t.track_number AS trackno,
        track_len(t.duration) AS length
      FROM track AS t
      JOIN album AS a
        ON a.id = t.album_id
      WHERE a.artist LIKE param
      ORDER BY artist, album, trackno
    ;
  END //
DELIMITER ;

CALL list_albums('%hendrix%');

-- with output parameter
DROP PROCEDURE IF EXISTS total_duration;

DELIMITER //
CREATE PROCEDURE total_duration (param VARCHAR(255), OUT outp VARCHAR(255))
  BEGIN
    SELECT track_len(SUM(duration)) INTO outp
      FROM track
      WHERE album_id IN (SELECT id FROM album WHERE artist LIKE param)
    ;
  END //
DELIMITER ;

CALL total_duration('%hendrix%', @dur);
SELECT @dur;

SHOW FUNCTION STATUS WHERE DEFINER LIKE 'admin%';
SHOW PROCEDURE STATUS WHERE DEFINER LIKE 'admin%';

DROP FUNCTION IF EXISTS track_len;
DROP PROCEDURE IF EXISTS total_duration;

-- 04 Loops in stored procedures

USE scratch;
DROP PROCEDURE IF EXISTS str_count;

-- STR_COUNT()
-- count 1 to 5
-- concatenate in string

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

