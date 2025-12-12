/*
===============================================================================
Ranking Analysis
===============================================================================
Purpose:
    - To rank strategy components (e.g., campaigns, channels) based on performance or other metrics.
    - To identify top performers or laggards.

SQL Functions Used:
    - Window Ranking Functions: RANK(), DENSE_RANK(), ROW_NUMBER(), TOP
    - Clauses: GROUP BY, ORDER BY

Queries: 
    1) Top 5 Campaigns by Highest Revenue (Group By)
    2) Top 5 Campaigns by Highest Revenue (Window Function)
    3) Top 5 Spend on Campaigns 
    4) Bottom 5 Campaigns by Revenue Performance 
    5) Top 5 Channels by Highest Revenue 
    6) Top 5 Spend on Channels
    7) Bottom 5 Channels by Revenue 
    8) Top 10 Highest Revenue generating Customers
===============================================================================
*/
USE marketing_dw;
GO 

-- 1) Which 5 campaigns generate the highest revenue
--    Simple ranking
SELECT TOP 5 
    f.campaign_id,
    d.campaign_name,
    SUM(f.revenue_share) AS total_revenue
FROM gold.fact_attribution_linear f
LEFT JOIN gold.dim_campaign d 
ON f.campaign_id = d.campaign_id
GROUP BY f.campaign_id, d.campaign_name 
ORDER BY SUM(f.revenue_share) DESC;
-- 2) Flexible ranking 
SELECT * 
FROM (
    SELECT 
        f.campaign_id,
        d.campaign_name,
        SUM(f.revenue_share) AS total_revenue,
        RANK() OVER(ORDER BY SUM(f.revenue_share) DESC) AS rank 
    FROM gold.fact_attribution_linear f
    LEFT JOIN gold.dim_campaign d 
    ON f.campaign_id = d.campaign_id
    GROUP BY f.campaign_id, d.campaign_name)t 
WHERE rank <= 5;

-- 3) Find top 5 spend on campaigns 
SELECT TOP 5
    f.campaign_id,
    d.campaign_name,
    SUM(f.spend) AS total_spend
FROM gold.fact_spend f
LEFT JOIN gold.dim_campaign d 
ON f.campaign_id = d.campaign_id
GROUP BY f.campaign_id, d.campaign_name 
ORDER BY SUM(spend) DESC; 

-- 4) Find 5 worst performing campaigns by revenue
SELECT TOP 5 
    f.campaign_id,
    d.campaign_name,
    SUM(f.revenue_share) AS total_revenue
FROM gold.fact_attribution_linear f
LEFT JOIN gold.dim_campaign d 
ON f.campaign_id = d.campaign_id
GROUP BY f.campaign_id, d.campaign_name 
ORDER BY SUM(f.revenue_share);


-- 5) Find top 5 performing channels 
SELECT TOP 5 
    channel,
    SUM(revenue_share) AS total_revenue
FROM gold.fact_attribution_linear  
GROUP BY channel
ORDER BY SUM(revenue_share) DESC; 

-- 6) Find top 5 spend on channels 
SELECT TOP 5 
    channel, 
    SUM(spend) AS total_spend 
FROM gold.fact_spend 
GROUP BY channel 
ORDER BY SUM(spend) DESC; 

-- 7) Find top 5 worst performing channels 
SELECT TOP 5 
    channel,
    SUM(revenue_share) AS total_revenue
FROM gold.fact_attribution_linear  
GROUP BY channel
ORDER BY SUM(revenue_share);  

-- 8) Find top 10 customers who have generated the highest revenue
SELECT TOP 10 
    user_id,
    SUM(revenue) AS total_revenue 
FROM gold.fact_attribution_last_touch 
GROUP BY user_id 
ORDER BY SUM(revenue) DESC;

