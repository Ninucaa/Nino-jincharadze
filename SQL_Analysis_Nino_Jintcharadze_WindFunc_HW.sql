-- Task 1: Calculate total sales per channel and customer sales with sales percentage

WITH TotalSales AS (
    -- Calculate total sales per channel
    SELECT 
        channel_id,
        SUM(amount_sold) AS total_sales
    FROM 
        sh.sales
    GROUP BY 
        channel_id  -- Group by channel to get total sales for each channel
),
CustomerSales AS (
    -- Calculate total sales for each customer per channel
    SELECT 
        s.channel_id,
        c.cust_last_name,
        c.cust_first_name,
        SUM(s.amount_sold) AS amount_sold
    FROM 
        sh.sales s
    JOIN 
        sh.customers c ON s.cust_id = c.cust_id 
    GROUP BY 
        s.channel_id, c.cust_last_name, c.cust_first_name  
)
SELECT 
    cs.channel_id,
    cs.cust_last_name,
    cs.cust_first_name,
    ROUND(cs.amount_sold, 2) AS amount_sold,  -- Round the sales amount to 2 decimal places
    CONCAT(ROUND((cs.amount_sold / ts.total_sales) * 100, 5), ' %') AS sales_percentage  -- Calculate sales percentage
FROM 
    CustomerSales cs
JOIN 
    TotalSales ts ON cs.channel_id = ts.channel_id  -- Join to get total sales by channel
ORDER BY 
    cs.channel_id, cs.amount_sold DESC  -- Order by channel and sales amount
LIMIT 5;  -- Limit the results to the top 5 customers per channel

-- Task 2: Generate quarterly sales report for products in 2000 using crosstab

CREATE EXTENSION IF NOT EXISTS tablefunc;  -- Enable tablefunc extension for crosstab functionality

WITH SalesData AS (
    -- Gather total sales for each product by quarter
    SELECT 
        p.prod_name,
        SUM(s.amount_sold) AS total_sales,
        EXTRACT(QUARTER FROM t.time_id) AS quarter  -- Extract quarter from time_id
    FROM 
        sh.sales s
    JOIN 
        sh.products p ON s.prod_id = p.prod_id  
    JOIN 
        sh.times t ON s.time_id = t.time_id  
    WHERE 
        t.calendar_year = 2000  
    GROUP BY 
        p.prod_name, quarter  
)
SELECT 
    prod_name,
    COALESCE(SUM(CASE WHEN quarter = 1 THEN total_sales END), 0) AS q1,  -- Total sales for Q1
    COALESCE(SUM(CASE WHEN quarter = 2 THEN total_sales END), 0) AS q2,  -- Total sales for Q2
    COALESCE(SUM(CASE WHEN quarter = 3 THEN total_sales END), 0) AS q3,  -- Total sales for Q3
    COALESCE(SUM(CASE WHEN quarter = 4 THEN total_sales END), 0) AS q4,  -- Total sales for Q4
    COALESCE(SUM(total_sales), 0) AS year_sum  -- Total sales for the year
FROM 
    SalesData
GROUP BY 
    prod_name  -- Group by product name to display results
ORDER BY 
    year_sum DESC;  

-- Task 3: Rank customers based on total sales for specific years

WITH RankedCustomers AS (
    -- Calculate total sales per customer and rank them
    SELECT 
        c.cust_id,  
        c.cust_last_name,
        c.cust_first_name,
        SUM(s.amount_sold) AS total_sales,
        RANK() OVER (ORDER BY SUM(s.amount_sold) DESC) AS sales_rank  -- Rank customers by total sales
    FROM 
        sh.sales s
    JOIN 
        sh.customers c ON s.cust_id = c.cust_id  
    WHERE 
        EXTRACT(YEAR FROM s.time_id) IN (1998, 1999, 2001) 
    GROUP BY 
        c.cust_id, c.cust_last_name, c.cust_first_name  -- Group by customer ID and names
)
SELECT 
    cust_id,
    cust_last_name,
    cust_first_name,
    ROUND(total_sales, 2) AS amount_sold  -- Round total sales to 2 decimal places
FROM 
    RankedCustomers
WHERE 
    sales_rank <= 300; 

-- Task 4: Summarize product sales by year and month for specific channels

SELECT 
    EXTRACT(YEAR FROM t.time_id) AS year,  -- Extract year from time_id
    EXTRACT(MONTH FROM t.time_id) AS month,  -- Extract month from time_id
    p.prod_category,
    SUM(CASE WHEN s.channel_id = 1 THEN s.amount_sold ELSE 0 END) AS Americas_SALES,  -- Total sales for Americas
    SUM(CASE WHEN s.channel_id = 2 THEN s.amount_sold ELSE 0 END) AS Europe_SALES  -- Total sales for Europe
FROM 
    sh.sales s
JOIN 
    sh.products p ON s.prod_id = p.prod_id 
JOIN 
    sh.times t ON s.time_id = t.time_id  
WHERE 
    t.time_id BETWEEN '2000-01-01' AND '2000-03-31'  -- Filter for the first quarter of 2000
GROUP BY 
    year, month, p.prod_category  
ORDER BY 
    year, month, p.prod_category; 