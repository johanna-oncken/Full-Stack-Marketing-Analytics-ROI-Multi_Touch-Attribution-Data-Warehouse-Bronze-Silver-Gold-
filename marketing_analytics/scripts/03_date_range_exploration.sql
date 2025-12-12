/*
===============================================================================
Date Range Exploration 
===============================================================================
Purpose:
    - To determine the temporal boundaries of key data points.
    - To understand the range of historical data.
    - To show the range of each tables dates within the 4 months dataset time

SQL Functions Used:
    - MIN(), MAX(), DATEDIFF()
===============================================================================
*/
USE marketing_dw;
GO

-- Determine the first and last campaign date and the total duration in months
SELECT 
    MIN(start_date) AS first_campaign_start_date,
    MAX(start_date) AS last_campaign_start_date,
    MAX(end_date) AS last_campaign_end_date,
    (DATEDIFF(MONTH, MIN(start_date), MAX(end_date))+1) AS campaigns_range_months
FROM gold.dim_campaign;

-- Determine the first and last ad spend date and the total duration in months
SELECT
    MIN(spend_date) AS first_spend_date,
    MAX(spend_date) AS last_spend_date,
    (DATEDIFF(MONTH, MIN(spend_date), MAX(spend_date))+1) AS ad_spend_range_months
FROM gold.fact_spend;

-- Determine the first and last click data date and the total duration in months
SELECT
    CAST(MIN(click_timestamp) AS date) AS first_click_date,
    CAST(MAX(click_timestamp) AS date) AS last_click_date,
    (DATEDIFF(MONTH, MIN(click_timestamp), MAX(click_timestamp))+1) AS clicks_range_months
FROM gold.fact_clicks;

-- Determine the first and last session date and the total duration in months
SELECT
    MIN(session_date) AS first_session_date,
    MAX(session_date) AS last_session_date,
    (DATEDIFF(MONTH, MIN(session_date), MAX(session_date))+1) AS sessions_range_months
FROM gold.fact_sessions;

-- Determine the first and last touchpoint date and the total duration in months
SELECT
    MIN(tp_date) AS first_touchpoint_date,
    MAX(tp_date) AS last_touchpoint_date,
    (DATEDIFF(MONTH, MIN(tp_date), MAX(tp_date))+1) AS touchpoints_range_months
FROM gold.fact_touchpoints;

-- Determine the first and last purchase date and the total duration in months
SELECT
    MIN(purchase_date) AS first_purchase_date,
    MAX(purchase_date) AS last_purchase_date,
    (DATEDIFF(MONTH, MIN(purchase_date), MAX(purchase_date))+1) AS purchases_range_months
FROM gold.fact_purchases;




