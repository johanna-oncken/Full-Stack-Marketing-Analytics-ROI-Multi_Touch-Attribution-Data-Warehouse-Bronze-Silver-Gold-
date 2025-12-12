/*
===============================================================================
Measures Exploration (Key Metrics)
===============================================================================
Purpose:
    - To calculate aggregated metrics (e.g., totals, averages) for quick insights.
    - To identify overall trends or spot anomalies.

SQL Functions Used:
    - COUNT(), SUM(), AVG()

Queries 
    1) Total Ad Spend
    2) Average Ad Spend
    3) Total Number of Clicks
    4) Average Clicks per Calendar Day
    5) Total Number of Sessions and Number of Users
    6) Total Number of Tochpoints and Number of Users
    7) Total Revenue, Number of Purchases and Number of Customers
    8) Number of One-Time Customers 
    9) Number of Multi-Time Customers 
    10) Total Number of Touchpoints contributing to a purchase 
    11) Average Touchpoint Position in Funnel 
    12) Number of Attributed Touchpoints 
    13) Average Touchpath Lengts (derived from attribution_linear)
    14) Number of Users in the Attribution Model 
    15) Average Size of Revenue Share by Touchpoint 
    16) Average Revenue by Purchase 
    17) Average of Revenue attributed by Last Touch 
    18) Average of Touchpath Lengths (derived from attribution_last_touch)
    --
    19) Report Table
===============================================================================
*/
USE marketing_dw;
GO
/*
    💡 SCROLL DOWN FOR REPORT TABLE
*/


-- 1) Find the total ad spend
SELECT SUM(spend) AS total_ad_spend FROM gold.fact_spend;

-- 2) Find the average ad spend
SELECT AVG(spend) AS avg_ad_spend FROM gold.fact_spend;

-- 3) Find total number of clicks
SELECT COUNT(click_id) AS total_clicks FROM gold.fact_clicks;

-- 4) Find the average click count per calendar day
SELECT COUNT(*) * 1.0 / (DATEDIFF(DAY, MIN(CAST(click_timestamp AS DATE)), MAX(CAST(click_timestamp AS DATE))) + 1) AS avg_clicks_per_day
FROM gold.fact_clicks;


/*
“In the raw Bronze tables (e.g. touchpoints, sessions, purchases), user_id was frequently missing because users interact anonymously. During the Silver → Gold ETL process, user identifiers were resolved. The resulting Gold fact tables therefore reflect high-quality, identity-based data.” */

    -- 5) Find the total number of valid sessions and the total of unique visitors 
    SELECT COUNT(*) AS started_sessions,
        COUNT(DISTINCT user_id) AS unique_visitors
    FROM gold.fact_sessions;

    -- 6) Find the total number of valid touchpoints and the total of associated users
    SELECT COUNT(*) AS total_touchpoints,
        COUNT(DISTINCT user_id) AS unique_users
    FROM gold.fact_touchpoints;

    -- 7) Find the total revenue, number of valid purchases and number of users who purchased as such (multiple purchases possible)
    SELECT SUM(revenue) AS total_revenue,
        COUNT(*) AS total_purchases,
        COUNT(DISTINCT user_id) AS users_who_purchased
    FROM gold.fact_purchases;

    -- 8) Find number of one-time customers 
    -- 2338
    SELECT COUNT(user_id) AS one_time_customers
    FROM
    (SELECT 
        user_id 
    FROM gold.fact_purchases 
    GROUP BY user_id 
    HAVING COUNT(purchase_id) = 1) t; 

    -- 9) Find number of multi_time customers
    -- 552
    SELECT COUNT(user_id) AS multi_time_customers
    FROM
    (SELECT 
        user_id 
    FROM gold.fact_purchases 
    GROUP BY user_id 
    HAVING COUNT(purchase_id) > 1) t;
 

-- 10) Find the total of touchpoints contributing to a purchase
SELECT COUNT(purchase_id) AS total_contributing_touchpoints
FROM gold.fact_touchpath;

-- 11) Find the average position in funnel touchpath (position of all touchpoints: avg per touchpoint)
SELECT AVG(touchpoint_number) AS avg_funnel_position
FROM gold.fact_touchpath
WHERE purchase_id IS NOT NULL; 

-- 12) Find the number of attributed touchpoints
SELECT COUNT(*) AS total_attributed_touchpoints FROM gold.fact_attribution_linear;

-- 13) Find the average of touchpath lenghts 
SELECT 
    AVG(touchpoints_in_path) AS avg_touchpath_length
FROM (
SELECT 
    distinct purchase_id,
    touchpoints_in_path 
FROM gold.fact_attribution_linear )t;

-- 14) Find unique number of users in the attribution model (purchases with touchpoints)
--     2160
SELECT COUNT(DISTINCT user_id) AS customers_with_touchpoints FROM gold.fact_attribution_linear; 

-- 15) Find the average size of revenue_share by touchpoint
SELECT 
    AVG(revenue_share) AS avg_revenue_share
FROM gold.fact_attribution_linear;

-- 16) Find average revenue by purchase
SELECT AVG(total_revenue) AS avg_revenue_per_purchase
FROM (
SELECT 
    distinct purchase_id,
    total_revenue 
FROM gold.fact_attribution_linear)t;

-- 17) Find average of revenue attributed to last touch 
SELECT 
    AVG(revenue) AS avg_revenue_by_last_touch 
FROM gold.fact_attribution_last_touch;

-- 18) Find the average of touchpath lengths 
SELECT 
    AVG(touchpoint_number) AS avg_touchpath_length
FROM gold.fact_attribution_last_touch;


/*
================================================================================
19) Report Table 
    ------------
    Generate a report that shows all key metrics of the business
================================================================================
*/

SELECT 'Total Ad Spend' AS measure_name, SUM(spend) AS measure_value FROM gold.fact_spend
UNION ALL
SELECT 'Average Ad Spend', AVG(spend) FROM gold.fact_spend
UNION ALL
SELECT 'Total Clicks', COUNT(click_id) FROM gold.fact_clicks
UNION ALL 
SELECT 'Avg Clicks per Calendar Day', COUNT(*) * 1.0 / (DATEDIFF(DAY, MIN(CAST(click_timestamp AS DATE)), MAX(CAST(click_timestamp AS DATE))) + 1) FROM gold.fact_clicks
UNION ALL 
SELECT 'Total Valid Sessions', COUNT(*) FROM gold.fact_sessions
UNION ALL
SELECT 'Unique Visitors', COUNT(DISTINCT user_id) FROM gold.fact_sessions 
UNION ALL 
SELECT 'Total Revenue (Identity Based)', SUM(revenue) FROM gold.fact_purchases 
UNION ALL 
SELECT 'Total Purchases', COUNT(*) FROM gold.fact_purchases 
UNION ALL 
SELECT 'Users Who Purchased', COUNT(DISTINCT user_id) FROM gold.fact_purchases 
UNION ALL 
SELECT 'One-time Customers', COUNT(user_id) FROM
    (SELECT 
        user_id 
    FROM gold.fact_purchases 
    GROUP BY user_id 
    HAVING COUNT(purchase_id) = 1)t
UNION ALL 
SELECT 'Multi-time Customers', COUNT(user_id) FROM
    (SELECT 
        user_id 
    FROM gold.fact_purchases 
    GROUP BY user_id 
    HAVING COUNT(purchase_id) > 1)t 
UNION ALL 
SELECT 'Total Touchpoints', COUNT(*) FROM gold.fact_touchpoints 
UNION ALL 
SELECT 'Unique Users Touched', COUNT(DISTINCT user_id) FROM gold.fact_touchpoints
UNION ALL
SELECT 'Total Contributing Touchpoints', COUNT(purchase_id) FROM gold.fact_touchpath 
UNION ALL 
SELECT 'Average Tp Funnel Position', AVG(touchpoint_number) FROM gold.fact_touchpath WHERE purchase_id IS NOT NULL
UNION ALL
SELECT 'Total Attributed Touchpoints', COUNT(*) FROM gold.fact_attribution_linear
UNION ALL 
SELECT 'Customers With Touchpoints', COUNT(DISTINCT user_id)  FROM gold.fact_attribution_linear
UNION ALL
SELECT 'Avg Revenue Share by Tp', AVG(revenue_share) FROM gold.fact_attribution_linear 
UNION ALL 
SELECT 'Avg Revenue Per Purchase', AVG(total_revenue) FROM (
    SELECT 
        distinct purchase_id, 
        total_revenue 
    FROM gold.fact_attribution_linear)t 
UNION ALL 
SELECT 'Avg Revenue By Last Touch', AVG(revenue) FROM gold.fact_attribution_last_touch 
UNION ALL 
SELECT 'Average Touchpoint Length', AVG(touchpoint_number) FROM gold.fact_attribution_last_touch;



