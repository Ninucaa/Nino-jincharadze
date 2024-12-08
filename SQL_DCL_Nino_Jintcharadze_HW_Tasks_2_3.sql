-- Task 1.
SELECT * FROM pg_roles;

--Task 2. Implement role-based authentication model for dvd_rental database
--1. Create a new user with the username "rentaluser" and the password "rentalpassword". 
--Give the user the ability to connect to the database but no other permissions.

CREATE USER rentaluser WITH PASSWORD 'rentalpassword';

-- Grant the ability to connect to the dvdrental database
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

-- Revoke all other permissions (ensure the user starts with no extra privileges)
REVOKE ALL ON SCHEMA public FROM rentaluser; -- Revoke schema-level permissions
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM rentaluser; -- Revoke table-level permissions
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM rentaluser; -- Revoke sequence-level permissions
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM rentaluser; -- Revoke function-level permissions


--2.Grant "rentaluser" SELECT permission for the "customer" table. 
--Сheck to make sure this permission works correctly—write a SQL query to select all customers.
GRANT SELECT ON TABLE customer TO rentaluser;

SELECT * FROM customer;

--3.Create a new user group called "rental" and add "rentaluser" to the group. 
CREATE ROLE rental;
GRANT rental TO rentaluser;

-- Grant SELECT on "customer" to the "rental" group role
GRANT SELECT ON TABLE customer TO rental;


--4.Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. 
--Insert a new row and update one existing row in the "rental" table under that role. 

GRANT INSERT, UPDATE ON TABLE public.rental TO rental;

-- Insert into rental table with the next rental_id
INSERT INTO rental (rental_id, rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT 
    (SELECT MAX(rental_id) + 1 FROM rental),  -- Calculate next rental_id
    CURRENT_DATE,  -- rental_date as today's date
    (
        SELECT i.inventory_id 
        FROM inventory i 
        INNER JOIN store s ON s.store_id = i.store_id 
        INNER JOIN film f ON f.film_id = i.film_id
        WHERE s.store_id = 1 
        LIMIT 1  
    ),
    (
        SELECT customer_id 
        FROM customer
        WHERE first_name = 'CHRISTINA' AND last_name = 'RAMIREZ'
        LIMIT 1 
    ),
    CURRENT_DATE + INTERVAL '7 days',  -- return_date (7 days from today)
    (
        SELECT staff_id 
        FROM staff
        WHERE first_name = 'Hanna' AND last_name = 'Carry'
        LIMIT 1  
    ),
    CURRENT_TIMESTAMP  -- last_update (current timestamp)
WHERE NOT EXISTS (
    SELECT 1
    FROM rental
    WHERE rental_date = CURRENT_DATE
    AND inventory_id = (SELECT i.inventory_id 
                         FROM inventory i 
                         INNER JOIN store s ON s.store_id = i.store_id 
                         INNER JOIN film f ON f.film_id = i.film_id
                         WHERE s.store_id = 1 
                         LIMIT 1)
    AND customer_id = (SELECT customer_id 
                       FROM customer
                       WHERE first_name = 'CHRISTINA' AND last_name = 'RAMIREZ'
                       LIMIT 1)
);
-- Update an existing row in the rental table
UPDATE rental
SET 
    return_date = CURRENT_DATE + INTERVAL '14 days',  -- Update return_date
    last_update = CURRENT_TIMESTAMP  -- Update last_update
WHERE rental_id = 1;  -- Specify the rental_id of the row to update

--5.Revoke the "rental" group's INSERT permission for the "rental" table. 
--Try to insert new rows into the "rental" table make sure this action is denied.
REVOKE INSERT ON rental FROM rental;

INSERT INTO rental (rental_id, rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT 
    (SELECT MAX(rental_id) + 1 FROM rental), 
    CURRENT_DATE,  
    i.inventory_id,  
    c.customer_id, 
    CURRENT_DATE + INTERVAL '7 days', 
    stf.staff_id, 
    CURRENT_TIMESTAMP  
FROM inventory i
JOIN store st ON st.store_id = i.store_id 
JOIN film f ON f.film_id = i.film_id  
JOIN customer c ON c.first_name = 'CHRISTINA' AND c.last_name = 'RAMIREZ' 
JOIN staff stf ON stf.first_name = 'Hanna' AND stf.last_name = 'Carry' 
    SELECT 1 
    FROM rental r
    WHERE r.rental_date = CURRENT_DATE
      AND r.inventory_id = i.inventory_id
      AND r.customer_id = c.customer_id
)
LIMIT 1;


--6. Create a personalized role for any customer already existing in the dvd_rental database. 
--The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). 
--The customer's payment and rental history must not be empty. 

-- Check if customer has rental and payment history
SELECT 
    c.first_name,
    c.last_name,
    COUNT(r.rental_id) AS rental_count,
    COUNT(p.payment_id) AS payment_count
FROM 
    customer c
LEFT JOIN 
    rental r ON c.customer_id = r.customer_id
LEFT JOIN 
    payment p ON c.customer_id = p.customer_id
WHERE 
    c.first_name = 'SANDRA'  
    AND c.last_name = 'MARTIN'  
GROUP BY 
    c.first_name, c.last_name;


-- Create a personalized role for Sandra Martin
DO $$
DECLARE
    customer_first_name TEXT := 'SANDRA';  
    customer_last_name TEXT := 'MARTIN';   
    role_name TEXT;
    customer_id_variable INT;  -- Renamed variable to avoid conflict
BEGIN
    -- Construct the role name based on the first and last name
    role_name := 'client_' || LOWER(customer_first_name) || '_' || LOWER(customer_last_name);

    -- Check if the customer exists and get the customer_id
    SELECT customer_id INTO customer_id_variable  -- Using renamed variable
    FROM customer
    WHERE first_name = customer_first_name AND last_name = customer_last_name
    LIMIT 1;

    -- If customer exists, create the role
    IF customer_id_variable IS NOT NULL THEN
        -- Create the role
        EXECUTE 'CREATE ROLE ' || role_name || ' NOINHERIT';

        -- Grant SELECT permission on rental and payment tables
        EXECUTE 'GRANT SELECT ON rental TO ' || role_name;
        EXECUTE 'GRANT SELECT ON payment TO ' || role_name;

        -- Set the session variable (using application_name here)
        PERFORM set_config('application_name', customer_id_variable::TEXT, true);
    END IF;
END $$;

-- Enable Row-Level Security on rental table
ALTER TABLE rental ENABLE ROW LEVEL SECURITY;

-- Create policy to allow Sandra to see only her rentals
CREATE POLICY rental_policy
    ON rental
    FOR SELECT
    USING (customer_id = current_setting('application_name')::int);

-- Enable Row-Level Security on payment table
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

-- Create policy to allow Sandra to see only her payments
CREATE POLICY payment_policy
    ON payment
    FOR SELECT
    USING (customer_id = current_setting('application_name')::int);

--check the session 
SHOW application_name;


-- Task 3. Implement row-level security

-- Enable Row-Level Security on the rental table
ALTER TABLE rental ENABLE ROW LEVEL SECURITY;

-- Enable Row-Level Security on the payment table
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

-- Query the rental table to verify Sandra can only access her own rentals
SELECT * FROM rental;

-- Query the payment table to verify Sandra can only access her own payments
SELECT * FROM payment;

-- Check the policies on the rental table
SELECT * FROM pg_policies WHERE tablename = 'rental';

-- Check the policies on the payment table
SELECT * FROM pg_policies WHERE tablename = 'payment';



