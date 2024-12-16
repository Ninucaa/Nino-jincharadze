-- Task 1: Calculate total sales per channel and customer sales with sales percentage using Window Functions
WITH CustomerSales AS (
    SELECT 
        s.channel_id,
        c.cust_last_name,
        c.cust_first_name,
        SUM(s.amount_sold) AS amount_sold,
        SUM(SUM(s.amount_sold)) OVER (PARTITION BY s.channel_id) AS total_sales_per_channel,
        RANK() OVER (PARTITION BY s.channel_id ORDER BY SUM(s.amount_sold) DESC) AS customer_rank
    FROM 
        sh.sales s
    JOIN 
        sh.customers c ON s.cust_id = c.cust_id
    GROUP BY 
        s.channel_id, c.cust_last_name, c.cust_first_name
)
SELECT 
    channel_id,
    cust_last_name,
    cust_first_name,
    ROUND(amount_sold, 2) AS amount_sold,
    CONCAT(ROUND((amount_sold / total_sales_per_channel) * 100, 5), ' %') AS sales_percentage
FROM 
    CustomerSales
WHERE 
    customer_rank <= 5
ORDER BY 
    channel_id,
    amount_sold DESC;

-- Task 2: Generate quarterly sales report for Photo products in the Asian region

CREATE EXTENSION IF NOT EXISTS tablefunc;

WITH SalesData AS (
    SELECT 
        p.prod_name,
        SUM(s.amount_sold) AS total_sales,
        EXTRACT(QUARTER FROM t.time_id) AS quarter
    FROM 
        sh.sales s
    JOIN 
        sh.products p ON s.prod_id = p.prod_id
    JOIN 
        sh.times t ON s.time_id = t.time_id
    WHERE 
        t.calendar_year = 2000
        AND p.prod_category = 'Photo'
        AND s.channel_id = 3
    GROUP BY 
        p.prod_name,
        quarter 
)

SELECT 
    prod_name, 
    COALESCE(SUM(CASE WHEN quarter = 1 THEN total_sales END), 0) AS q1,
    COALESCE(SUM(CASE WHEN quarter = 2 THEN total_sales END), 0) AS q2,
    COALESCE(SUM(CASE WHEN quarter = 3 THEN total_sales END), 0) AS q3,
    COALESCE(SUM(CASE WHEN quarter = 4 THEN total_sales END), 0) AS q4,
    COALESCE(SUM(total_sales), 0) AS year_sum
FROM 
    SalesData 
GROUP BY 
    prod_name 
ORDER BY 
    year_sum DESC; 
    
-- Task 3: Rank customers for each year and select the top customers
WITH RankedCustomers AS (
    SELECT 
        c.cust_id,
        c.cust_last_name,
        c.cust_first_name,
        EXTRACT(YEAR FROM t.time_id) AS sales_year,
        SUM(s.amount_sold) AS total_sales,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM t.time_id) ORDER BY SUM(s.amount_sold) DESC) AS sales_rank
    FROM 
        sh.sales s
    JOIN 
        sh.customers c ON s.cust_id = c.cust_id
    JOIN 
        sh.times t ON s.time_id = t.time_id
    WHERE 
        EXTRACT(YEAR FROM t.time_id) IN (1998, 1999, 2001) 
    GROUP BY 
        c.cust_id, c.cust_last_name, c.cust_first_name, sales_year
),
TopCustomers AS (
    SELECT
        cust_id,
        COUNT(DISTINCT sales_year) AS years_in_top_300
    FROM
        RankedCustomers
    WHERE
        sales_rank <= 300
    GROUP BY
        cust_id
    HAVING
        COUNT(DISTINCT sales_year) = 3  -- customer ranks in the top 300 for all three years
)
SELECT 
    rc.sales_year,
    rc.cust_id,
    rc.cust_last_name,
    rc.cust_first_name,
    ROUND(rc.total_sales, 2) AS amount_sold
FROM 
    RankedCustomers rc
JOIN 
    TopCustomers tc ON rc.cust_id = tc.cust_id
ORDER BY 
    rc.sales_year, rc.sales_rank;
	
-- Task 4: Summarize product sales by year and month for specific channels
SELECT 
    EXTRACT(YEAR FROM t.time_id) AS year,
    EXTRACT(MONTH FROM t.time_id) AS month,
    p.prod_category,
    SUM(CASE WHEN s.channel_id = 3 THEN s.amount_sold ELSE 0 END) AS Asia_SALES,
    SUM(CASE WHEN s.channel_id = 2 THEN s.amount_sold ELSE 0 END) AS Europe_SALES
FROM 
    sh.sales s
JOIN 
    sh.products p ON s.prod_id = p.prod_id
JOIN 
    sh.times t ON s.time_id = t.time_id
WHERE 
    t.time_id BETWEEN '2000-01-01' AND '2000-03-31'
GROUP BY 
    year, month, p.prod_category
ORDER BY 
    year, month, p.prod_category;