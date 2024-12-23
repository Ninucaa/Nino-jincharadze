--Task1:Window Functions
--Generate a report for each channel identifying the regions with the highest quantity of products sold.
WITH ChannelRegionSales AS (
    SELECT ch.channel_desc,c.country_region,
    ROUND(SUM(s.quantity_sold),2) AS total_sales, -- Total products sold in each region, rounded to 2 decimal places
    RANK()OVER(PARTITION BY ch.channel_desc ORDER BY SUM(s.quantity_sold) DESC) AS sales_rank -- Rank regions by total sales for each channel
    FROM sh.sales s
    JOIN sh.channels ch ON s.channel_id=ch.channel_id
    JOIN sh.customers cu ON s.cust_id=cu.cust_id
    JOIN sh.countries c ON cu.country_id=c.country_id
    GROUP BY ch.channel_desc,c.country_region
)
--Filter to include only the regions with the highest sales (rank=1)
SELECT channel_desc,country_region,total_sales
FROM ChannelRegionSales
WHERE sales_rank=1
ORDER BY channel_desc,total_sales DESC;

--Task 2. Window Functions
--Step1:Calculate sales for each subcategory by year
WITH SubcategorySales AS (
    SELECT 
        p.prod_subcategory,
        EXTRACT(YEAR FROM t.time_id) AS sales_year,
        SUM(s.quantity_sold) AS total_sales,
        LAG(SUM(s.quantity_sold)) OVER (
            PARTITION BY p.prod_subcategory ORDER BY EXTRACT(YEAR FROM t.time_id)
        ) AS prev_year_sales--Sales of the previous year for the subcategory
    FROM sh.sales s
    JOIN sh.products p ON s.prod_id=p.prod_id
    JOIN sh.times t ON s.time_id=t.time_id
    WHERE EXTRACT(YEAR FROM t.time_id) BETWEEN 1998 AND 2001
    GROUP BY p.prod_subcategory,EXTRACT(YEAR FROM t.time_id)
)

--Step2:Identify subcategories with consistently higher sales
, ConsistentlyHigherSales AS (
    SELECT prod_subcategory
    FROM SubcategorySales
    WHERE total_sales>prev_year_sales AND prev_year_sales IS NOT NULL--Exclude the first year (1998) as it has no previous year data
    GROUP BY prod_subcategory
    HAVING COUNT(*)=3--Ensure sales are consistently higher for 3 years (1999,2000,2001)
)

--Step3:Output the identified subcategories
SELECT prod_subcategory
FROM ConsistentlyHigherSales;

--Task 3. Window Frames
--Step1: Filter data for specific years, product categories, and distribution channels
WITH FilteredSales AS (
    SELECT t.calendar_year, t.calendar_quarter_desc, p.prod_category,
    SUM(s.amount_sold) AS sales -- Total sales amount for the quarter and category
    FROM sh.sales s
    JOIN sh.products p ON s.prod_id = p.prod_id
    JOIN sh.times t ON s.time_id = t.time_id
    JOIN sh.channels c ON s.channel_id = c.channel_id 
    WHERE t.calendar_year BETWEEN 1999 AND 2000 AND p.prod_category IN ('Electronics', 'Hardware', 'Software/Other') -- Specific product categories
    AND c.channel_desc IN ('Partners', 'Internet') -- Specific channels
    GROUP BY t.calendar_year, t.calendar_quarter_desc, p.prod_category
)

--Step2: Add cumulative sum and percentage difference
, SalesReport AS (
    SELECT calendar_year,calendar_quarter_desc, prod_category,
        ROUND(sales, 2) AS sales$, -- Total sales rounded to 2 decimal places
        CASE
            WHEN ROW_NUMBER() OVER (
                PARTITION BY calendar_year, prod_category ORDER BY calendar_quarter_desc
            ) = 1 THEN 'N/A' -- 'N/A' for the first quarter
            ELSE CONCAT(
                ROUND(
                    ((sales - FIRST_VALUE(sales) OVER (
                        PARTITION BY calendar_year, prod_category ORDER BY calendar_quarter_desc
                    )) / FIRST_VALUE(sales) OVER (
                        PARTITION BY calendar_year, prod_category ORDER BY calendar_quarter_desc
                    )) * 100, 2
                ), '%'
            )
        END AS diff_percent, -- Percentage difference compared to the first quarter
        ROUND(SUM(sales) OVER (
            PARTITION BY calendar_year, prod_category ORDER BY calendar_quarter_desc ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ), 2) AS cum_sum$ -- Cumulative sum of sales
    FROM
        FilteredSales
)

--Step3: Order the results
SELECT
    calendar_year, calendar_quarter_desc, prod_category,sales$,diff_percent, cum_sum$
FROM SalesReport
ORDER BY calendar_year, calendar_quarter_desc, sales$ DESC; 
