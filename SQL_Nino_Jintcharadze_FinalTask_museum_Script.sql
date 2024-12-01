
--3. Create a physical database with a separate database and schema and give it an appropriate domain-related name. 
--4. Populate the tables with the sample data generated, ensuring each table has at least 6+ rows (for a total of 36+ rows in all the tables) for the last 3 months.

CREATE DATABASE museum_db;
CREATE SCHEMA museum_schema;

-- Artists Table
CREATE TABLE museum_schema.artists (
    artist_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    birth_date DATE
);

INSERT INTO museum_schema.artists (first_name, last_name, birth_date)
VALUES
    ('Giorgi', 'Pirosmani', '1862-12-04'),
    ('Niko', 'Pirosmani', '1869-02-01'),
    ('Elene', 'Akhvlediani', '1919-06-15'),
    ('Tamar', 'Abuladze', '1929-08-07'),
    ('Levan', 'Kikodze', '1935-11-10'),
    ('Irakli', 'Gogava', '1985-03-03');


-- Exhibitions Table
CREATE TABLE museum_schema.exhibitions (
    exhibition_id SERIAL PRIMARY KEY,
    exhibition_name VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    CONSTRAINT chk_start_date CHECK (start_date > '2024-07-01'),
    CONSTRAINT chk_end_date CHECK (end_date > start_date)
);

INSERT INTO museum_schema.exhibitions (exhibition_name, start_date, end_date)
VALUES
    ('Georgian Art Exhibition', '2024-10-01', '2024-10-15'),
    ('Classical Masters', '2024-10-05', '2024-11-05'),
    ('Contemporary Artists of Georgia', '2024-09-01', '2024-09-30'),
    ('Traditional Georgian Culture', '2024-11-01', '2024-11-30'),
    ('Portraits of the Past', '2024-11-10', '2024-12-10'),
    ('The Golden Age of Georgian Art', '2024-08-15', '2024-09-15');


-- Collections Table
CREATE TABLE museum_schema.collections (
    collection_id SERIAL PRIMARY KEY,
    collection_name VARCHAR(255) NOT NULL,
    artist_id INT NOT NULL,
    acquisition_date DATE NOT NULL,
    value NUMERIC CHECK (value >= 0),
    CONSTRAINT fk_artist FOREIGN KEY (artist_id) REFERENCES museum_schema.artists (artist_id)
);
INSERT INTO museum_schema.collections (collection_name, artist_id, acquisition_date, value)
VALUES
    ('Pirosmani’s Masterpieces', 1, '2024-09-15', 5000000.00),
    ('Works of Niko Pirosmani', 2, '2024-08-20', 3000000.00),
    ('Elene Akhvlediani’s Artwork', 3, '2024-10-10', 1500000.00),
    ('Modern Georgian Art', 4, '2024-09-05', 2000000.00),
    ('Levan Kikodze’s Sculpture', 5, '2024-10-01', 2500000.00),
    ('Irakli Gogava’s Gallery', 6, '2024-11-15', 1000000.00);


-- Visitors Table
CREATE TABLE museum_schema.visitors (
    visitor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20) CHECK (phone ~ '^\+?\d+$')
);

INSERT INTO museum_schema.visitors (first_name, last_name, email, phone)
VALUES
    ('Nino', 'Jorjadze', 'nino.jorjadze@example.com', '+995551234567'),
    ('Sandro', 'Mikadze', 'sandro.mikadze@example.com', '+995552345678'),
    ('Mariam', 'Tskhvediani', 'mariam.tskhvediani@example.com', '+995553456789'),
    ('Zaza', 'Sagunashvili', 'zaza.sagunashvili@example.com', '+995554567890'),
    ('Irina', 'Kakabadze', 'irina.kakabadze@example.com', '+995555678901'),
    ('Giorgi', 'Chikovani', 'giorgi.chikovani@example.com', '+995556789012');


-- Tickets Table
CREATE TABLE museum_schema.tickets (
    ticket_id SERIAL PRIMARY KEY,
    visitor_id INT NOT NULL,
    exhibition_id INT NOT NULL,
    purchase_date DATE DEFAULT CURRENT_DATE,
    ticket_price NUMERIC CHECK (ticket_price >= 0),
    CONSTRAINT fk_visitor FOREIGN KEY (visitor_id) REFERENCES museum_schema.visitors (visitor_id),
    CONSTRAINT fk_exhibition FOREIGN KEY (exhibition_id) REFERENCES museum_schema.exhibitions (exhibition_id)
);

INSERT INTO museum_schema.tickets (visitor_id, exhibition_id, ticket_price)
VALUES
    (1, 1, 15.00),
    (2, 2, 20.00),
    (3, 3, 25.00),
    (4, 4, 10.00),
    (5, 5, 18.00),
    (6, 6, 22.00);


-- Many-to-Many Relationship Table for Exhibition-Artist Link
CREATE TABLE museum_schema.exhibition_artists (
    exhibition_id INT NOT NULL,
    artist_id INT NOT NULL,
    CONSTRAINT pk_exhibition_artist PRIMARY KEY (exhibition_id, artist_id),
    CONSTRAINT fk_exhibition FOREIGN KEY (exhibition_id) REFERENCES museum_schema.exhibitions (exhibition_id),
    CONSTRAINT fk_artist FOREIGN KEY (artist_id) REFERENCES museum_schema.artists (artist_id)
);

INSERT INTO museum_schema.exhibition_artists (exhibition_id, artist_id)
VALUES
    (1, 1),
    (2, 2),
    (3, 3),
    (4, 4),
    (5, 5),
    (6, 6);



--5. Create the following functions.
--5.1
CREATE OR REPLACE FUNCTION update_table(
    p_id INT,                        -- The primary key of the row you want to update
    p_column_name VARCHAR,            -- The name of the column I want to update
    p_new_value TEXT                  -- The new value you want to set for the column
)
RETURNS VOID AS $$
DECLARE
    v_sql TEXT; 
    v_column_exists BOOLEAN;
BEGIN
    -- Check if the column exists in the table
    SELECT EXISTS(
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'artists' 
        AND column_name = p_column_name
    ) INTO v_column_exists;

    IF v_column_exists THEN
        v_sql := 'UPDATE museum_schema.artists SET ' || p_column_name || ' = $1 WHERE artist_id = $2';
        EXECUTE v_sql USING p_new_value, p_id;
        RAISE NOTICE 'Updated table "artists" - Set column "%" to value "%" where artist_id = %', p_column_name, p_new_value, p_id;
    ELSE
        RAISE EXCEPTION 'Column "%" does not exist in the "artists" table', p_column_name;
    END IF;
END;
$$ LANGUAGE plpgsql;


--5.2
CREATE TABLE museum_schema.transactions (
    transaction_id SERIAL PRIMARY KEY,
    visitor_id INT NOT NULL,
    exhibition_id INT NOT NULL,
    ticket_price NUMERIC CHECK (ticket_price >= 0),
    transaction_date DATE DEFAULT CURRENT_DATE,
    CONSTRAINT fk_visitor FOREIGN KEY (visitor_id) REFERENCES museum_schema.visitors (visitor_id),
    CONSTRAINT fk_exhibition FOREIGN KEY (exhibition_id) REFERENCES museum_schema.exhibitions (exhibition_id)
);

CREATE OR REPLACE FUNCTION add_transaction(
    p_visitor_id INT,               -- The ID of the visitor making the purchase
    p_exhibition_id INT,            -- The ID of the exhibition for which the ticket is bought
    p_ticket_price NUMERIC,         -- The price of the ticket
    p_transaction_date DATE DEFAULT CURRENT_DATE   -- The transaction date, defaulting to the current date
)
RETURNS VOID AS $$
BEGIN
    -- Check if ticket price is valid
    IF p_ticket_price < 0 THEN
        RAISE EXCEPTION 'Ticket price cannot be negative';
    END IF;

    -- Insert the new transaction
    INSERT INTO museum_schema.transactions (visitor_id, exhibition_id, ticket_price, transaction_date)
    VALUES (p_visitor_id, p_exhibition_id, p_ticket_price, p_transaction_date);
    
    RAISE NOTICE 'New transaction added: visitor_id = %, exhibition_id = %, ticket_price = %, transaction_date = %',
        p_visitor_id, p_exhibition_id, p_ticket_price, p_transaction_date;
END;
$$ LANGUAGE plpgsql;

--6.
CREATE VIEW museum_schema.recent_quarter_analytics AS
WITH recent_quarter AS (
    -- Subquery to find the most recent quarter based on transaction date
    SELECT
        EXTRACT(YEAR FROM MAX(transaction_date)) AS year,
        CEIL(EXTRACT(MONTH FROM MAX(transaction_date)) / 3.0) AS quarter
    FROM museum_schema.transactions
),
quarter_data AS (
    -- Get all transactions from the most recent quarter
    SELECT
        t.transaction_date,
        t.ticket_price,
        e.exhibition_name,
        v.first_name AS visitor_first_name,
        v.last_name AS visitor_last_name
    FROM museum_schema.transactions t
    JOIN museum_schema.visitors v ON t.visitor_id = v.visitor_id
    JOIN museum_schema.exhibitions e ON t.exhibition_id = e.exhibition_id
    WHERE EXTRACT(YEAR FROM t.transaction_date) = (SELECT year FROM recent_quarter)
      AND CEIL(EXTRACT(MONTH FROM t.transaction_date) / 3.0) = (SELECT quarter FROM recent_quarter)
)
SELECT
    exhibition_name,
    COUNT(*) AS total_transactions,
    SUM(ticket_price) AS total_sales
FROM quarter_data
GROUP BY exhibition_name
ORDER BY total_sales DESC;


--7.
CREATE ROLE manager_role LOGIN PASSWORD 'password';

-- Grant SELECT privilege on all tables in the schema
GRANT SELECT ON ALL TABLES IN SCHEMA museum_schema TO manager_role;

-- Grant SELECT on future tables in the schema
ALTER DEFAULT PRIVILEGES IN SCHEMA museum_schema
GRANT SELECT ON TABLES TO manager_role;




