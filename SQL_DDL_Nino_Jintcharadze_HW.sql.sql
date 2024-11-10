CREATE SCHEMA sushi_delivery_service;

CREATE TABLE Customer(
    customer_id SERIAL PRIMARY KEY NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL, 
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(50) NOT NULL UNIQUE,
    CONSTRAINT chk_email_format CHECK (email LIKE '%@%.%')
);

-- Creating the Sushi_item table with a check constraint for non-negative price
CREATE TABLE Sushi_item(
    sushi_item_id SERIAL PRIMARY KEY,
    sushi_name VARCHAR(70) NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK(price >= 0), -- Cannot be negative
    CONSTRAINT chk_sushi_name_non_empty CHECK (sushi_name <> '')
);

-- Creating the Order table with a default value for order_date and a check constraint for valid total_cost
CREATE TABLE "Order" (
    order_id SERIAL PRIMARY KEY,
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP CHECK (order_date > '2000-01-01'), -- Date must be after January 1, 2000
    total_cost DECIMAL(10, 2) NOT NULL CHECK (total_cost >= 0), -- Total cost cannot be negative
    customer_id INT REFERENCES Customer(customer_id) ON DELETE CASCADE -- Relationship with Customer table
);

-- Creating the Order_Item table with a check constraint to prevent negative quantity and price
CREATE TABLE Order_Item (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES "Order"(order_id) ON DELETE CASCADE,  -- Relationship with Order table
    sushi_item_id INT REFERENCES Sushi_Item(sushi_item_id) ON DELETE CASCADE,  -- Relationship with Sushi_item table
    quantity INT NOT NULL CHECK (quantity > 0),  -- Quantity must be positive
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0),  -- Unit price cannot be negative
    CONSTRAINT fk_sushi_item CHECK (sushi_item_id IS NOT NULL)
);

-- Creating the Delivery table with a default value for delivery_date
CREATE TABLE Delivery (
    delivery_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES "Order"(order_id) ON DELETE CASCADE,
    delivery_address VARCHAR(255) NOT NULL,
    delivery_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP CHECK (delivery_date > '2000-01-01') -- Date must be after January 1, 2000
);

-- Creating the Courier table
CREATE TABLE Courier (
    courier_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL,
	CONSTRAINT chk_phone_format CHECK (phone SIMILAR TO '\+995[5-9][0-9]{8}') -- Validating Georgian phone numbers
);

-- Creating the Payment table with a foreign key to the "Order" table
CREATE TABLE Payment (
    payment_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES "Order"(order_id) ON DELETE CASCADE,
    payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('Credit Card', 'PayPal', 'Cash')),
    payment_status VARCHAR(50) NOT NULL CHECK (payment_status IN ('Pending', 'Completed', 'Failed')) -- Restricting payment status
);

INSERT INTO Customer (first_name, last_name, phone, email) VALUES
('Nika', 'Berdzenishvili', '598-123-456', 'nika.berdzenishvili@example.com'),
('Salome', 'Jgenti', '599-234-567', 'salome.jgenti@example.com'),
('Giorgi', 'Kharadze', '597-345-678', 'giorgi.kharadze@example.com'),
('Tamari', 'Chikovani', '598-456-789', 'tamari.chikovani@example.com'),
('Luka', 'Tavdgiridze', '599-567-890', 'luka.tavdgiridze@example.com'),
('Mariam', 'Gugeshashvili', '597-678-901', 'mariam.gugeshashvili@example.com'),
('Zurab', 'Kiknadze', '598-789-012', 'zurab.kiknadze@example.com'),
('Elene', 'Javakhishvili', '599-890-123', 'elene.javakhishvili@example.com');


INSERT INTO Sushi_Item (sushi_name, price) VALUES
('Dragon Roll', 12.50),
('Philadelphia Roll', 10.00),
('Unagi Nigiri', 4.50),
('Sashimi Combo', 18.00),
('Tuna Tataki', 15.00),
('Vegetable Roll', 7.00);


INSERT INTO "Order" (order_date, total_cost, customer_id) VALUES
(CURRENT_TIMESTAMP, 45.00, 1),
(CURRENT_TIMESTAMP, 50.00, 2),
(CURRENT_TIMESTAMP, 35.00, 3),
(CURRENT_TIMESTAMP, 20.50, 4),
(CURRENT_TIMESTAMP, 60.75, 5),
(CURRENT_TIMESTAMP, 47.30, 6),
(CURRENT_TIMESTAMP, 33.20, 7),
(CURRENT_TIMESTAMP, 25.00, 8);

INSERT INTO Order_Item (order_id, sushi_item_id, quantity, unit_price) VALUES
(1, 1, 2, 7.00),   
(2, 2, 1, 12.50),  
(3, 3, 1, 10.00), 
(4, 4, 2, 4.50),   
(5, 5, 1, 18.00), 
(6, 6, 1, 15.00),  
(7, 1, 2, 7.00),   
(8, 2, 1, 12.50);  

INSERT INTO Delivery (order_id, delivery_address, delivery_date) VALUES
(1, '12 Rustaveli Ave, Tbilisi', CURRENT_TIMESTAMP),
(2, '33 Marjanishvili St, Tbilisi', CURRENT_TIMESTAMP),
(3, '45 Chavchavadze Ave, Tbilisi', CURRENT_TIMESTAMP),
(4, '19 Vake Park St, Tbilisi', CURRENT_TIMESTAMP);

INSERT INTO Courier (first_name, last_name, phone) VALUES
('Irakli', 'Mikadze', '+995593456789'),
('Natia', 'Javakhishvili', '+995594567890'),
('Nino', 'Tsereteli', '+995555123456');  

INSERT INTO Payment (order_id, payment_method, payment_status) VALUES
(1, 'Credit Card', 'Completed'),  
(2, 'Cash', 'Pending'),           
(3, 'Credit Card', 'Completed'),  
(4, 'PayPal', 'Completed');   


ALTER TABLE Customer
ADD COLUMN record_ts DATE NOT NULL DEFAULT current_date;
UPDATE Customer
SET record_ts = current_date;


ALTER TABLE Sushi_item
ADD COLUMN record_ts DATE NOT NULL DEFAULT current_date;
UPDATE Sushi_item
SET record_ts = current_date;


ALTER TABLE "Order"
ADD COLUMN record_ts DATE NOT NULL DEFAULT current_date;
UPDATE "Order"
SET record_ts = current_date;


ALTER TABLE Order_Item
ADD COLUMN record_ts DATE NOT NULL DEFAULT current_date;
UPDATE Order_Item
SET record_ts = current_date;


ALTER TABLE Delivery
ADD COLUMN record_ts DATE NOT NULL DEFAULT current_date;
UPDATE Delivery
SET record_ts = current_date;

ALTER TABLE Courier
ADD COLUMN record_ts DATE NOT NULL DEFAULT current_date;
UPDATE Courier
SET record_ts = current_date;


ALTER TABLE Payment
ADD COLUMN record_ts DATE NOT NULL DEFAULT current_date;
UPDATE Payment
SET record_ts = current_date;





