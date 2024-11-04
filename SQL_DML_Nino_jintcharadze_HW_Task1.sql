--1.Choose your top-3 favorite movies and add them to the 'film' table 
--(films with the title Film1, Film2, etc - will not be taken into account and grade will be reduced)
-- Little Women, Frances Ha, La La Land
-- English language_id = 1
BEGIN;

INSERT INTO film (title, language_id)
VALUES ('Little Women',1), ('Frances Ha',1), ('La La Land',1)
RETURNING *;
COMMIT;

SELECT * FROM film
ORDER by film_id desc
--2.Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.
-- 'little Women' film_id = 1001,  'Frances Ha' film_id = 1002, 'La La Land' film_id = 1003

--Littlw Women
UPDATE film 
SET rental_duration = 7, rental_rate = 4.99
WHERE film_id = 1001
RETURNING *;


--Frances Ha
UPDATE film 
SET rental_duration = 14, rental_rate = 9.99
WHERE film_id = 1002
RETURNING *;

--La La Land
UPDATE film 
SET rental_duration = 21, rental_rate = 19.99
WHERE film_id = 1003
RETURNING *;
COMMIT;
-- 3.Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).  
-- Actors with the name Actor1, Actor2, etc - will not be taken into account and grade will be reduced.

-- film_id = 1001 (Little Women)
-- actor_id = 201 (Saoirse Ronan),202(Florence Pugh),203(Timothée Chalamet),204(Emma Watson),205(Eliza Scanlen),206(Meryl streep)
BEGIN;
INSERT INTO actor (first_name, last_name)
VALUES ('Saoirse', 'Ronan'), ('Florence', 'Pugh'), ('Timothée','Chalamet'), ('Emma', 'Watson'),
	('Eliza', 'Scanlen'), ('Meryl', 'Streep')
RETURNING*;


INSERT INTO film_actor(actor_id, film_id)
VALUES(201,1001), (202, 1001), (203, 1001), (204, 1001), (205, 1001), (206, 1001)
RETURNING *;
COMMIT;


--film_id = 1002 (Frances Ha)
--actor_id = (207, 208, 209, 210, 211, 212)

INSERT INTO actor (first_name, last_name)
VALUES('Greta','Gerwig'), ('Mickey','Sumner'), ('Adam','Driver'), ('Michael','Zegen'), ('Grace','Gummer'), ('Michael','Esper')
RETURNING*;


INSERT INTO film_actor(actor_id, film_id)
VALUES(207,1002), (208, 1002), (209, 1002), (210, 1002), (211, 1002), (212, 1002)
RETURNING *;
COMMIT;


--film_id = 2003(La La Land)
--actor_id = (213,214,215,216,217,218)
INSERT INTO actor(first_name, last_name)
VALUES('Emma', 'Stone'), ('Ryan', 'Gosling'), ('John', 'Legend'), ('J. K.', 'Simmons'), ('Sonoya', 'Mizuno'), ('Finn', 'Wittrock')
RETURNING *;


INSERT INTO film_actor(actor_id, film_id)
VALUES(213,1003), (214, 1003), (215, 1003), (216, 1003), (217, 1003), (218, 1003)
RETURNING *;
COMMIT;

--Note: here it should be Many-to-Many relationship, it is possible that one actor can be in several movies and several actors can be in one move,
--but in film_actor table there is only this scenario where one actor can be in several moves. 
--I can't mach with this logic, I hope I will not mess it up with mine.

--4.Add your favorite movies to any store's inventory.
INSERT INTO inventory (film_id, store_id)
VALUES(1001,2),(1002,2),(1003,2)
RETURNING *;
COMMIT;

--5. Alter any existing customer in the database with at least 43 rental and 43 payment records. 
--Change their personal data to yours (first name, last name, address, etc.). 
--You can use any existing address from the "address" table. Please do not perform any updates on the "address" table, 
--as this can impact multiple records with the same address.

SELECT cust.customer_id
FROM customer cust
JOIN rental r ON cust.customer_id = r.customer_id
JOIN payment pay ON pay.customer_id = cust.customer_id
GROUP BY cust.customer_id
HAVING COUNT(r.rental_id) >= 43 AND COUNT(pay.payment_id) >= 43
LIMIT 1;


--MARY SMITH
UPDATE customer
SET first_name = 'Nino', last_name = 'Jintcharadze', email = 'Nino.Jintcharadze@sakilacustomer.org'
WHERE customer_id = 1
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

