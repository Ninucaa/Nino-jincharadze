--Task 1. Create a view

CREATE OR REPLACE VIEW get_sales_revenue_by_category_qtr AS
WITH current_quarter AS (
    SELECT 
        CEIL(EXTRACT(MONTH FROM CURRENT_DATE)::NUMERIC / 3) AS quarter,
        EXTRACT(YEAR FROM CURRENT_DATE) AS year
)
SELECT cat.name,SUM(pay.amount) AS total_sales_revenue
FROM  category cat
INNER JOIN film_category fm ON fm.category_id = cat.category_id
INNER JOIN film f ON f.film_id = fm.film_id
INNER JOIN inventory i ON i.film_id = f.film_id
INNER JOIN rental r ON r.inventory_id = i.inventory_id
INNER JOIN payment pay ON pay.rental_id = r.rental_id
INNER JOIN current_quarter cq ON EXTRACT(YEAR FROM r.rental_date) = cq.year
                      AND CEIL(EXTRACT(MONTH FROM r.rental_date)::NUMERIC / 3) = cq.quarter
GROUP BY cat.name
HAVING SUM(pay.amount) > 0;


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
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(quarter INT, year INT)
RETURNS TABLE(category_name TEXT, total_sales_revenue NUMERIC) AS $$
BEGIN 
	RETURN QUERY
	SELECT cat.name AS category_name, SUM(pay.amount) AS total_sales_revenue
	FROM category cat
	INNER JOIN film_category fm ON fm.category_id = cat.category_id
	INNER JOIN film f ON f.film_id = fm.film_id
	INNER JOIN inventory i ON i.film_id = f.film_id
	INNER JOIN rental r ON r.inventory_id = i.inventory_id
	INNER JOIN payment pay ON pay.rental_id = r.rental_id
	WHERE EXTRACT(YEAR FROM r.rental_date) = year
		  AND CEIL(EXTRACT(MONTH FROM r.rental_date)::NUMERIC/3)=quarter
	GROUP BY cat.name
	HAVING SUM(pay.amount)>0;
END;
$$ LANGUAGE plpgsql;

--Task 3. Create procedure language functions
CREATE OR REPLACE FUNCTION most_popular_films_by_countries(countries TEXT[])
RETURNS TABLE(
	Country TEXT,
	Film TEXT,
	Rating TEXT,
	Language TEXT,
	Length INT,
	"Release year" INT,
	"Total rentals" INT
) AS $$
BEGIN
	RETURN QUERY
	SELECT 
        co.country AS Country, 
        f.title AS Film, 
        f.rating::TEXT AS Rating,  -- Cast to TEXT
		l.name::TEXT AS Language,  -- Cast to TEXT
        f.length::INTEGER AS Length,  -- Cast smallint to integer
        f.release_year::INTEGER AS "Release year",  -- Cast year to integer
		COUNT(r.rental_id)::INTEGER AS "Total rentals"  -- Cast COUNT result to INTEGER
	FROM country co
	INNER JOIN city ci ON ci.country_id = co.country_id
	INNER JOIN address a ON a.city_id = ci.city_id
	INNER JOIN customer cu ON cu.address_id = a.address_id
	INNER JOIN rental r ON cu.customer_id = r.customer_id 
	INNER JOIN inventory i ON i.inventory_id = r.inventory_id
	INNER JOIN film f ON f.film_id = i.film_id
	INNER JOIN language l ON l.language_id = f.language_id
	WHERE co.country = ANY(countries) -- Filters by the input list of countries
	GROUP BY co.country, f.title, f.rating, l.name, f.length, f.release_year
	ORDER BY co.country, "Total rentals" DESC;
END;
$$ LANGUAGE plpgsql;

--Check
SELECT * 
FROM most_popular_films_by_countries(ARRAY['Afghanistan', 'Brazil', 'United States']);


--Task 4. Create procedure language functions
CREATE OR REPLACE FUNCTION films_in_stock_by_title(title_search TEXT)
RETURNS TABLE(
    Row_num INT,
    "Film title" TEXT,
    Language TEXT,
    "Customer name" TEXT,
    "Rental date" DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT ROW_NUMBER() OVER ()::INTEGER AS Row_num,  -- Automatically generated row number
           f.title AS "Film title",
           l.name::TEXT AS Language,  -- Explicit cast to TEXT
           cust.first_name || ' ' || cust.last_name AS "Customer name",
           r.rental_date::DATE AS "Rental date"  -- Cast timestamp to DATE
    FROM film f
    INNER JOIN language l ON l.language_id = f.language_id
    INNER JOIN inventory i ON i.film_id = f.film_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id
    INNER JOIN customer cust ON cust.customer_id = r.customer_id
    WHERE f.title ILIKE title_search  -- Case-insensitive partial match for title
      AND i.inventory_id IS NOT NULL  -- Ensuring the film is in stock (available in inventory)
    ORDER BY Row_num;  
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

