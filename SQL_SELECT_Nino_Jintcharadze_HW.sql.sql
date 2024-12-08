-- Part 1: SQL queries to retrieve animation movies

-- -- -- -- -- -- TASK 1.1 -- -- -- -- -- --
-- Task: Find all animation movies:
-- 1. Released between 2017-2019 (inclusive)
-- 2. Rental rate > $1
-- 3. Category must be 'Animation'
-- 4. Results should be alphabetically sorted by title
-- 5. Only need to display the title

-- Solution 1: Using standard INNER JOINs
-- This solution efficiently retrieves animation movie titles using JOINs to link 
-- the relevant tables while ensuring that all filters are applied directly in the query.
SELECT f.title
FROM category AS cat 
INNER JOIN film_category AS fc ON cat.category_id = fc.category_id  -- Join to link categories with films
INNER JOIN film AS f ON f.film_id = fc.film_id  -- Join to link films with their categories
WHERE f.release_year BETWEEN 2017 AND 2019  -- Filter for the specified release years
      AND f.rental_rate > 1  -- Filter for rental rates greater than $1
      AND cat.name = 'Animation'  -- Ensure the category is 'Animation'
ORDER BY f.title ASC;  -- Sort results alphabetically by title

-- Solution 2: Using Common Table Expressions (CTEs)
-- This solution uses a CTE to first isolate the 'Animation' category, improving readability
-- and separation of concerns before performing the final filtering and retrieval of titles.
WITH animation_films AS (
    SELECT fc.film_id
    FROM category AS cat
    INNER JOIN film_category AS fc ON cat.category_id = fc.category_id  -- Join to link categories with films
    WHERE cat.name = 'Animation'  -- Filter for 'Animation' category
)
SELECT f.title
FROM film AS f
INNER JOIN animation_films AS af ON f.film_id = af.film_id  -- Join to get film titles from CTE
WHERE f.release_year BETWEEN 2017 AND 2019  -- Filter for the specified release years
      AND f.rental_rate > 1  -- Filter for rental rates greater than $1
ORDER BY f.title ASC;  -- Sort results alphabetically by title

-- Solution 3: Using EXISTS clause
-- This solution demonstrates an alternative approach by using EXISTS clauses to check for 
-- the presence of the 'Animation' category, allowing for flexible and logical filtering.
SELECT f.title
FROM film AS f
WHERE EXISTS (  -- Check for existence of a matching category
    SELECT 1
    FROM film_category AS fc
    WHERE fc.film_id = f.film_id  -- Match film IDs
      AND fc.category_id IN (  -- Filter for categories that match 'Animation'
          SELECT category_id
          FROM category AS cat
          WHERE cat.name = 'Animation'  -- Ensure the category is 'Animation'
      )
)
AND f.release_year BETWEEN 2017 AND 2019  -- Filter for the specified release years
AND f.rental_rate > 1  -- Filter for rental rates greater than $1
ORDER BY f.title ASC;  -- Sort results alphabetically by title


-- Best Solution is 2 (Using CTE).
-- Using a CTE to pre-filter movies by category ("Animation") improves clarity by separating filtering logic, 
-- making it easier to understand and maintain without affecting performance significantly.


-- -- -- -- -- -- TASK 1.2 -- -- -- -- -- --

-- Task: Calculate revenue earned by each rental store since March 2017
-- Business Logic Interpretation:
-- 1. Need to show combined store addresses (address + address2)
-- 2. Calculate total revenue from payments
-- 3. Only include rentals from March 2017 onwards
-- 4. Group results by store location
-- 5. Address2 is optional (handle NULL values)

-- Solution 1: Using CTE to separate address and revenue calculations
-- This solution separates address construction and revenue calculation into CTEs,
-- improving clarity and allowing for modular queries. It also handles NULL values
-- for address2 using COALESCE.
WITH store_addresses AS (
   SELECT 
       st.store_id,
       ad.address || ' ' || COALESCE(ad.address2, '') AS full_address  -- Combine address and address2, handling NULL
   FROM store AS st
   INNER JOIN address AS ad ON ad.address_id = st.address_id  -- INNER JOIN to connect stores with addresses
),
store_revenue AS (
   SELECT 
       s.store_id,
       SUM(pay.amount) AS revenue  -- Calculate total revenue per store
   FROM payment AS pay
   INNER JOIN rental AS r ON r.rental_id = pay.rental_id  -- INNER JOIN to link payments with rentals
   INNER JOIN staff AS s ON s.staff_id = r.staff_id  -- INNER JOIN to connect rentals with staff/store
   WHERE r.rental_date >= '2017-03-01'  -- Filter for rentals since March 2017
   GROUP BY s.store_id  -- Group by store ID to aggregate revenue
)
SELECT 
   sa.full_address AS addresses,  -- Select combined addresses from store_addresses CTE
   sr.revenue  -- Select revenue from store_revenue CTE
FROM store_addresses AS sa
INNER JOIN store_revenue AS sr ON sr.store_id = sa.store_id;  -- Join the two CTEs on store ID

-- Solution 2: Using subqueries
-- This solution employs subqueries to retrieve both the address and the revenue.
-- It’s a more straightforward approach, though it may be less efficient than using CTEs.
SELECT 
   (SELECT ad.address || ' ' || COALESCE(ad.address2, '')  -- Combine address and address2, handling NULL
    FROM address AS ad 
    WHERE ad.address_id = st.address_id) AS addresses,  -- Subquery to get the full address
   (SELECT SUM(pay.amount)  -- Subquery to calculate revenue
    FROM payment AS pay
    INNER JOIN rental AS r ON r.rental_id = pay.rental_id  -- INNER JOIN to link payments with rentals
    INNER JOIN staff AS s ON s.staff_id = r.staff_id  -- INNER JOIN to connect rentals with staff/store
    WHERE s.store_id = st.store_id
    AND r.rental_date >= '2017-03-01') AS revenue  -- Filter for rentals since March 2017
FROM store AS st;  -- Main query on the store table

-- Solution 3: Using window functions
-- This solution demonstrates a method using window functions to calculate revenue
-- and get addresses, but it violates the requirement of not using window functions.
-- Hence, we won't use this solution as per your constraints.
SELECT DISTINCT
   ad.address || ' ' || COALESCE(ad.address2, '') AS addresses,  -- Combine address and address2, handling NULL
   SUM(pay.amount) OVER (PARTITION BY st.store_id) AS revenue  -- Calculate revenue using window function (not allowed as per requirements)
FROM payment AS pay
INNER JOIN rental AS r ON r.rental_id = pay.rental_id  -- INNER JOIN to link payments with rentals
INNER JOIN staff AS s ON s.staff_id = r.staff_id  -- INNER JOIN to connect rentals with staff/store
INNER JOIN store AS st ON st.store_id = s.store_id  -- INNER JOIN to link stores
INNER JOIN address AS ad ON ad.address_id = st.address_id  -- INNER JOIN to get addresses
WHERE r.rental_date >= '2017-03-01';  -- Filter for rentals since March 2017



-- In Solution 1.2, the filter on the category is moved to a Common Table Expression (CTE) to improve readability and modularity.
--  By isolating 'Animation' films in the animation_films CTE, it makes the main query more straightforward, 
--  as it no longer has to filter by category in each JOIN. This approach also provides a modular way to manage complex queries, 
--  breaking down filtering steps into smaller, manageable pieces.


-- Best Solution is 1 (Using CTE).
-- The CTEs modularize address construction and revenue calculation, enhancing readability while efficiently managing large datasets.
--  Handling NULL values in address2 via COALESCE ensures robustness, and separating the data retrieval stages does not significantly impact performance compared to other solutions.

-- -- -- -- -- -- TASK 1.3 -- -- -- -- -- --
-- Task: Top-5 actors by number of movies (released since 2015)
-- (Columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)

-- Business Logic Interpretation:
-- The goal is to identify the top 5 actors who have been in the most movies since 2015.
-- This involves:
-- 1. Filtering the films to include only those released from 2015 onward.
-- 2. Counting the number of films for each actor that meets the release year condition.
-- 3. Grouping results by actor to ensure accurate counting.
-- 4. Sorting the actors based on their movie count in descending order to highlight the most prolific actors.
-- 5. Limiting the results to the top 5 actors for concise output.

-- Solution 1: Using standard JOINs
-- This approach directly joins the actor, film_actor, and film tables.
-- It counts the number of movies for each actor released since 2015.
-- The results are grouped by the actor's first and last name and sorted to show the top 5.
SELECT 
    a.first_name, 
    a.last_name, 
    COUNT(f.film_id) AS number_of_movies  -- Count movies for each actor
FROM 
    actor AS a
INNER JOIN 
    film_actor AS fa ON fa.actor_id = a.actor_id  -- Join actor with film_actor to get actor's films
INNER JOIN 
    film AS f ON f.film_id = fa.film_id  -- Join film_actor with film to filter by release year
WHERE 
    f.release_year >= 2015  -- Filter films released since 2015
GROUP BY 
    a.first_name, a.last_name  -- Group results by actor's name
ORDER BY 
    number_of_movies DESC  -- Sort results by number of movies in descending order
LIMIT 5;  -- Limit results to top 5 actors

-- Solution 2: Using CTE to separate counting
-- This solution uses a Common Table Expression (CTE) to first calculate the number of movies for each actor.
-- The main query then selects from the CTE to retrieve the top 5 actors.
WITH actor_movie_counts AS (
    SELECT 
        a.first_name, 
        a.last_name, 
        COUNT(f.film_id) AS number_of_movies  -- Count movies for each actor
    FROM 
        actor AS a
    INNER JOIN 
        film_actor AS fa ON fa.actor_id = a.actor_id  -- Join actor with film_actor
    INNER JOIN 
        film AS f ON f.film_id = fa.film_id  -- Join film_actor with film
    WHERE 
        f.release_year >= 2015  -- Filter films released since 2015
    GROUP BY 
        a.first_name, a.last_name  -- Group by actor's name
)
SELECT 
    first_name, last_name, number_of_movies
FROM 
    actor_movie_counts  -- Select from the CTE
ORDER BY 
    number_of_movies DESC  -- Sort results by number of movies in descending order
LIMIT 5;  -- Limit results to top 5 actors

-- Solution 3: Using EXISTS clause
-- This approach utilizes the EXISTS clause to ensure that only actors with movies released since 2015 are counted.
-- It includes a correlated subquery to count the number of movies for each actor.
SELECT 
    a.first_name, 
    a.last_name, 
    (SELECT COUNT(*)  -- Subquery to count movies for each actor
     FROM film_actor AS fa
     INNER JOIN film AS f ON f.film_id = fa.film_id  -- Join film_actor with film
     WHERE fa.actor_id = a.actor_id AND f.release_year >= 2015) AS number_of_movies
FROM 
    actor AS a
WHERE 
    EXISTS (  -- Check if the actor has any movies released since 2015
        SELECT 1
        FROM film_actor AS fa
        INNER JOIN film AS f ON f.film_id = fa.film_id  -- Join film_actor with film
        WHERE fa.actor_id = a.actor_id AND f.release_year >= 2015
    )
ORDER BY 
    number_of_movies DESC  -- Sort results by number of movies in descending order
LIMIT 5;  -- Limit results to top 5 actors

-- In Solution 1.3, the subquery for counting movies per actor runs once per actor in the SELECT list. 
-- Therefore, for each unique actor in the main query's result set, the subquery counts the actor's movies released since 2015.
--  This results in the subquery being executed multiple times—one for each actor in the actor table that meets the condition.

-- Best Solution is 2 (Using CTE).
-- Using a CTE to pre-calculate the movie count for each actor simplifies the query structure, 
-- isolating counting logic and making the main query focused on retrieving the top 5 actors.
--  It performs well with complex aggregation tasks, as the CTE minimizes redundant calculations.


-- -- -- -- -- -- TASK 1.4 -- -- -- -- -- --

-- Task: Number of Drama, Travel, Documentary per year
-- Business Logic Interpretation:
-- 1. Count movies in each category: Drama, Travel, Documentary
-- 2. Aggregate results by release year
-- 3. Handle NULL values in the category count
-- 4. Sort results by release year in descending order
-- 5. Ensure only relevant movies are counted

-- Solution 1: Using standard JOINs
-- This approach directly joins the necessary tables and uses conditional counting to aggregate
-- the number of movies in each category for each release year.
SELECT 
    f.release_year,
    COUNT(CASE WHEN cat.name = 'Drama' THEN 1 END) AS number_of_drama_movies, -- Count of Drama movies
    COUNT(CASE WHEN cat.name = 'Travel' THEN 1 END) AS number_of_travel_movies, -- Count of Travel movies
    COUNT(CASE WHEN cat.name = 'Documentary' THEN 1 END) AS number_of_documentary_movies -- Count of Documentary movies
FROM 
    film AS f
INNER JOIN 
    film_category AS fc ON f.film_id = fc.film_id -- Join film with film_category to filter by category
INNER JOIN 
    category AS cat ON fc.category_id = cat.category_id -- Join film_category with category for category names
GROUP BY 
    f.release_year -- Group results by release year
ORDER BY 
    f.release_year DESC; -- Sort results by release year in descending order

-- Solution 2: Using Common Table Expressions (CTEs)
-- This solution uses a Common Table Expression to first organize the movies by their categories and release years.
-- The main query then counts the movies in each category per release year.
WITH categorized_movies AS (
    SELECT 
        f.release_year,
        cat.name AS category_name -- Capture category names for each movie
    FROM 
        film AS f
    INNER JOIN 
        film_category AS fc ON f.film_id = fc.film_id -- Join film with film_category
    INNER JOIN 
        category AS cat ON fc.category_id = cat.category_id -- Join film_category with category
)
SELECT 
    release_year,
    COUNT(CASE WHEN category_name = 'Drama' THEN 1 END) AS number_of_drama_movies, -- Count of Drama movies
    COUNT(CASE WHEN category_name = 'Travel' THEN 1 END) AS number_of_travel_movies, -- Count of Travel movies
    COUNT(CASE WHEN category_name = 'Documentary' THEN 1 END) AS number_of_documentary_movies -- Count of Documentary movies
FROM 
    categorized_movies -- Select from the CTE
GROUP BY 
    release_year -- Group results by release year
ORDER BY 
    release_year DESC; -- Sort results by release year in descending order

-- Solution 3: Using Subqueries
-- This approach counts the movies in each category using subqueries. 
-- It retrieves the counts of each category for every release year, ensuring relevant filtering.
SELECT 
    f.release_year,
    (SELECT COUNT(*)  -- Subquery to count Drama movies
     FROM film_category AS fc 
     INNER JOIN category AS cat ON fc.category_id = cat.category_id -- Join to get category names
     WHERE cat.name = 'Drama' 
       AND fc.film_id IN (SELECT film_id FROM film WHERE release_year = f.release_year)) AS number_of_drama_movies,
    (SELECT COUNT(*)  -- Subquery to count Travel movies
     FROM film_category AS fc 
     INNER JOIN category AS cat ON fc.category_id = cat.category_id -- Join to get category names
     WHERE cat.name = 'Travel' 
       AND fc.film_id IN (SELECT film_id FROM film WHERE release_year = f.release_year)) AS number_of_travel_movies,
    (SELECT COUNT(*)  -- Subquery to count Documentary movies
     FROM film_category AS fc 
     INNER JOIN category AS cat ON fc.category_id = cat.category_id -- Join to get category names
     WHERE cat.name = 'Documentary' 
       AND fc.film_id IN (SELECT film_id FROM film WHERE release_year = f.release_year)) AS number_of_documentary_movies
FROM 
    film AS f -- Start with the film table to ensure we have all release years
GROUP BY 
    f.release_year -- Group results by release year
ORDER BY 
    f.release_year DESC; -- Sort results by release year in descending order


-- Best Solution is 2 (Using CTE).
-- The CTE allows for clear categorization and counts per year in a straightforward and manageable structure, 
-- making it easier to follow and maintain than subqueries or more complex joins. 
-- This structure also handles conditional aggregation effectively.

-- -- -- -- -- -- TASK 1.5 -- -- -- -- -- --

-- Task: List of horrors rented by each client and total amount paid
-- Business Logic Interpretation:
-- 1. Retrieve a list of all horror movies rented by each client.
-- 2. Present the list in a single column separated by commas.
-- 3. Calculate the total amount paid for these rentals.
-- 4. Group results by client.

-- Solution 1: Using standard JOINs 
-- This method directly joins all necessary tables to aggregate the horror films rented by each customer
-- and their total payments in one query.
SELECT 
    cust.customer_id,                       
    cust.first_name || ' ' || cust.last_name AS customer_name, -- Full name of the customer
    STRING_AGG(f.title, ', ') AS horror_films,  -- Aggregate horror film titles into a single string
    SUM(pay.amount) AS total_amount_paid -- Calculate total payment made by the customer for horror films     
FROM 
    film AS f
INNER JOIN 
    film_category AS fc ON fc.film_id = f.film_id -- Join film with film_category to filter by category
INNER JOIN 
    category AS cat ON cat.category_id = fc.category_id -- Join film_category with category to get the category name
INNER JOIN 
    inventory AS i ON i.film_id = f.film_id -- Join inventory to get the inventory items
INNER JOIN 
    rental AS r ON r.inventory_id = i.inventory_id -- Join rental to connect rentals to customers
INNER JOIN 
    customer AS cust ON cust.customer_id = r.customer_id -- Join customer to get customer details
INNER JOIN 
    payment AS pay ON pay.rental_id = r.rental_id -- Join payment to get payment details
WHERE 
    cat.name = 'Horror' -- Filter for horror category
GROUP BY 
    cust.customer_id, cust.first_name, cust.last_name; -- Group results by customer

-- Solution 2: Using Common Table Expressions (CTEs)
-- This approach organizes the relevant horror rentals in a CTE for clarity and then aggregates them.
WITH HorrorRentals AS (
    SELECT 
        cust.customer_id, 
        cust.first_name || ' ' || cust.last_name AS customer_name, -- Full name of the customer
        f.title AS horror_film, -- Film title
        pay.amount AS payment_amount -- Payment for each rental
    FROM 
        film AS f
    INNER JOIN 
        film_category AS fc ON fc.film_id = f.film_id -- Join to filter by category
    INNER JOIN 
        category AS cat ON cat.category_id = fc.category_id -- Join to get category names
    INNER JOIN 
        inventory AS i ON i.film_id = f.film_id -- Join to inventory for rentals
    INNER JOIN 
        rental AS r ON r.inventory_id = i.inventory_id -- Join rentals
    INNER JOIN 
        customer AS cust ON cust.customer_id = r.customer_id -- Join to get customer details
    INNER JOIN 
        payment AS pay ON pay.rental_id = r.rental_id -- Join to get payment details
    WHERE 
        cat.name = 'Horror' -- Filter for horror films
)
SELECT 
    customer_id, 
    customer_name, 
    STRING_AGG(horror_film, ', ') AS horror_films, -- Aggregate horror film titles into a single string
    SUM(payment_amount) AS total_amount_paid -- Sum payments made by each customer
FROM 
    HorrorRentals -- Select from the CTE
GROUP BY 
    customer_id, customer_name; -- Group results by customer

-- Solution 3: Using Subqueries
-- This method retrieves horror films and total payments using correlated subqueries for each customer.
SELECT 
    cust.customer_id,                       
    cust.first_name || ' ' || cust.last_name AS customer_name, -- Full name of the customer
    (SELECT STRING_AGG(f.title, ', ') 
     FROM film AS f
     INNER JOIN film_category AS fc ON fc.film_id = f.film_id -- Join to filter by category
     INNER JOIN category AS cat ON cat.category_id = fc.category_id -- Join to get category names
     INNER JOIN inventory AS i ON i.film_id = f.film_id -- Join to inventory
     INNER JOIN rental AS r ON r.inventory_id = i.inventory_id -- Join rentals
     WHERE r.customer_id = cust.customer_id AND cat.name = 'Horror') AS horror_films, -- Aggregate titles for horror films
    (SELECT SUM(pay.amount) 
     FROM payment AS pay
     INNER JOIN rental AS r ON pay.rental_id = r.rental_id -- Join to get rentals
     INNER JOIN inventory AS i ON r.inventory_id = i.inventory_id -- Join to inventory for films
     INNER JOIN film_category AS fc ON i.film_id = fc.film_id -- Join to filter by category
     INNER JOIN category AS cat ON fc.category_id = cat.category_id -- Join to get category names
     WHERE r.customer_id = cust.customer_id AND cat.name = 'Horror') AS total_amount_paid -- Sum payments for horror films
FROM 
    customer AS cust
WHERE 
    EXISTS (SELECT 1 
            FROM rental AS r
            INNER JOIN inventory AS i ON r.inventory_id = i.inventory_id -- Join to inventory
            INNER JOIN film_category AS fc ON i.film_id = fc.film_id -- Join to filter by category
            INNER JOIN category AS cat ON fc.category_id = cat.category_id -- Join to get category names
            WHERE r.customer_id = cust.customer_id AND cat.name = 'Horror'); -- Ensure that the customer has rented horror films

-- Best Solution is 2 (Using CTE).
-- The CTE simplifies aggregation by separating the horror movie rentals and payments logic,
--  then performing the final aggregation in a clear and organized structure. 
--  This approach ensures readability and prevents performance issues caused by repeated subqueries.


-- -- -- -- -- -- TASK 2.1 -- -- -- -- -- --
-- Task: List top 3 staff members by total revenue generated in 2017
-- Business Logic Interpretation:
-- 1. Calculate the total revenue generated by each staff member in 2017.
-- 2. Aggregate results by staff member and store.
-- 3. Sort the results to find the top three staff members based on revenue.

-- Solution 1: Using standard JOINs 
-- This method directly joins the necessary tables to compute the total revenue for each staff member in a single query.
SELECT 
    s.staff_id,
    s.first_name || ' ' || s.last_name AS staff_name, -- Full name of the staff
    st.store_id, -- Store ID associated with the staff
    SUM(pay.amount) AS total_revenue -- Total revenue generated by the staff
FROM 
    staff AS s
INNER JOIN 
    rental AS r ON r.staff_id = s.staff_id -- Join rentals to associate staff with rentals
INNER JOIN 
    payment AS pay ON pay.rental_id = r.rental_id -- Join payments to calculate total revenue
INNER JOIN 
    store AS st ON s.store_id = st.store_id -- Join store to get store details
WHERE 
    EXTRACT(YEAR FROM pay.payment_date) = 2017 -- Filter payments made in the year 2017
GROUP BY 
    s.staff_id, s.first_name, s.last_name, st.store_id -- Group by staff ID and names to get totals per staff
ORDER BY 
    total_revenue DESC -- Sort results by total revenue in descending order
LIMIT 3; -- Limit to the top three staff members



-- Solution 2: Using Common Table Expressions (CTEs)
-- This approach first compiles revenue data in a CTE and then selects the top staff based on that data.
WITH RevenueGenerated AS (
    SELECT 
        s.staff_id,
        s.first_name || ' ' || s.last_name AS staff_name, -- Full name of the staff
        st.store_id, -- Store ID associated with the staff
        SUM(pay.amount) AS total_revenue -- Total revenue for the staff in 2017
    FROM 
        staff AS s
    INNER JOIN 
        rental AS r ON r.staff_id = s.staff_id -- Join rentals
    INNER JOIN 
        payment AS pay ON pay.rental_id = r.rental_id -- Join payments
    INNER JOIN 
        store AS st ON s.store_id = st.store_id -- Join store
    WHERE 
        EXTRACT(YEAR FROM pay.payment_date) = 2017  -- Filter for payments in 2017
    GROUP BY 
        s.staff_id, s.first_name, s.last_name, st.store_id -- Group results by staff
)
SELECT 
    staff_id,
    staff_name,
    store_id,
    total_revenue
FROM 
    RevenueGenerated
ORDER BY 
    total_revenue DESC -- Order by revenue to get top earners
LIMIT 3; -- Select only the top three staff members

-- Solution 3: Using Subqueries
-- This method retrieves the total revenue for each staff member using correlated subqueries.
SELECT 
    s.staff_id,
    s.first_name || ' ' || s.last_name AS staff_name, -- Full name of the staff
    st.store_id, -- Store ID associated with the staff
    (SELECT SUM(pay.amount) 
     FROM payment AS pay
     JOIN rental AS r ON pay.rental_id = r.rental_id -- Join to get rentals for each staff
     WHERE r.staff_id = s.staff_id 
       AND EXTRACT(YEAR FROM pay.payment_date) = 2017) AS total_revenue -- Calculate total revenue for 2017
FROM 
    staff AS s
JOIN 
    store AS st ON s.store_id = st.store_id -- Join store to get store details
ORDER BY 
    total_revenue DESC -- Sort results by total revenue
LIMIT 3; -- Limit to the top three staff members


-- -- -- -- -- -- TASK 2.2 -- -- -- -- -- --

-- Task: Find the top 5 rented movies and their expected audience age
-- Business Logic Interpretation:
-- 1. Count the number of rentals for each movie.
-- 2. Determine the expected audience age based on the movie's rating.
-- 3. Sort the results to get the top 5 rented movies.

-- Solution 1: Using standard JOINs 
-- This solution directly aggregates the rental counts and determines the expected audience age in a single query.
SELECT 
    f.film_id, -- Unique identifier for the film
    f.title, -- Title of the film
    COUNT(r.rental_id) AS rental_count, -- Count of rentals for the film
    CASE 
        WHEN f.rating = 'G' THEN 'All Ages' 
        WHEN f.rating = 'PG' THEN 'ages 10+'
        WHEN f.rating = 'PG-13' THEN 'ages 13+'
        WHEN f.rating = 'R' THEN 'ages 17+'
        WHEN f.rating = 'NC-17' THEN 'Adults Only (ages 17+)'
        ELSE 'Not Rated' 
    END AS expected_age -- Determine expected audience age based on film rating
FROM 
    film AS f
INNER JOIN 
    inventory AS i ON i.film_id = f.film_id -- Join inventory to link films to rentals
INNER JOIN 
    rental AS r ON r.inventory_id = i.inventory_id -- Join rental to get rental counts
GROUP BY 
    f.film_id, f.title, f.rating -- Group results by film to aggregate rental counts
ORDER BY 
    rental_count DESC -- Sort results by rental count in descending order
LIMIT 5; -- Limit to the top 5 rented movies


-- Solution 2: Using Common Table Expressions (CTEs)
-- This solution uses a CTE to first calculate rental counts before selecting and determining expected audience age.
WITH RentalCounts AS (
    SELECT 
        f.film_id, -- Unique identifier for the film
        f.title, -- Title of the film
        COUNT(r.rental_id) AS rental_count, -- Count of rentals for the film
        f.rating -- Film rating for age categorization
    FROM 
        film AS f
    INNER JOIN 
        inventory AS i ON i.film_id = f.film_id -- Join inventory
    INNER JOIN 
        rental AS r ON r.inventory_id = i.inventory_id -- Join rental
    GROUP BY 
        f.film_id, f.title, f.rating -- Group results to aggregate rental counts
)
SELECT 
    film_id, -- Unique identifier for the film
    title, -- Title of the film
    rental_count, -- Count of rentals for the film
    CASE 
        WHEN rating = 'G' THEN 'All Ages' 
        WHEN rating = 'PG' THEN 'ages 10+'
        WHEN rating = 'PG-13' THEN 'ages 13+'
        WHEN rating = 'R' THEN 'ages 17+'
        WHEN rating = 'NC-17' THEN 'Adults Only (ages 17+)'
        ELSE 'Not Rated' 
    END AS expected_age -- Determine expected audience age based on film rating
FROM 
    RentalCounts
ORDER BY 
    rental_count DESC -- Sort results by rental count in descending order
LIMIT 5; -- Limit to the top 5 rented movies


-- Solution 3: Using Subqueries
-- This solution uses a correlated subquery to count rentals for each film while determining expected audience age.
SELECT 
    f.film_id, -- Unique identifier for the film
    f.title, -- Title of the film
    (SELECT COUNT(r.rental_id) 
     FROM rental AS r
     JOIN inventory AS i ON r.inventory_id = i.inventory_id -- Join to link rentals to inventory
     WHERE i.film_id = f.film_id) AS rental_count, -- Count of rentals for the film
    CASE 
        WHEN f.rating = 'G' THEN 'All Ages' 
        WHEN f.rating = 'PG' THEN 'ages 10+'
        WHEN f.rating = 'PG-13' THEN 'ages 13+'
        WHEN f.rating = 'R' THEN 'ages 17+'
        WHEN f.rating = 'NC-17' THEN 'Adults Only (ages 17+)'
        ELSE 'Not Rated' 
    END AS expected_age -- Determine expected audience age based on film rating
FROM 
    film AS f
ORDER BY 
    rental_count DESC -- Sort results by rental count in descending order
LIMIT 5; -- Limit to the top 5 rented movies


-- -- -- -- -- -- TASK 3-- -- -- -- -- --

-- Task: Find actors/actresses with the shortest gap in acting roles based on the latest release year of their films.
-- Business Logic Interpretation:
-- 1. Calculate the gap between the latest release year of films for each actor and the current year.
-- 2. Sort results by the gap in ascending order to identify actors with the shortest gap since their last role.
-- V1: gap between the latest release_year and current year per each actor;
-- Solution: Using standard JOINs with aggregation

SELECT 
    a.actor_id, -- Unique identifier for the actor
    a.first_name || ' ' || a.last_name AS actor_name, -- Full name of the actor
    MAX(f.release_year) AS latest_release_year, -- Most recent release year of the actor's films
    EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year) AS gap_years -- Gap between the latest release year and the current year
FROM 
    actor AS a
INNER JOIN 
    film_actor AS fa ON fa.actor_id = a.actor_id -- INNER JOIN to link actors with their films
INNER JOIN 
    film AS f ON f.film_id = fa.film_id -- INNER JOIN to retrieve film details
GROUP BY 
    a.actor_id, a.first_name, a.last_name -- Group by actor to get latest release year for each
ORDER BY 
    gap_years ASC; -- Sort results by gap in ascending order to highlight actors with recent roles


-- V2: gaps between sequential films per each actor;
-- Solution 1: Using standard JOINs with sequential comparison
SELECT 
    a.actor_id,
    a.first_name || ' ' || a.last_name AS actor_name, -- Concatenate first and last name
    f1.release_year AS previous_film_year,            -- Release year of the earlier film
    f2.release_year AS next_film_year,                -- Release year of the subsequent film
    f2.release_year - f1.release_year AS gap_years    -- Calculate gap in years
FROM 
    actor AS a
INNER JOIN 
    film_actor AS fa1 ON fa1.actor_id = a.actor_id
INNER JOIN 
    film AS f1 ON f1.film_id = fa1.film_id
INNER JOIN 
    film_actor AS fa2 ON fa2.actor_id = a.actor_id
INNER JOIN 
    film AS f2 ON f2.film_id = fa2.film_id
WHERE 
    f1.release_year < f2.release_year                -- Ensure f2 is a subsequent film of f1
ORDER BY 
    gap_years DESC;                                  -- Order by the longest gaps

-- Solution 2: Using Common Table Expressions (CTEs)
WITH FilmGaps AS (
    SELECT 
        a.actor_id,
        a.first_name || ' ' || a.last_name AS actor_name,
        f.release_year,
        ROW_NUMBER() OVER (PARTITION BY a.actor_id ORDER BY f.release_year) AS film_order -- Sequential numbering for ordering by release year
    FROM 
        actor AS a
    INNER JOIN 
        film_actor AS fa ON fa.actor_id = a.actor_id
    INNER JOIN 
        film AS f ON f.film_id = fa.film_id
)
SELECT 
    fg1.actor_id,
    fg1.actor_name,
    fg1.release_year AS previous_film_year,          -- Year of the earlier film
    fg2.release_year AS next_film_year,              -- Year of the next film
    fg2.release_year - fg1.release_year AS gap_years -- Calculate gap between sequential films
FROM 
    FilmGaps fg1
INNER JOIN 
    FilmGaps fg2 ON fg1.actor_id = fg2.actor_id 
               AND fg1.film_order + 1 = fg2.film_order -- Join sequential films for each actor
ORDER BY 
    gap_years DESC;                                  -- Sort by the largest gap in descending order

-- Solution 3: Using Subqueries to find sequential film gaps
SELECT 
    a.actor_id,
    a.first_name || ' ' || a.last_name AS actor_name,
    f1.release_year AS previous_film_year,           -- Year of the earlier film
    f2.release_year AS next_film_year,               -- Year of the next film
    f2.release_year - f1.release_year AS gap_years   -- Calculate the gap between films
FROM 
    actor AS a
INNER JOIN 
    film_actor AS fa1 ON fa1.actor_id = a.actor_id
INNER JOIN 
    film AS f1 ON f1.film_id = fa1.film_id
INNER JOIN 
    film_actor AS fa2 ON fa2.actor_id = a.actor_id
INNER JOIN 
    film AS f2 ON f2.film_id = fa2.film_id
WHERE 
    f1.release_year < f2.release_year                -- Only consider subsequent films
    AND f2.release_year = (
        SELECT MIN(f3.release_year) 
        FROM film f3
        INNER JOIN film_actor fa3 ON fa3.film_id = f3.film_id
        WHERE fa3.actor_id = a.actor_id 
          AND f3.release_year > f1.release_year      -- Find the next closest release year
    )
ORDER BY 
    gap_years DESC;                                  -- Order by the longest gap first


-- Solution 2 (Using CTEs with sequential row numbering) is best because it’s clear, efficient, and flexible. 
-- It organizes films in order, making it easy to calculate gaps without complex joins or subqueries, 
-- which improves readability and performance.


