/*
===============================================================================
Drop-Off By Stage Funnel Analysis
===============================================================================
Purpose:
    - To measure the path length of journeys as such, the closing effectivness(path length by last-touch channel/campaign) and funnel nurturing difficulty (path length by acquisition channel/campaign)
    - To track monthly 2024 trends.

SQL Functions Used:
    - AVG() 
    - GROUP BY
    - LEFT JOIN

Queries:
    1) Determine Stage Counts and Path Lenghts 

!!   Due to synthetic data there are more users with clicks (8554) than users with impressions (8267)    !! 

===============================================================================
*/
USE marketing_dw; 
GO

/*
===============================================================================
1) Stage Counts and Path Length
===============================================================================
*/ 
-- Stage 1 Users with impressions
WITH impressions AS (
SELECT 
    COUNT(DISTINCT user_id) AS users_i
FROM gold.fact_touchpoints 
WHERE interaction_type = 'Impression'
)
-- Stage 2 Users who clicked
, clicks AS (
SELECT 
    COUNT(DISTINCT user_id) AS users_c
FROM gold.fact_clicks
)
-- Stage 3 Users who converted
, conversions AS (
SELECT 
    COUNT(DISTINCT user_id) AS users_p
FROM gold.fact_purchases
)
-- Drop off by path length
, user_path_lengths AS (
SELECT
    t.user_id,
    COUNT(*) AS path_length,
    MAX(t.touchpoint_time) AS last_seen
FROM gold.fact_touchpoints t
WHERE t.user_id NOT IN (SELECT DISTINCT user_id FROM gold.fact_purchases) -- excluding non-converting paths
GROUP BY t.user_id
)
SELECT 
    1 - ((SELECT users_c FROM clicks) * 1.0 /(SELECT users_i FROM impressions)) AS drop_off_impressions_to_clicks,
    1- ((SELECT users_p FROM conversions) * 1.0 /(SELECT users_c FROM clicks)) AS drop_off_clicks_to_conversions,
    (SELECT AVG(path_length) FROM user_path_lengths) AS avg_path_length_at_drop_off ;

