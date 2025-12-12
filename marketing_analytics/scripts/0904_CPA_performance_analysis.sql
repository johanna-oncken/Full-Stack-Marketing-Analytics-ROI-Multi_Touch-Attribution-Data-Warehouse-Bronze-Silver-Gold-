/*
===============================================================================
CPA Cost per Aquisition Performance Analysis (Month-over-Month)
===============================================================================
Purpose:
    - To measure the CPA performance of marketing components such as campaigns and channels over time (CPA lower = better).
    - For benchmarking and identifying high-performing entities.
    - To track monthly 2024 trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis. 

Queries: 
    1) CPA overall 
    2) CPA Performance monthly
    3.1) Monthly CPA Performance and MOM Analysis by Campaigns 
    3.2) Top Ten Campaigns by Monthly CPA Improvements 
    3.3) Top Ten Campaigns by Monthly CPA Declines 
    4.1) Monthly CPA Performance and MOM Analysis by Channels 
    4.2) Top Ten Channels by Monthly CPA Improvements 
    4.3) Top Ten Channels by Monthly CPA Declines
    

===============================================================================
*/
USE marketing_dw; 
GO

/*
===============================================================================
1) CPA overall
===============================================================================
*/
SELECT 
    (SELECT SUM(spend) FROM gold.fact_spend) AS spend, 
    (SELECT COUNT(purchase_id) FROM gold.fact_purchases) AS conversions,
    (SELECT SUM(spend) FROM gold.fact_spend) 
    /
    (SELECT COUNT(purchase_id) FROM gold.fact_purchases) AS cpa;


/*
===============================================================================
2) CPA Performance monthly
===============================================================================
*/
DROP VIEW IF EXISTS gold.cpa;
GO

CREATE VIEW gold.cpa AS
WITH monthly_conversions AS (
SELECT
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month, 
    COUNT(purchase_id) AS conversions
FROM gold.fact_attribution_last_touch
GROUP BY YEAR(purchase_date), MONTH(purchase_date)
), 
monthly_spend AS (
SELECT 
    YEAR(spend_date) AS performance_year,
    MONTH(spend_date) AS performance_month,
    SUM(spend) AS current_spend 
FROM gold.fact_spend 
GROUP BY YEAR(spend_date), MONTH(spend_date)
), 
cpa_metrics AS (
SELECT
    COALESCE(c.performance_year, s.performance_year) AS performance_year,
    COALESCE(c.performance_month, s.performance_month) AS performance_month,
    c.conversions AS current_conversions,
    s.current_spend,
    s.current_spend/NULLIF(c.conversions, 0) AS cpa
FROM monthly_conversions c
FULL JOIN monthly_spend s 
ON c.performance_year = s.performance_year
    AND c.performance_month = s.performance_month 
)

SELECT 
    performance_year,
    performance_month,
    current_spend,
    current_conversions,
    cpa AS current_cpa,
    AVG(cpa) OVER() AS avg_cpa,
    (cpa) - AVG(cpa) OVER() AS diff_avg,
    CASE 
        WHEN (cpa) - AVG(cpa) OVER() > 0 THEN 'Worsened (Above Avg)'
        WHEN (cpa) - AVG(cpa) OVER() < 0 THEN 'Improved (Below Avg)' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(cpa) OVER(ORDER BY performance_year, performance_month) AS pm_cpa, 
    (cpa) - LAG(cpa) OVER(ORDER BY performance_year, performance_month) AS diff_pm_cpa,
    CASE 
        WHEN (cpa) - LAG(cpa) OVER(ORDER BY performance_year, performance_month) > 0 THEN 'Worsened (Higher)'
        WHEN (cpa) - LAG(cpa) OVER(ORDER BY performance_year, performance_month) < 0 THEN 'Improved (Lower)'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(cpa) OVER(ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((cpa) - LAG(cpa) OVER(ORDER BY performance_year, performance_month))/LAG(cpa) OVER(ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM cpa_metrics;
GO

SELECT *
FROM gold.cpa
ORDER BY performance_year, performance_month;
GO


/*
===============================================================================
3) CAMPAIGNS
===============================================================================
*/
-- 3.1) MoM by Monthly Ad Spend and Conversions
--      Analyze Month-over-Month CPA campaign performance 
DROP VIEW IF EXISTS gold.campaigns_cpa;
GO

CREATE VIEW gold.campaigns_cpa AS
WITH monthly_conversions AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    f.last_touch_campaign, 
    c.campaign_name,
    COUNT(f.purchase_id) AS conversions
FROM gold.fact_attribution_last_touch f
LEFT JOIN gold.dim_campaign c 
ON f.last_touch_campaign = c.campaign_id
WHERE f.last_touch_campaign IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), f.last_touch_campaign, c.campaign_name
), 
monthly_spend AS (
SELECT 
    YEAR(spend_date) AS performance_year,
    MONTH(spend_date) AS performance_month,
    campaign_id, 
    SUM(spend) AS current_spend 
FROM gold.fact_spend 
WHERE campaign_id IS NOT NULL 
GROUP BY YEAR(spend_date), MONTH(spend_date), campaign_id
), 
cpa_metrics AS (
SELECT
    COALESCE(c.performance_year, s.performance_year) AS performance_year,
    COALESCE(c.performance_month, s.performance_month) AS performance_month,
    c.last_touch_campaign, 
    c.campaign_name,
    c.conversions AS current_conversions,
    s.current_spend,
    s.current_spend/NULLIF(c.conversions, 0) AS cpa
FROM monthly_conversions c
FULL JOIN monthly_spend s 
ON c.performance_year = s.performance_year
    AND c.performance_month = s.performance_month 
    AND c.last_touch_campaign = s.campaign_id
)

SELECT 
    performance_year,
    performance_month,
    last_touch_campaign, 
    campaign_name,
    current_spend,
    current_conversions,
    cpa AS current_cpa,
    AVG(cpa) OVER(PARTITION BY last_touch_campaign) AS avg_cpa,
    (cpa) - AVG(cpa) OVER(PARTITION BY last_touch_campaign) AS diff_avg,
    CASE 
        WHEN (cpa) - AVG(cpa) OVER(PARTITION BY last_touch_campaign) > 0 THEN 'Worsened (Above Avg)'
        WHEN (cpa) - AVG(cpa) OVER(PARTITION BY last_touch_campaign) < 0 THEN 'Improved (Below Avg)' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(cpa) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) AS pm_cpa, 
    (cpa) - LAG(cpa) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) AS diff_pm_cpa,
    CASE 
        WHEN (cpa) - LAG(cpa) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) > 0 THEN 'Worsened (Higher)'
        WHEN (cpa) - LAG(cpa) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) < 0 THEN 'Improved (Lower)'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(cpa) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((cpa) - LAG(cpa) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month))/LAG(cpa) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM cpa_metrics
WHERE last_touch_campaign IS NOT NULL;
GO

SELECT *
FROM gold.campaigns_cpa
ORDER BY last_touch_campaign, performance_year, performance_month;
GO

-- 3.2) Top 10 Improvements MoM CPA campaigns
SELECT TOP 10 *
FROM gold.campaigns_cpa
WHERE diff_pm_cpa IS NOT NULL
ORDER BY diff_pm_cpa ASC; 

SELECT TOP 10 *
FROM gold.campaigns_cpa
WHERE pm_cpa IS NOT NULL
ORDER BY mom_percentage ASC;

-- 3.3) Top 10 Declines MoM CPA campaigns
SELECT TOP 10 *
FROM gold.campaigns_cpa
WHERE diff_pm_cpa IS NOT NULL
ORDER BY diff_pm_cpa DESC; 

SELECT TOP 10 *
FROM gold.campaigns_cpa
WHERE pm_cpa IS NOT NULL
ORDER BY mom_percentage DESC;


/*
===============================================================================
4) CHANNELS
===============================================================================
*/
-- 4.1) MoM by Monthly Ad Spend and Conversions
--      Analyze Month-over-Month CPA channel performance 
DROP VIEW IF EXISTS gold.channels_cpa;
GO

CREATE VIEW gold.channels_cpa AS
WITH monthly_conversions AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    f.last_touch_channel, 
    COUNT(f.purchase_id) AS conversions
FROM gold.fact_attribution_last_touch f
WHERE f.last_touch_channel IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), f.last_touch_channel
), 
monthly_spend AS (
SELECT 
    YEAR(spend_date) AS performance_year,
    MONTH(spend_date) AS performance_month,
    channel, 
    SUM(spend) AS current_spend 
FROM gold.fact_spend 
WHERE channel IS NOT NULL 
GROUP BY YEAR(spend_date), MONTH(spend_date), channel
), 
cpa_metrics AS (
SELECT
    COALESCE(c.performance_year, s.performance_year) AS performance_year,
    COALESCE(c.performance_month, s.performance_month) AS performance_month,
    c.last_touch_channel, 
    c.conversions AS current_conversions,
    s.current_spend,
    s.current_spend/NULLIF(c.conversions, 0) AS cpa
FROM monthly_conversions c
FULL JOIN monthly_spend s 
ON c.performance_year = s.performance_year
    AND c.performance_month = s.performance_month 
    AND c.last_touch_channel = s.channel
)

SELECT 
    performance_year,
    performance_month,
    last_touch_channel, 
    current_spend,
    current_conversions,
    cpa AS current_cpa,
    AVG(cpa) OVER(PARTITION BY last_touch_channel) AS avg_cpa,
    (cpa) - AVG(cpa) OVER(PARTITION BY last_touch_channel) AS diff_avg,
    CASE 
        WHEN (cpa) - AVG(cpa) OVER(PARTITION BY last_touch_channel) > 0 THEN 'Worsened (Above Avg)'
        WHEN (cpa) - AVG(cpa) OVER(PARTITION BY last_touch_channel) < 0 THEN 'Improved (Below Avg)' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(cpa) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) AS pm_cpa, 
    (cpa) - LAG(cpa) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) AS diff_pm_cpa,
    CASE 
        WHEN (cpa) - LAG(cpa) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) > 0 THEN 'Worsened (Higher)'
        WHEN (cpa) - LAG(cpa) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) < 0 THEN 'Improved (Lower)'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(cpa) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((cpa) - LAG(cpa) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month))/LAG(cpa) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM cpa_metrics
WHERE last_touch_channel IS NOT NULL;
GO

SELECT *
FROM gold.channels_cpa
ORDER BY last_touch_channel, performance_year, performance_month;
GO

-- 4.2) Top 10 Improvements MoM CPA channels
SELECT TOP 10 *
FROM gold.channels_cpa
WHERE diff_pm_cpa IS NOT NULL
ORDER BY diff_pm_cpa ASC; 

SELECT TOP 10 *
FROM gold.channels_cpa
WHERE pm_cpa IS NOT NULL
ORDER BY mom_percentage ASC;

-- 4.3) Top 10 Declines MoM CPA channels
SELECT TOP 10 *
FROM gold.channels_cpa
WHERE diff_pm_cpa IS NOT NULL
ORDER BY diff_pm_cpa DESC; 

SELECT TOP 10 *
FROM gold.channels_cpa
WHERE pm_cpa IS NOT NULL
ORDER BY mom_percentage DESC;

