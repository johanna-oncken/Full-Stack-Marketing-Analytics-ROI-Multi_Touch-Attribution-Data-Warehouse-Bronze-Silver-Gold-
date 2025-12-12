/*
===============================================================================
Change Over Time Analysis
===============================================================================
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
    - To measure growth or decline over specific periods.

SQL Functions Used:
    - Date Functions: DATETRUNC(), FORMAT()
    - Aggregate Functions: SUM(), COUNT(), AVG() 

Queries: 
    1) Revenue Performance over Time (Seperated Columns) 
    2) Revenue Performance over Time (DATETRUNC)
    3) Revenue Performance over Time (FORMAT) 
    4) Revenue Performance Inner Week (Monday to Friday)
    5) Revenue Performance Weekend (Saturday, Sunday)
    6) Ad Spend over Time

===============================================================================
*/
USE marketing_dw; 
GO

-- 1) Analyze revenue performance over time 
SELECT 
    d.year,
    d.month,
    d.month_name,
    SUM(f.revenue) AS total_revenue,
    COUNT(distinct f.purchase_id) AS total_purchases,
    COUNT(distinct f.user_id) AS total_customers 
FROM gold.fact_purchases f 
LEFT JOIN gold.dim_date d 
ON f.date_key = d.date_key 
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

-- 2) DATETRUNC()
SELECT 
    DATETRUNC(month, purchase_date) AS performance_month,
    SUM(f.revenue) AS total_revenue,
    COUNT(distinct f.purchase_id) AS total_purchases,
    COUNT(distinct f.user_id) AS total_customers 
FROM gold.fact_purchases f 
GROUP BY DATETRUNC(month, purchase_date)
ORDER BY DATETRUNC(month, purchase_date);

--3) FORMAT() 
SELECT 
    d.month,
    FORMAT(purchase_date, 'yyyy-MMM') AS performance_month,
    SUM(f.revenue) AS total_revenue,
    COUNT(distinct f.purchase_id) AS total_purchases,
    COUNT(distinct f.user_id) AS total_customers 
FROM gold.fact_purchases f 
LEFT JOIN gold.dim_date d 
ON f.date_key = d.date_key
GROUP BY FORMAT(purchase_date, 'yyyy-MMM'), d.month
ORDER BY d.month;



-- 4) Analyze inner-week revenue performance over time 
SELECT 
    d.year,
    d.month,
    d.month_name,
    SUM(f.revenue) AS total_revenue,
    COUNT(distinct f.purchase_id) AS total_purchases,
    COUNT(distinct f.user_id) AS total_customers 
FROM gold.fact_purchases f 
LEFT JOIN gold.dim_date d 
ON f.date_key = d.date_key 
WHERE d.is_weekend = 0
GROUP BY d.year, d.month, d.month_name 
ORDER BY d.year, d.month;

-- 5) Analyze weekend revenue performance over time 
SELECT 
    d.year,
    d.month,
    d.month_name,
    SUM(f.revenue) AS total_revenue,
    COUNT(distinct f.purchase_id) AS total_purchases,
    COUNT(distinct f.user_id) AS total_customers 
FROM gold.fact_purchases f 
LEFT JOIN gold.dim_date d 
ON f.date_key = d.date_key 
WHERE d.is_weekend = 1
GROUP BY d.year, d.month, d.month_name 
ORDER BY d.year, d.month;

-- 6) Analyse ad spend over time 
SELECT 
    d.year,
    d.month,
    d.month_name,
    SUM(f.spend) AS total_ad_spend
FROM gold.fact_spend f 
LEFT JOIN gold.dim_date d 
ON f.date_key = d.date_key 
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;