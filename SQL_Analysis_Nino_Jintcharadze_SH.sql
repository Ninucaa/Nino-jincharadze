--Task3. 
--Retrieve the total sales amount for each product category for a specific time period

SELECT 
    sh.products.prod_category AS product_category,
    SUM(sh.sales.amount_sold) AS total_sales_amount
FROM 
    sh.sales
JOIN 
    sh.products ON sh.sales.prod_id = sh.products.prod_id
JOIN 
    sh.times ON sh.sales.time_id = sh.times.time_id
WHERE 
    sh.times.calendar_year = 2000
GROUP BY 
    sh.products.prod_category
ORDER BY 
    total_sales_amount DESC;

--Calculate the average sales quantity by region for a particular product

SELECT 
    sh.countries.country_region AS region,
    AVG(sh.sales.quantity_sold) AS average_quantity_sold
FROM 
    sh.sales
JOIN 
    sh.products ON sh.sales.prod_id = sh.products.prod_id
JOIN 
    sh.customers ON sh.sales.cust_id = sh.customers.cust_id
JOIN 
    sh.countries ON sh.customers.country_id = sh.countries.country_id
WHERE 
    sh.products.prod_name = 'Keyboard Wrist Rest'
GROUP BY 
    sh.countries.country_region
ORDER BY 
    average_quantity_sold DESC;

--Find the top five customers with the highest total sales amount
SELECT 
    sh.customers.cust_first_name,
    sh.customers.cust_last_name,
    SUM(sh.sales.amount_sold) AS total_sales_amount
FROM 
    sh.sales
JOIN 
    sh.customers ON sh.sales.cust_id = sh.customers.cust_id
GROUP BY 
    sh.customers.cust_first_name, 
    sh.customers.cust_last_name
ORDER BY 
    total_sales_amount DESC
LIMIT 5;