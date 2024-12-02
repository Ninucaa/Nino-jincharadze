-- Create the Sales History Schema
CREATE SCHEMA SalesHistory;

-- Create the countries table
CREATE TABLE SalesHistory.countries (
    id SERIAL PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL
);
INSERT INTO SalesHistory.countries (country_name)
VALUES
('USA'), ('Canada'), ('Germany'), ('France'), ('UK'), ('Australia');

-- Create the customers table
CREATE TABLE SalesHistory.customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL
);
INSERT INTO SalesHistory.customers (name, region)
VALUES
('Alice', 'North America'),
('Bob', 'Europe'),
('Charlie', 'Europe'),
('David', 'Australia'),
('Eve', 'North America'),
('Frank', 'Australia');

-- Create the channels table
CREATE TABLE SalesHistory.channels (
    id SERIAL PRIMARY KEY,
    channel_name VARCHAR(100) NOT NULL
);
INSERT INTO SalesHistory.channels (channel_name)
VALUES
('Online'), ('Retail'), ('Wholesale');

-- Create the times table
CREATE TABLE SalesHistory.times (
    id SERIAL PRIMARY KEY,
    year INT NOT NULL,
    month INT NOT NULL,
    day INT NOT NULL
);
-- Insert data into TIMES (Dates for 2023)
INSERT INTO SalesHistory.times (year, month, day)
VALUES
(2024, 3, 10),
(2024, 5, 15),
(2024, 8, 20),
(2024, 9, 25),
(2024, 10, 30),
(2024, 11, 5);


-- Create the products table
CREATE TABLE SalesHistory.products (
    id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    product_category VARCHAR(50) NOT NULL,
    price DECIMAL(10, 2) NOT NULL 
);
INSERT INTO SalesHistory.products (product_name, product_category, price)
VALUES
('Laptop', 'Electronics', 1200.00),
('Phone', 'Electronics', 800.00),
('Tablet', 'Electronics', 400.00),
('Shoes', 'Apparel', 50.00),
('Jacket', 'Apparel', 100.00),
('Socks', 'Apparel', 10.00);

ALTER TABLE SalesHistory.products
ADD COLUMN price DECIMAL(10, 2);

-- Create the promotions table
CREATE TABLE SalesHistory.promotions (
    id SERIAL PRIMARY KEY,
    promotion_name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
);
INSERT INTO SalesHistory.promotions (promotion_name, start_date, end_date)
VALUES
('Summer Sale', '2024-06-01', '2024-06-30'),
('Black Friday', '2024-11-01', '2024-11-30'),
('Winter Sale', '2024-12-01', '2024-12-31');

-- Create the costs table
CREATE TABLE SalesHistory.costs (
    id SERIAL PRIMARY KEY,
    product_id INT REFERENCES SalesHistory.products(id),
    cost DECIMAL(10, 2) NOT NULL
);
INSERT INTO SalesHistory.costs (product_id, cost)
SELECT p.id,
       CASE
           WHEN p.product_category = 'Electronics' THEN 500.00
           WHEN p.product_category = 'Apparel' THEN 50.00
           ELSE 100.00
       END AS cost
FROM SalesHistory.products p;


-- Create the sales table 
CREATE TABLE SalesHistory.sales (
    id SERIAL PRIMARY KEY,
    product_id INT REFERENCES SalesHistory.products(id),
    customer_id INT REFERENCES SalesHistory.customers(id),
    channel_id INT REFERENCES SalesHistory.channels(id),
    time_id INT REFERENCES SalesHistory.times(id),
    sales_amount DECIMAL(10, 2) NOT NULL,
    sales_quantity INT NOT NULL
);

--Task3
--3.1 Retrieve the total sales amount for each product category for a specific time period.
INSERT INTO SalesHistory.sales (product_id, customer_id, channel_id, time_id, sales_amount, sales_quantity)
SELECT 
    p.id AS product_id,
    c.id AS customer_id,
    ch.id AS channel_id,
    t.id AS time_id,
    (p.price * COALESCE(s.sales_quantity, 1)) AS sales_amount, 
    COALESCE(s.sales_quantity, 1) AS sales_quantity 
FROM SalesHistory.products p
JOIN SalesHistory.customers c ON c.id IS NOT NULL  
JOIN SalesHistory.channels ch ON ch.id IS NOT NULL 
JOIN SalesHistory.times t ON t.id IS NOT NULL  
LEFT JOIN SalesHistory.sales s ON s.product_id = p.id  
WHERE s.sales_quantity > 0 OR s.sales_quantity IS NULL;  

--3.2Calculate the average sales quantity by region for a particular product.
SELECT 
    c.region,  
    AVG(s.sales_quantity) AS avg_sales_quantity
FROM 
    SalesHistory.sales s
JOIN 
    SalesHistory.customers c ON s.customer_id = c.id 
WHERE 
    s.product_id = 1  
GROUP BY 
    c.region
ORDER BY 
    avg_sales_quantity DESC;  


--3.3 Find the top five customers with the highest total sales amount
SELECT 
    c.id AS customer_id,  
    c.name AS customer_name,    
    SUM(s.sales_amount) AS total_sales_amount
FROM 
    SalesHistory.sales s
JOIN 
    SalesHistory.customers c ON s.customer_id = c.id  
GROUP BY 
    c.id, c.name 
ORDER BY 
    total_sales_amount DESC
LIMIT 5; 