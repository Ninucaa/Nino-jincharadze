CREATE TABLE Customer (
    customer_id SERIAL PRIMARY KEY NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Sushi_Item (
    sushi_item_id SERIAL PRIMARY KEY,
    sushi_name VARCHAR(70) NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE "Order" (
    order_id SERIAL PRIMARY KEY,
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_cost DECIMAL(10, 2) NOT NULL,
    customer_id INT REFERENCES Customer(customer_id) ON DELETE CASCADE
);

CREATE TABLE Order_Item (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES "Order"(order_id) ON DELETE CASCADE,
    sushi_item_id INT REFERENCES Sushi_Item(sushi_item_id) ON DELETE CASCADE,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0)
);

CREATE TABLE Delivery (
    delivery_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES "Order"(order_id) ON DELETE CASCADE,
    delivery_address VARCHAR(255) NOT NULL,
    delivery_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Courier (
    courier_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL
);

CREATE TABLE Payment (
    payment_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES "Order"(order_id) ON DELETE CASCADE,
    payment_method VARCHAR(50) NOT NULL,
    payment_status VARCHAR(50) NOT NULL
);

CREATE TABLE Order_Status (
    status_id SERIAL PRIMARY KEY,
    status_name VARCHAR(50) NOT NULL
);

CREATE TABLE Order_Tracking (
    tracking_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES "Order"(order_id) ON DELETE CASCADE,
    status_id INT REFERENCES Order_Status(status_id),
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Customer_Feedback (
    feedback_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES "Order"(order_id) ON DELETE CASCADE,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    feedback_comments TEXT
);

INSERT INTO Customer_Feedback (order_id, rating, feedback_comments) VALUES
(1, 5, 'Delicious sushi! Will order again.'),
(2, 4, 'Great service, but delivery took longer than expected.');

INSERT INTO Order_Tracking (order_id, status_id) VALUES
(1, 1),  
(2, 2),  
(3, 3);  

INSERT INTO Order_Status (status_name) VALUES
('Pending'),
('Processing'),
('Completed'),
('Cancelled');

INSERT INTO Customer (first_name, last_name, phone, email) VALUES
('Nika', 'Berdzenishvili', '598-123-456', 'nika.berdzenishvili@example.com'),
('Salome', 'Jgenti', '599-234-567', 'salome.jgenti@example.com'),
('Giorgi', 'Kharadze', '597-345-678', 'giorgi.kharadze@example.com'),
('Tamari', 'Chikovani', '598-456-789', 'tamari.chikovani@example.com'),
('Luka', 'Tavdgiridze', '599-567-890', 'luka.tavdgiridze@example.com'),
('Mariam', 'Gugeshashvili', '597-678-901', 'mariam.gugeshashvili@example.com'),
('Zurab', 'Kiknadze', '598-789-012', 'zurab.kiknadze@example.com'),
('Elene', 'Javakhishvili', '599-890-123', 'elene.javakhishvili@example.com');

SELECT * FROM Customer

INSERT INTO Sushi_Item (sushi_name, price) VALUES
('Dragon Roll', 12.50),
('Philadelphia Roll', 10.00),
('Unagi Nigiri', 4.50),
('Sashimi Combo', 18.00),
('Tuna Tataki', 15.00),
('Vegetable Roll', 7.00);

SELECT * FROM Sushi_Item;

INSERT INTO "Order" (order_date, total_cost, customer_id) VALUES
(CURRENT_TIMESTAMP, 45.00, 1),
(CURRENT_TIMESTAMP, 50.00, 2),
(CURRENT_TIMESTAMP, 35.00, 3),
(CURRENT_TIMESTAMP, 20.50, 4),
(CURRENT_TIMESTAMP, 60.75, 5),
(CURRENT_TIMESTAMP, 47.30, 6),
(CURRENT_TIMESTAMP, 33.20, 7),
(CURRENT_TIMESTAMP, 25.00, 8);

SELECT * FROM "Order";

INSERT INTO Order_Item (order_id, sushi_item_id, quantity, unit_price) VALUES
(1, 1, 2, 7.00),   
(2, 2, 1, 12.50),  
(3, 3, 1, 10.00), 
(4, 4, 2, 4.50),   
(5, 5, 1, 18.00), 
(6, 6, 1, 15.00),  
(7, 1, 2, 7.00),   
(8, 2, 1, 12.50);  

SELECT * FROM Order_Item

INSERT INTO Delivery (order_id, delivery_address, delivery_date) VALUES
(1, '12 Rustaveli Ave, Tbilisi', CURRENT_TIMESTAMP),
(2, '33 Marjanishvili St, Tbilisi', CURRENT_TIMESTAMP),
(3, '45 Chavchavadze Ave, Tbilisi', CURRENT_TIMESTAMP),
(4, '19 Vake Park St, Tbilisi', CURRENT_TIMESTAMP);

SELECT * FROM Delivery;

INSERT INTO Courier (first_name, last_name, phone) VALUES
('Nino', 'Tsereteli', '555-1234'),
('Lasha', 'Chikviladze', '555-5678'),
('Irakli', 'Sharashenidze', '555-9101'),
('Ketevan', 'Kvachadze', '555-1213');

SELECT * FROM Courier;

INSERT INTO Payment (order_id, payment_method, payment_status) VALUES
(1, 'Credit Card', 'Completed'),  
(2, 'Cash', 'Pending'),           
(3, 'Credit Card', 'Completed'),  
(4, 'PayPal', 'Completed');       

SELECT * FROM Payment;




