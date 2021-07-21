-- 01 update triggers

USE scratch;
DROP TABLE IF EXISTS widgetCustomer;
DROP TABLE IF EXISTS widgetSale;

CREATE TABLE widgetCustomer ( id INTEGER AUTO_INCREMENT PRIMARY KEY, name VARCHAR(64), last_order_id INT );
CREATE TABLE widgetSale ( id INTEGER AUTO_INCREMENT PRIMARY KEY, item_id INT, customer_id INT, quan INT, price INT );

INSERT INTO widgetCustomer (name) VALUES ('Bob');
INSERT INTO widgetCustomer (name) VALUES ('Sally');
INSERT INTO widgetCustomer (name) VALUES ('Fred');

SELECT * FROM widgetCustomer;

DROP TRIGGER IF EXISTS newWidgetSale;
DELIMITER //
CREATE TRIGGER newWidgetSale AFTER INSERT ON widgetSale 
    FOR EACH ROW
    BEGIN
         UPDATE widgetCustomer SET last_order_id = NEW.id WHERE widgetCustomer.id = NEW.customer_id;
    END //
DELIMITER ;


INSERT INTO widgetSale (item_id, customer_id, quan, price) VALUES (1, 3, 5, 1995);
INSERT INTO widgetSale (item_id, customer_id, quan, price) VALUES (2, 2, 3, 1495);
INSERT INTO widgetSale (item_id, customer_id, quan, price) VALUES (3, 1, 1, 2995);
SELECT * FROM widgetSale;
SELECT * FROM widgetCustomer;

DROP TRIGGER IF EXISTS newWidgetSale;
DROP TABLE IF EXISTS widgetCustomer;
DROP TABLE IF EXISTS widgetSale;


-- 02 preventing updates
-- test.db

USE scratch;
DROP TABLE IF EXISTS widgetCustomer;
DROP TABLE IF EXISTS widgetSale;

CREATE TABLE widgetCustomer ( id INTEGER AUTO_INCREMENT PRIMARY KEY, name VARCHAR(64), last_order_id INT );
CREATE TABLE widgetSale ( id INTEGER AUTO_INCREMENT PRIMARY KEY, item_id INT, customer_id INTEGER, quan INT, price INT,
    reconciled INT );
INSERT INTO widgetSale (item_id, customer_id, quan, price, reconciled) VALUES (1, 3, 5, 1995, 0);
INSERT INTO widgetSale (item_id, customer_id, quan, price, reconciled) VALUES (2, 2, 3, 1495, 1);
INSERT INTO widgetSale (item_id, customer_id, quan, price, reconciled) VALUES (3, 1, 1, 2995, 0);
SELECT * FROM widgetSale;

DROP TRIGGER IF EXISTS updateWidgetSale;
DELIMITER //
CREATE TRIGGER updateWidgetSale BEFORE UPDATE ON widgetSale
    FOR EACH ROW
    BEGIN
        IF OLD.id = NEW.id AND OLD.reconciled = 1 THEN
            SIGNAL SQLSTATE '45000' set message_text = 'cannot update reconciled row: "widgetSale"';
        END IF;
    END //
DELIMITER ;

UPDATE widgetSale SET quan = 9 WHERE id = 1;
UPDATE widgetSale SET quan = 9 WHERE id = 2;

SELECT * FROM widgetSale;

DROP TABLE IF EXISTS widgetCustomer;
DROP TABLE IF EXISTS widgetSale;

-- 03 timestamps
-- test.db

USE scratch;
DROP TABLE IF EXISTS widgetSale;
DROP TABLE IF EXISTS widgetCustomer;
DROP TABLE IF EXISTS widgetLog;

CREATE TABLE widgetCustomer ( id INTEGER AUTO_INCREMENT PRIMARY KEY, name VARCHAR(64), last_order_id INT, stamp VARCHAR(24) );
CREATE TABLE widgetSale ( id INTEGER AUTO_INCREMENT PRIMARY KEY, item_id INT, customer_id INTEGER, quan INT, price INT, stamp VARCHAR(24) );
CREATE TABLE widgetLog ( id INTEGER AUTO_INCREMENT PRIMARY KEY, stamp VARCHAR(24), event VARCHAR(64), username VARCHAR(64), tablename VARCHAR(64), table_id INT);

INSERT INTO widgetCustomer (name) VALUES ('Bob');
INSERT INTO widgetCustomer (name) VALUES ('Sally');
INSERT INTO widgetCustomer (name) VALUES ('Fred');
SELECT * FROM widgetCustomer;

DROP TRIGGER IF EXISTS stampSale;
DROP TRIGGER IF EXISTS newWidgetSale;
DELIMITER //
CREATE TRIGGER stampSale BEFORE INSERT ON widgetSale
    FOR EACH ROW
    BEGIN
        DECLARE nowstamp VARCHAR(24) DEFAULT NOW();
        SET NEW.stamp = nowstamp;
    END //

CREATE TRIGGER newWidgetSale AFTER INSERT ON widgetSale 
    FOR EACH ROW
    BEGIN
        DECLARE nowstamp VARCHAR(24) DEFAULT NOW();
        INSERT INTO widgetLog (stamp, event, username, tablename, table_id)
            VALUES (nowstamp, 'INSERT', USER(), 'widgetSale', NEW.id);
        UPDATE widgetCustomer SET last_order_id = NEW.id, stamp = nowstamp
             WHERE widgetCustomer.id = NEW.customer_id;
        
    END //
DELIMITER ;

INSERT INTO widgetSale (item_id, customer_id, quan, price) VALUES (1, 3, 5, 1995);
INSERT INTO widgetSale (item_id, customer_id, quan, price) VALUES (2, 2, 3, 1495);
INSERT INTO widgetSale (item_id, customer_id, quan, price) VALUES (3, 1, 1, 2995);

SELECT * FROM widgetSale;
SELECT * FROM widgetCustomer;
SELECT * FROM widgetLog;

-- restore database
DROP TABLE IF EXISTS widgetCustomer;
DROP TABLE IF EXISTS widgetSale;
DROP TABLE IF EXISTS widgetLog;

