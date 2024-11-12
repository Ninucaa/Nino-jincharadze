CREATE SCHEMA sushi_delivery_service;

CREATE TABLE sushi_delivery_service.customer (
    customer_id SERIAL PRIMARY KEY NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL, 
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(50) NOT NULL UNIQUE,
    CONSTRAINT chk_email_format CHECK (email LIKE '%@%.%')
);

-- Creating the Sushi_item table with a check constraint for non-negative price
CREATE TABLE sushi_delivery_service.sushi_item (
    sushi_item_id SERIAL PRIMARY KEY,
    sushi_name VARCHAR(70) NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK(price >= 0), -- Cannot be negative
    CONSTRAINT chk_sushi_name_non_empty CHECK (sushi_name <> '')
);

-- Creating the Order table with a default value for order_date and a check constraint for valid total_cost
CREATE TABLE sushi_delivery_service."order" (
    order_id SERIAL PRIMARY KEY,
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP CHECK (order_date > '2000-01-01'), -- Date must be after January 1, 2000
    total_cost DECIMAL(10, 2) NOT NULL CHECK (total_cost >= 0), -- Total cost cannot be negative
    customer_id INT REFERENCES sushi_delivery_service.Customer(customer_id) ON DELETE CASCADE -- Relationship with Customer table
);

-- Creating the Order_Item table with a check constraint to prevent negative quantity and price
CREATE TABLE sushi_delivery_service.order_item (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES sushi_delivery_service."Order"(order_id) ON DELETE CASCADE,  -- Relationship with Order table
    sushi_item_id INT REFERENCES sushi_delivery_service.Sushi_Item(sushi_item_id) ON DELETE CASCADE,  -- Relationship with Sushi_item table
    quantity INT NOT NULL CHECK (quantity > 0),  -- Quantity must be positive
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0),  -- Unit price cannot be negative
    CONSTRAINT fk_sushi_item CHECK (sushi_item_id IS NOT NULL)
);

-- Creating the Delivery table with a default value for delivery_date
CREATE TABLE sushi_delivery_service.delivery (
    delivery_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES sushi_delivery_service."Order"(order_id) ON DELETE CASCADE,
    delivery_address VARCHAR(255) NOT NULL,
    delivery_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP CHECK (delivery_date > '2000-01-01') -- Date must be after January 1, 2000
);

-- Creating the Courier table
CREATE TABLE sushi_delivery_service.courier (
    courier_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL,
	CONSTRAINT chk_phone_format CHECK (phone SIMILAR TO '\+995[5-9][0-9]{8}') -- Validating Georgian phone numbers
);

-- Creating the Payment table with a foreign key to the "Order" table
CREATE TABLE sushi_delivery_service.payment (
    payment_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES sushi_delivery_service."Order"(order_id) ON DELETE CASCADE,
    payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('Credit Card', 'PayPal', 'Cash')),
    payment_status VARCHAR(50) NOT NULL CHECK (payment_status IN ('Pending', 'Completed', 'Failed')) -- Restricting payment status
);

INSERT INTO sushi_delivery_service.customer (first_name, last_name, phone, email) VALUES
('Nika', 'Berdzenishvili', '598-123-456', 'nika.berdzenishvili@example.com'),
('Salome', 'Jgenti', '599-234-567', 'salome.jgenti@example.com'),
('Giorgi', 'Kharadze', '597-345-678', 'giorgi.kharadze@example.com'),
('Tamari', 'Chikovani', '598-456-789', 'tamari.chikovani@example.com'),
('Luka', 'Tavdgiridze', '599-567-890', 'luka.tavdgiridze@example.com'),
('Mariam', 'Gugeshashvili', '597-678-901', 'mariam.gugeshashvili@example.com'),
('Zurab', 'Kiknadze', '598-789-012', 'zurab.kiknadze@example.com'),
('Elene', 'Javakhishvili', '599-890-123', 'elene.javakhishvili@example.com');

INSERT INTO sushi_delivery_service.sushi_Item (sushi_name, price) VALUES
('Dragon Roll', 12.50),
('Philadelphia Roll', 10.00),
('Unagi Nigiri', 4.50),
('Sashimi Combo', 18.00),
('Tuna Tataki', 15.00),
('Vegetable Roll', 7.00);

INSERT INTO sushi_delivery_service."order" (order_date, total_cost, customer_id) VALUES
(CURRENT_TIMESTAMP, 45.00, (SELECT customer_id FROM sushi_delivery_service.Customer WHERE email = 'nika.berdzenishvili@example.com')),
(CURRENT_TIMESTAMP, 50.00, (SELECT customer_id FROM sushi_delivery_service.Customer WHERE email = 'salome.jgenti@example.com')),
(CURRENT_TIMESTAMP, 35.00, (SELECT customer_id FROM sushi_delivery_service.Customer WHERE email = 'giorgi.kharadze@example.com')),
(CURRENT_TIMESTAMP, 20.50, (SELECT customer_id FROM sushi_delivery_service.Customer WHERE email = 'tamari.chikovani@example.com')),
(CURRENT_TIMESTAMP, 60.75, (SELECT customer_id FROM sushi_delivery_service.Customer WHERE email = 'luka.tavdgiridze@example.com')),
(CURRENT_TIMESTAMP, 47.30, (SELECT customer_id FROM sushi_delivery_service.Customer WHERE email = 'mariam.gugeshashvili@example.com')),
(CURRENT_TIMESTAMP, 33.20, (SELECT customer_id FROM sushi_delivery_service.Customer WHERE email = 'zurab.kiknadze@example.com')),
(CURRENT_TIMESTAMP, 25.00, (SELECT customer_id FROM sushi_delivery_service.Customer WHERE email = 'elene.javakhishvili@example.com'));

INSERT INTO sushi_delivery_service.order_Item (order_id, sushi_item_id, quantity, unit_price) VALUES
((SELECT order_id FROM sushi_delivery_service."Order" WHERE total_cost = 45.00), (SELECT sushi_item_id FROM sushi_delivery_service.Sushi_Item WHERE sushi_name = 'Dragon Roll'), 2, 7.00),
((SELECT order_id FROM sushi_delivery_service."Order" WHERE total_cost = 50.00), (SELECT sushi_item_id FROM sushi_delivery_service.Sushi_Item WHERE sushi_name = 'Philadelphia Roll'), 1, 12.50),
((SELECT order_id FROM sushi_delivery_service."Order" WHERE total_cost = 35.00), (SELECT sushi_item_id FROM sushi_delivery_service.Sushi_Item WHERE sushi_name = 'Unagi Nigiri'), 1, 10.00),
((SELECT order_id FROM sushi_delivery_service."Order" WHERE total_cost = 20.50), (SELECT sushi_item_id FROM sushi_delivery_service.Sushi_Item WHERE sushi_name = 'Sashimi Combo'), 2, 4.50);

INSERT INTO sushi_delivery_service.delivery (order_id, delivery_address, delivery_date) VALUES
((SELECT order_id FROM sushi_delivery_service."Order" WHERE total_cost = 45.00), '12 Rustaveli Ave, Tbilisi', CURRENT_TIMESTAMP),
((SELECT order_id FROM sushi_delivery_service."Order" WHERE total_cost = 50.00), '33 Marjanishvili St, Tbilisi', CURRENT_TIMESTAMP),
((SELECT order_id FROM sushi_delivery_service."Order" WHERE total_cost = 35.00), '45 Chavchavadze Ave, Tbilisi', CURRENT_TIMESTAMP),
((SELECT order_id FROM sushi_delivery_service."Order" WHERE total_cost = 20.50), '19 Vake Park St, Tbilisi', CURRENT_TIMESTAMP);

INSERT INTO sushi_delivery_service.courier (first_name, last_name, phone) VALUES
('Irakli', 'Mikadze', '+995593456789'),
('Natia', 'Javakhishvili', '+995594567890'),
('Nino', 'Tsereteli', '+995555123456');

INSERT INTO sushi_delivery_service.payment (order_id, payment_method, payment_status) VALUES
((SELECT order_id FROM sushi_delivery_service."Order" WHERE total_cost = 45.00), 'Credit Card', 'Completed'),
((SELECT order_id FROM sushi_delivery_service."Order" WHERE total_cost = 50.00), 'Cash', 'Pending'),
((SELECT order_id FROM sushi_delivery_service."Order" WHERE total_cost = 35.00), 'Credit Card', 'Completed'),
((SELECT order_id FROM sushi_delivery_service."Order" WHERE total_cost = 20.50), 'PayPal', 'Completed');

-- Adding timestamps for all tables
ALTER TABLE sushi_delivery_service.customer
    ADD COLUMN record_ts DATE NOT NULL DEFAULT current_date;
UPDATE sushi_delivery_service.Customer
    SET record_ts = current_date;

ALTER TABLE sushi_delivery_service.sushi_item
    ADD COLUMN record_ts DATE NOT NULL DEFAULT current_date;
UPDATE sushi_delivery_service.Sushi_item
    SET record_ts = current_date;

ALTER TABLE sushi_delivery_service."order"
    ADD COLUMN record_ts DATE NOT NULL DEFAULT current_date;
UPDATE sushi_delivery_service."Order"
    SET record_ts = current_date;

ALTER TABLE sushi_delivery_service.order_item
    ADD COLUMN record_ts DATE NOT NULL DEFAULT current_date;
UPDATE sushi_delivery_service.Order_Item
    SET record_ts = current_date;

ALTER TABLE sushi_delivery_service.delivery
    ADD COLUMN record_ts DATE NOT NULL DEFAULT current_date;
UPDATE sushi_delivery_service.Delivery
    SET record_ts = current_date;

ALTER TABLE sushi_delivery_service.courier
    ADD COLUMN record_ts DATE NOT NULL DEFAULT current_date;
UPDATE sushi_delivery_service.Courier
    SET record_ts = current_date;

ALTER TABLE sushi_delivery_service.payment
    ADD COLUMN record_ts DATE NOT NULL DEFAULT current_date;
UPDATE sushi_delivery_service.Payment
    SET record_ts = current_date;
