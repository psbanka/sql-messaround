-- 01 Foreign keys

USE scratch;
DROP TABLE IF EXISTS widgetSale;
DROP TABLE IF EXISTS widgetCustomer;

CREATE TABLE widgetCustomer ( id INTEGER AUTO_INCREMENT PRIMARY KEY, name VARCHAR(64) );
CREATE TABLE widgetSale ( 
    id INTEGER AUTO_INCREMENT PRIMARY KEY, 
    item_id INT, 
    customer_id INT,
    quan INT,
    price INT,
    INDEX custid (customer_id),
    CONSTRAINT custid FOREIGN KEY custid(customer_id) REFERENCES widgetCustomer(id)
        ON UPDATE RESTRICT
        ON DELETE SET NULL
);

INSERT INTO widgetCustomer (name) VALUES ('Bob'), ('Sally'), ('Fred');
INSERT INTO widgetSale (item_id, customer_id, quan, price) VALUES (1, 3, 5, 1995), (2, 2, 3, 1495), (3, 1, 1, 2995);
SELECT * FROM widgetSale;
SELECT * FROM widgetCustomer;

UPDATE widgetCustomer SET id = 9 WHERE id = 2;



-- 02 Dropping and changing foreign keys

USE scratch;
SELECT * FROM widgetSale;
SELECT * FROM widgetCustomer;

ALTER TABLE widgetSale DROP FOREIGN KEY custid;
ALTER TABLE widgetSale ADD CONSTRAINT custid
  FOREIGN KEY (customer_id) REFERENCES widgetCustomer(id)
  ON UPDATE RESTRICT 
  ON DELETE SET NULL;

UPDATE widgetCustomer SET id = 2 WHERE id = 9;
UPDATE widgetCustomer SET id = 9 WHERE id = 2;

DROP TABLE IF EXISTS widgetCustomer;
DROP TABLE IF EXISTS widgetSale;

DROP TABLE IF EXISTS widgetSale;
DROP TABLE IF EXISTS widgetCustomer;

