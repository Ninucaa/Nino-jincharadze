--Task 1. Create a view

CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
SELECT 
    cat.name AS category_name,
    SUM(pay.amount) AS total_sales_revenue
FROM 
    category cat
INNER JOIN film_category fm ON fm.category_id = cat.category_id
INNER JOIN film f ON f.film_id = fm.film_id
INNER JOIN inventory i ON i.film_id = f.film_id
INNER JOIN rental r ON r.inventory_id = i.inventory_id
INNER JOIN payment pay ON pay.rental_id = r.rental_id
WHERE 
    EXTRACT(YEAR FROM r.rental_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    AND CEIL(EXTRACT(MONTH FROM r.rental_date)::NUMERIC / 3) = CEIL(EXTRACT(MONTH FROM CURRENT_DATE)::NUMERIC / 3)
GROUP BY 
    cat.name
HAVING 
    SUM(pay.amount) > 0;



SELECT cat.name, SUM(pay.amount) AS total_sales_revenue
FROM category cat
INNER JOIN film_category fm ON fm.category_id = cat.category_id
INNER JOIN film f ON f.film_id = fm.film_id
INNER JOIN inventory i ON i.film_id = f.film_id
INNER JOIN rental r ON r.inventory_id = i.inventory_id
INNER JOIN payment pay ON pay.rental_id = r.rental_id
WHERE EXTRACT(YEAR FROM r.rental_date) = 2017  -- i have data only for this year
      AND CEIL(EXTRACT(MONTH FROM r.rental_date)::NUMERIC / 3) = 1  -- Example for the first quarter of 2017
GROUP BY cat.name
HAVING SUM(pay.amount) > 0;

--Task 2. Create a query language functions
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(current_period TEXT)
RETURNS TABLE(category_name TEXT, total_sales_revenue NUMERIC) AS $$
DECLARE
    quarter INT;
    year INT;
BEGIN
    -- Extract quarter and year from the input parameter
    SELECT 
        CAST(SPLIT_PART(current_period, '-', 1) AS INT),  -- Quarter
        CAST(SPLIT_PART(current_period, '-', 2) AS INT)  -- Year
    INTO quarter, year;

    RETURN QUERY
    SELECT 
        cat.name AS category_name, 
        SUM(pay.amount) AS total_sales_revenue
    FROM 
        category cat
    INNER JOIN film_category fm ON fm.category_id = cat.category_id
    INNER JOIN film f ON f.film_id = fm.film_id
    INNER JOIN inventory i ON i.film_id = f.film_id
    INNER JOIN rental r ON r.inventory_id = i.inventory_id
    INNER JOIN payment pay ON pay.rental_id = r.rental_id
    WHERE 
        EXTRACT(YEAR FROM r.rental_date) = year
        AND CEIL(EXTRACT(MONTH FROM r.rental_date)::NUMERIC / 3) = quarter
    GROUP BY 
        cat.name
    HAVING 
        SUM(pay.amount) > 0;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_sales_revenue_by_category_qtr('1-2017');


--Task 3. Create procedure language functions
CREATE OR REPLACE FUNCTION most_popular_films_by_countries(countries TEXT[])
RETURNS TABLE(
    country TEXT,
    film TEXT,
    rating TEXT,
    language TEXT,
    length INT,
    release_year INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        co.country AS country,
        f.title AS film,
        f.rating::TEXT AS rating,
        l.name::TEXT AS language,
        f.length::INTEGER AS length,
        f.release_year::INTEGER AS release_year
    FROM 
        country co
    INNER JOIN city ci ON ci.country_id = co.country_id
    INNER JOIN address a ON a.city_id = ci.city_id
    INNER JOIN customer cu ON cu.address_id = a.address_id
    INNER JOIN rental r ON cu.customer_id = r.customer_id
    INNER JOIN inventory i ON i.inventory_id = r.inventory_id
    INNER JOIN film f ON f.film_id = i.film_id
    INNER JOIN language l ON l.language_id = f.language_id
    WHERE 
        co.country = ANY(countries)
    GROUP BY 
        co.country, f.title, f.rating, l.name, f.length, f.release_year
    HAVING 
        COUNT(r.rental_id) = (
            SELECT MAX(count_rentals)
            FROM (
                SELECT COUNT(r2.rental_id) AS count_rentals
                FROM rental r2
                INNER JOIN inventory i2 ON i2.inventory_id = r2.inventory_id
                INNER JOIN film f2 ON f2.film_id = i2.film_id
                INNER JOIN customer cu2 ON cu2.customer_id = r2.customer_id
                INNER JOIN address a2 ON a2.address_id = cu2.address_id
                INNER JOIN city ci2 ON ci2.city_id = a2.city_id
                INNER JOIN country co2 ON co2.country_id = ci2.country_id
                WHERE co2.country = co.country
                GROUP BY f2.film_id
            ) subquery
        );
END;
$$ LANGUAGE plpgsql;

--Check
SELECT * 
FROM most_popular_films_by_countries(ARRAY['Afghanistan', 'Brazil', 'United States']);


--Task 4. Create procedure language functions
CREATE OR REPLACE FUNCTION films_in_stock_by_title(title_search TEXT)
RETURNS TABLE(
    row_num INT,
    film_title TEXT,
    language TEXT,
    customer_name TEXT,
    rental_date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ROW_NUMBER() OVER () AS row_num,
        f.title AS film_title,
        l.name AS language,
        cust.first_name || ' ' || cust.last_name AS customer_name,
        r.rental_date
    FROM 
        film f
    INNER JOIN language l ON l.language_id = f.language_id
    INNER JOIN inventory i ON i.film_id = f.film_id
    INNER JOIN rental r ON r.inventory_id = i.inventory_id
    INNER JOIN customer cust ON cust.customer_id = r.customer_id
    WHERE 
        f.title ILIKE title_search;

    IF NOT FOUND THEN
        RAISE NOTICE 'No movies with the specified title found in stock.';
    END IF;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM films_in_stock_by_title('%love%');

-- Task 5. Create procedure language functions
CREATE OR REPLACE PROCEDURE new_movie(
    title TEXT, 
    release_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),  -- Default to the current year
    language_name TEXT DEFAULT 'Klingon'  -- Default language is 'Klingon'
)
AS $$
BEGIN
    -- Check if the language exists in the 'language' table
    IF NOT EXISTS (SELECT 1 FROM language WHERE language.name = language_name) THEN
        INSERT INTO language (name) VALUES (language_name);
    END IF;

    -- Insert a new movie into the film table
    INSERT INTO film (title, release_year, language_id, rental_rate, rental_duration, replacement_cost)
    VALUES (
        title, release_year,
        (SELECT language_id FROM language WHERE language.name = language_name),  -- Retrieve the language_id
        4.99, 3, 19.99  
    );
END;
$$ LANGUAGE plpgsql;


DROP PROCEDURE new_movie(text,integer,text)


