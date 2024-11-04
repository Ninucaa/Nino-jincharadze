--1.Choose your top-3 favorite movies and add them to the 'film' table 
--(films with the title Film1, Film2, etc - will not be taken into account and grade will be reduced)
-- Little Women, Frances Ha, La La Land
-- English language_id = 1
BEGIN;

INSERT INTO film (title, language_id)
VALUES ('Little Women',(SELECT language_id FROM language WHERE name = 'English')), 
		('Frances Ha',(SELECT language_id FROM language WHERE name = 'English')), 
		('La La Land',(SELECT language_id FROM language WHERE name = 'English'))
RETURNING *;
COMMIT;

--2.Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.
-- 'little Women' film_id = 1001,  'Frances Ha' film_id = 1002, 'La La Land' film_id = 1003

--Littlw Women
UPDATE film 
SET rental_duration = 7, rental_rate = 4.99
WHERE film_id = (SELECT film_id FROM film WHERE title = 'Little Women')
RETURNING *;


--Frances Ha
UPDATE film 
SET rental_duration = 14, rental_rate = 9.99
WHERE film_id = (SELECT film_id FROM film WHERE title = 'Frances Ha')
RETURNING *;

--La La Land
UPDATE film 
SET rental_duration = 21, rental_rate = 19.99
WHERE film_id = (SELECT film_id FROM film WHERE title = 'La La Land')
RETURNING *;
COMMIT;
-- 3.Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).  
-- Actors with the name Actor1, Actor2, etc - will not be taken into account and grade will be reduced.

-- (Little Women)
BEGIN;
INSERT INTO actor (first_name, last_name)
VALUES ('Saoirse', 'Ronan'), ('Florence', 'Pugh'), ('Timothée','Chalamet'), ('Emma', 'Watson'),
	('Eliza', 'Scanlen'), ('Meryl', 'Streep')
RETURNING*;


INSERT INTO film_actor(actor_id, film_id)
VALUES
	((SELECT actor_id FROM actor WHERE first_name = 'Saoirse' AND last_name = 'Ronan'), (SELECT film_id FROM film WHERE title = 'Little Women')),
    ((SELECT actor_id FROM actor WHERE first_name = 'Florence' AND last_name = 'Pugh'), (SELECT film_id FROM film WHERE title = 'Little Women')),
    ((SELECT actor_id FROM actor WHERE first_name = 'Timothée' AND last_name = 'Chalamet'), (SELECT film_id FROM film WHERE title = 'Little Women')),
    ((SELECT actor_id FROM actor WHERE first_name = 'Emma' AND last_name = 'Watson'), (SELECT film_id FROM film WHERE title = 'Little Women')),
    ((SELECT actor_id FROM actor WHERE first_name = 'Eliza' AND last_name = 'Scanlen'), (SELECT film_id FROM film WHERE title = 'Little Women')),
    ((SELECT actor_id FROM actor WHERE first_name = 'Meryl' AND last_name = 'Streep'), (SELECT film_id FROM film WHERE title = 'Little Women'))
RETURNING *;
COMMIT;


--(Frances Ha)

INSERT INTO actor (first_name, last_name)
VALUES('Greta','Gerwig'), ('Mickey','Sumner'), ('Adam','Driver'), ('Michael','Zegen'), ('Grace','Gummer'), ('Michael','Esper')
RETURNING*;


INSERT INTO film_actor(actor_id, film_id)
VALUES
	((SELECT actor_id FROM actor WHERE first_name = 'Greta' AND last_name = 'Gerwig'), (SELECT film_id FROM film WHERE title = 'Frances Ha')),
    ((SELECT actor_id FROM actor WHERE first_name = 'Mickey' AND last_name = 'Sumner'), (SELECT film_id FROM film WHERE title = 'Frances Ha')),
    ((SELECT actor_id FROM actor WHERE first_name = 'Adam' AND last_name = 'Driver'), (SELECT film_id FROM film WHERE title = 'Frances Ha')),
    ((SELECT actor_id FROM actor WHERE first_name = 'Michael' AND last_name = 'Zegen'), (SELECT film_id FROM film WHERE title = 'Frances Ha')),
    ((SELECT actor_id FROM actor WHERE first_name = 'Grace' AND last_name = 'Gummer'), (SELECT film_id FROM film WHERE title = 'Frances Ha')),
    ((SELECT actor_id FROM actor WHERE first_name = 'Michael' AND last_name = 'Esper'), (SELECT film_id FROM film WHERE title = 'Frances Ha'))
RETURNING *;
COMMIT;


--(La La Land)

INSERT INTO actor(first_name, last_name)
VALUES('Emma', 'Stone'), ('Ryan', 'Gosling'), ('John', 'Legend'), ('J. K.', 'Simmons'), ('Sonoya', 'Mizuno'), ('Finn', 'Wittrock')
RETURNING *;


INSERT INTO film_actor(actor_id, film_id)
VALUES
	((SELECT actor_id FROM actor WHERE first_name = 'Emma' AND last_name = 'Stone'), (SELECT film_id FROM film WHERE title = 'La La Land')),
    ((SELECT actor_id FROM actor WHERE first_name = 'Ryan' AND last_name = 'Gosling'), (SELECT film_id FROM film WHERE title = 'La La Land')),
    ((SELECT actor_id FROM actor WHERE first_name = 'John' AND last_name = 'Legend'), (SELECT film_id FROM film WHERE title = 'La La Land')),
    ((SELECT actor_id FROM actor WHERE first_name = 'J. K.' AND last_name = 'Simmons'), (SELECT film_id FROM film WHERE title = 'La La Land')),
    ((SELECT actor_id FROM actor WHERE first_name = 'Sonoya' AND last_name = 'Mizuno'), (SELECT film_id FROM film WHERE title = 'La La Land')),
    ((SELECT actor_id FROM actor WHERE first_name = 'Finn' AND last_name = 'Wittrock'), (SELECT film_id FROM film WHERE title = 'La La Land'))
RETURNING *;
RETURNING *;
COMMIT;

--Note: here it should be Many-to-Many relationship, it is possible that one actor can be in several movies and several actors can be in one move,
--but in film_actor table there is only this scenario where one actor can be in several moves. 
--I can't mach with this logic, I hope I will not mess it up with mine.

--4.Add your favorite movies to any store's inventory.
INSERT INTO inventory (film_id, store_id)
VALUES
	((SELECT film_id FROM film WHERE title = 'Little Women'), 2),
    ((SELECT film_id FROM film WHERE title = 'Frances Ha'), 2),
    ((SELECT film_id FROM film WHERE title = 'La La Land'), 2)
RETURNING *;
COMMIT;

--5. Alter any existing customer in the database with at least 43 rental and 43 payment records. 
--Change their personal data to yours (first name, last name, address, etc.). 
--You can use any existing address from the "address" table. Please do not perform any updates on the "address" table, 
--as this can impact multiple records with the same address.

UPDATE customer
SET first_name = 'Nino', last_name = 'Jintcharadze', email = 'Nino.Jintcharadze@sakilacustomer.org'
WHERE customer_id = (
	SELECT cust.customer_id
	FROM customer cust
	JOIN rental r ON cust.customer_id = r.customer_id
	JOIN payment pay ON pay.customer_id = cust.customer_id
	GROUP BY cust.customer_id
	HAVING COUNT(r.rental_id) >= 43 AND COUNT(pay.payment_id) >= 43
	LIMIT 1
)
RETURNING *;
COMMIT;

--Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'.
--My customer_id =1
DELETE FROM payment WHERE customer_id = 1;
DELETE FROM rental WHERE customer_id = 1;

--Rent you favorite movies from the store they are in and pay for them 
--(add corresponding records to the database to represent this activity)


--inventory_id = (4582, 4583, 4584)

INSERT INTO rental(customer_id, inventory_id, rental_date, return_date, staff_id)
VALUES(1, 4582, CURRENT_DATE, CURRENT_DATE + 7, 1),  
    (1, 4583, CURRENT_DATE, CURRENT_DATE + 14, 1),
    (1, 4584, CURRENT_DATE, CURRENT_DATE + 21, 1)
RETURNING rental_id;

COMMIT;

-- rental_id =(32295, 32296, 32297)
BEGIN;


CREATE TABLE payment_for_my_favorite_movies PARTITION OF payment
FOR VALUES FROM ('2024-11-04') TO ('2024-11-25');



INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
VALUES
    (1, 1, 32295, 4.99, CURRENT_DATE),  -- Payment for Little Women
    (1, 1, 32296, 9.99, CURRENT_DATE),  -- Payment for Frances Ha
    (1, 1, 32297, 19.99, CURRENT_DATE); -- Payment for La La Land

COMMIT;

-- I really strugle with this one, Itried to create view but doesn't work, I fugure that without a partition covering the payment_date
-- won’t know where to place the row with this date, and this was cousing a error.
--partition allows database to correctly rout the data in the appropriate location.
--end then I saw Tasks note 🤦‍♀️

