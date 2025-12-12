/*
===============================================================================
Path Length Funnel Analysis
===============================================================================
Purpose:
    - To measure the path length of journeys as such, the closing effectivness(path length by last-touch channel/campaign) and funnel nurturing difficulty (path length by acquisition channel/campaign)
    - To track monthly 2024 trends.

SQL Functions Used:
    - AVG() 
    - GROUP BY
    - LEFT JOIN

Queries: 
    1) Path Length by Month 
    2.1) Path Length by Last-Touch Channel (closing effectiveness)
    2.2) Path Length by Acquisition Channel (funnel nurturing) 
    3.1) Path Length by Last-Touch Campaign 
    32.) Path Length by Acquisition Campaign 

===============================================================================
*/
USE marketing_dw; 
GO
/*
===============================================================================
1) Path Length by Month
===============================================================================
*/
SELECT 
    YEAR(purchase_date) AS year,
    MONTH(purchase_date) AS month,
    AVG(touchpoint_number) AS avg_path_length
FROM gold.fact_attribution_last_touch
GROUP BY YEAR(purchase_date), MONTH(purchase_date)
ORDER BY YEAR(purchase_date), MONTH(purchase_date)

/*
===============================================================================
2.1) Path Length by Last-Touch Channel (closing effectiveness)
===============================================================================
*/
SELECT 
    YEAR(purchase_date) AS year,
    MONTH(purchase_date) AS month,
    last_touch_channel,
    AVG(touchpoint_number) AS avg_path_length
FROM gold.fact_attribution_last_touch
GROUP BY YEAR(purchase_date), MONTH(purchase_date), last_touch_channel
ORDER BY last_touch_channel, YEAR(purchase_date), MONTH(purchase_date)

/*
===============================================================================
2.2) Path Length by Aquisition Channel (funnel nurturing difficulty)
===============================================================================
*/
SELECT 
    YEAR(f.purchase_date) AS year,
    MONTH(f.purchase_date) AS month,
    p.acquisition_channel,
    AVG(touchpoint_number) AS avg_path_length
FROM gold.fact_attribution_last_touch f
LEFT JOIN gold.fact_purchases p
ON f.purchase_id = p.purchase_id
WHERE p.acquisition_channel IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), p.acquisition_channel
ORDER BY p.acquisition_channel, YEAR(f.purchase_date), MONTH(f.purchase_date)

/*
===============================================================================
3.1) Path Length by Last-Touch Campaign 
===============================================================================
*/
SELECT 
    YEAR(f.purchase_date) AS year,
    MONTH(f.purchase_date) AS month,
    f.last_touch_campaign,
    c.campaign_name,
    AVG(f.touchpoint_number) AS avg_path_length
FROM gold.fact_attribution_last_touch f
LEFT JOIN gold.dim_campaign c
ON f.last_touch_campaign = c.campaign_id
WHERE f.last_touch_campaign IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), f.last_touch_campaign, c.campaign_name
ORDER BY f.last_touch_campaign, YEAR(f.purchase_date), MONTH(f.purchase_date)

/*
===============================================================================
3.2) Path Length by Aquisition Campaign 
===============================================================================
*/
SELECT 
    YEAR(f.purchase_date) AS year,
    MONTH(f.purchase_date) AS month,
    p.acquisition_campaign,
    c.campaign_name,
    AVG(touchpoint_number) AS avg_path_length
FROM gold.fact_attribution_last_touch f
LEFT JOIN gold.fact_purchases p
ON f.purchase_id = p.purchase_id
LEFT JOIN gold.dim_campaign c 
ON p.acquisition_campaign = c.campaign_id
WHERE p.acquisition_campaign IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), p.acquisition_campaign, c.campaign_name
ORDER BY p.acquisition_campaign, YEAR(f.purchase_date), MONTH(f.purchase_date)

