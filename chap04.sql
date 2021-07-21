-- 02 Data integrity

USE scratch;
DROP TABLE IF EXISTS widgetInventory;
DROP TABLE IF EXISTS widgetSales;

CREATE TABLE widgetInventory (
  id INTEGER AUTO_INCREMENT PRIMARY KEY,
  description TEXT,
  onhand INTEGER NOT NULL
);

CREATE TABLE widgetSales (
  id INTEGER AUTO_INCREMENT PRIMARY KEY,
  inv_id INTEGER,
  quan INTEGER,
  price INTEGER
);

INSERT INTO widgetInventory ( description, onhand ) VALUES ( 'rock', 25 );
INSERT INTO widgetInventory ( description, onhand ) VALUES ( 'paper', 25 );
INSERT INTO widgetInventory ( description, onhand ) VALUES ( 'scissors', 25 );

SELECT * FROM widgetInventory;


START TRANSACTION;
INSERT INTO widgetSales ( inv_id, quan, price ) VALUES ( 1, 5, 500 );
UPDATE widgetInventory SET onhand = ( onhand - 5 ) WHERE id = 1;
COMMIT;

SELECT * FROM widgetInventory;
SELECT * FROM widgetSales;


START TRANSACTION;
INSERT INTO widgetInventory ( description, onhand ) VALUES ( 'toy', 25 );
ROLLBACK;
SELECT * FROM widgetInventory;

-- restore database
DROP TABLE widgetInventory;
DROP TABLE widgetSales;

-- 03 Performance 

USE scratch;
DROP TABLE IF EXISTS test;
DROP PROCEDURE IF EXISTS insert_loop;
CREATE TABLE test ( id INTEGER AUTO_INCREMENT PRIMARY KEY, data TEXT );

DELIMITER //
CREATE PROCEDURE insert_loop( IN count INT UNSIGNED )
BEGIN
    DECLARE accum INT UNSIGNED DEFAULT 0;
    DECLARE start_time VARCHAR(32);
    DECLARE end_time VARCHAR(32);
    SET start_time = SYSDATE(6);
    WHILE accum < count DO
        SET accum = accum + 1;
        INSERT INTO test ( data ) VALUES ( 'this is a good sized line of text.' );
    END WHILE;
    SET end_time = SYSDATE(6);
    SELECT TIME_FORMAT(start_time, '%T.%f') AS `Start`,
        TIME_FORMAT(end_time, '%T.%f') AS `End`,
        TIME_FORMAT(TIMEDIFF(end_time, start_time), '%s.%f') AS `Elapsed Secs`;
END //
DELIMITER ;

-- START TRANSACTION;
CALL insert_loop(10000);
-- START TRANSACTION;

SELECT * FROM test ORDER BY id DESC LIMIT 10;

DROP TABLE IF EXISTS test;
DROP PROCEDURE IF EXISTS insert_loop;

