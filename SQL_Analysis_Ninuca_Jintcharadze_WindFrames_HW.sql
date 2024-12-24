-- 1. Annual sales analysis by channel and region.
WITH TotalSales AS (
    SELECT co.country_region, t.calendar_year, ch.channel_desc, SUM(s.amount_sold) AS amount_sold
    FROM sh.sales s
    JOIN sh.customers c ON s.cust_id = c.cust_id
    JOIN sh.times t ON s.time_id = t.time_id
    JOIN sh.countries co ON c.country_id = co.country_id
    JOIN sh.channels ch ON s.channel_id = ch.channel_id  
    WHERE t.calendar_year BETWEEN 1998 AND 2001 AND co.country_region IN ('Americas', 'Asia', 'Europe')
    GROUP BY co.country_region, t.calendar_year, ch.channel_desc
),
SalesPercentages AS (
    SELECT country_region, calendar_year, channel_desc, amount_sold,
        ROUND((amount_sold::decimal / SUM(amount_sold) OVER (PARTITION BY country_region, calendar_year) * 100), 2) AS percentage_by_channel
    FROM TotalSales
),
PreviousYearSales AS (
    SELECT country_region, calendar_year, channel_desc, amount_sold, percentage_by_channel,
        LAG(percentage_by_channel) OVER (PARTITION BY country_region, channel_desc ORDER BY calendar_year) AS percentage_previous_period
    FROM SalesPercentages
)

SELECT country_region, calendar_year, channel_desc, ROUND(amount_sold, 2) AS amount_sold, percentage_by_channel,
    COALESCE(percentage_previous_period, 0) AS percentage_previous_period,
    ROUND(percentage_by_channel - COALESCE(percentage_previous_period, 0), 2) AS percent_diff
FROM PreviousYearSales
ORDER BY country_region, calendar_year, channel_desc;

-- 2. Weekly sales report with cumulative and moving average calculations.
WITH WeeklySales AS (
    SELECT EXTRACT(WEEK FROM t.time_id) AS week_number, EXTRACT(YEAR FROM t.time_id) AS sales_year,
        SUM(s.amount_sold) AS total_sales, t.time_id
    FROM sh.sales s
    JOIN sh.times t ON s.time_id = t.time_id
    WHERE EXTRACT(YEAR FROM t.time_id) = 1999 AND EXTRACT(WEEK FROM t.time_id) IN (49, 50, 51)
    GROUP BY week_number, sales_year, t.time_id
),

SalesWithCumulativeSum AS (
    SELECT week_number, sales_year,
        SUM(total_sales) OVER (PARTITION BY sales_year ORDER BY week_number) AS cum_sum,
        time_id, total_sales
    FROM WeeklySales
),

CenteredAvg AS (
    SELECT swc.time_id, swc.week_number, swc.sales_year, swc.total_sales, swc.cum_sum,
        AVG(total_sales) OVER (
            ORDER BY swc.time_id 
            ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
        ) AS centered_3_day_avg
    FROM SalesWithCumulativeSum swc
)

SELECT week_number, sales_year, ROUND(total_sales, 2) AS total_sales,
    ROUND(cum_sum, 2) AS cum_sum, ROUND(centered_3_day_avg, 2) AS centered_3_day_avg
FROM CenteredAvg
WHERE week_number IN (49, 50, 51)
ORDER BY week_number, time_id;

-- 3. Window functions demonstration with frame clauses.
-- 3.1 RANGE
SELECT cust_id, time_id, amount_sold,
    SUM(amount_sold) OVER (
        ORDER BY time_id 
        RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW
    ) AS cum_sales_last_30_days
FROM sh.sales
ORDER BY time_id;

-- 3.2 ROWS
SELECT time_id, amount_sold,
    AVG(amount_sold) OVER (
        ORDER BY time_id 
        ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
    ) AS centered_avg_sales
FROM sh.sales
ORDER BY time_id;

-- 3.3 GROUPS
SELECT time_id, amount_sold,
    SUM(amount_sold) OVER (
        ORDER BY time_id 
        GROUPS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS total_sales_up_to_date,
    RANK() OVER (
        ORDER BY amount_sold DESC 
        GROUPS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS sales_rank
FROM sh.sales
ORDER BY time_id;