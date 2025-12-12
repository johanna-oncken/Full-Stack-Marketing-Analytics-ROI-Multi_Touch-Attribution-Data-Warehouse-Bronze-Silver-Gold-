/*
===============================================================================
CPC Cost per Click Performance Analysis (Month-over-Month)
===============================================================================
Purpose:
    - To measure the CPC performance of marketing components such as campaigns and channels over time (CPC lower = better).
    - For benchmarking and identifying high-performing entities.
    - To track monthly 2024 trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.

Queries: 
    1) CPC overall 
    2) CPC Performance monthly
    3.1) Monthly CPC Performance and MOM Analysis by Campaigns 
    3.2) Top Ten Campaigns by Monthly CPC Improvements 
    3.3) Top Ten Campaigns by Monthly CPC Declines 
    4.1) Monthly CPC Performance and MOM Analysis by Channels 
    4.2) Top Ten Channels by Monthly CPC Improvements 
    4.3) Top Ten Channels by Monthly CPC Declines

===============================================================================
*/
USE marketing_dw; 
GO


/*
===============================================================================
1) CPC overall
===============================================================================
*/ 
SELECT 
    (SELECT SUM(spend) FROM gold.fact_spend) AS spend, 
    (SELECT COUNT(click_id) FROM gold.fact_clicks) AS clicks,
    (SELECT SUM(spend) FROM gold.fact_spend) 
    / 
    (SELECT COUNT(click_id) FROM gold.fact_clicks) AS cpc;


/*
===============================================================================
2) CPC Performance monthly
===============================================================================
*/
DROP VIEW IF EXISTS gold.cpc;
GO

CREATE VIEW gold.cpc AS
WITH monthly_clicks AS (
SELECT
    d.year AS performance_year,
    d.month AS performance_month, 
    COUNT(f.click_id) AS clicks
FROM gold.fact_clicks f
LEFT JOIN gold.dim_date d 
ON f.date_key = d.date_key
GROUP BY d.year, d.month
), 
monthly_spend AS (
SELECT 
    YEAR(spend_date) AS performance_year,
    MONTH(spend_date) AS performance_month,
    SUM(spend) AS current_spend 
FROM gold.fact_spend  
GROUP BY YEAR(spend_date), MONTH(spend_date)
), 
cpc_metrics AS (
SELECT
    COALESCE(c.performance_year, s.performance_year) AS performance_year,
    COALESCE(c.performance_month, s.performance_month) AS performance_month,
    c.clicks AS current_clicks,
    s.current_spend,
    s.current_spend/NULLIF(c.clicks, 0) AS cpc
FROM monthly_clicks c
FULL JOIN monthly_spend s 
ON c.performance_year = s.performance_year
    AND c.performance_month = s.performance_month 
)


SELECT 
    performance_year,
    performance_month,
    current_spend,
    current_clicks,
    cpc AS current_cpc,
    AVG(cpc) OVER() AS avg_cpc,
    (cpc) - AVG(cpc) OVER() AS diff_avg,
    CASE 
        WHEN (cpc) - AVG(cpc) OVER() > 0 THEN 'Worsened (Above Avg)'
        WHEN (cpc) - AVG(cpc) OVER() < 0 THEN 'Improved (Below Avg)' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(cpc) OVER(ORDER BY performance_year, performance_month) AS pm_cpc, 
    (cpc) - LAG(cpc) OVER(ORDER BY performance_year, performance_month) AS diff_pm_cpc,
    CASE 
        WHEN (cpc) - LAG(cpc) OVER(ORDER BY performance_year, performance_month) > 0 THEN 'Worsened (Higher)'
        WHEN (cpc) - LAG(cpc) OVER(ORDER BY performance_year, performance_month) < 0 THEN 'Improved (Lower)'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(cpc) OVER(ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((cpc) - LAG(cpc) OVER(ORDER BY performance_year, performance_month))/LAG(cpc) OVER(ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM cpc_metrics;
GO

SELECT *
FROM gold.cpc
ORDER BY performance_year, performance_month;
GO


/*
===============================================================================
3) CAMPAIGNS
===============================================================================
*/
-- 3.1) MoM by Monthly Ad Spend and Clicks
--      Analyze Month-over-Month CPC campaign performance 
DROP VIEW IF EXISTS gold.campaigns_cpc;
GO

CREATE VIEW gold.campaigns_cpc AS
WITH monthly_clicks AS (
SELECT
    d.year AS performance_year,
    d.month AS performance_month, 
    f.campaign_id, 
    c.campaign_name,
    COUNT(f.click_id) AS clicks
FROM gold.fact_clicks f
LEFT JOIN gold.dim_campaign c 
ON f.campaign_id = c.campaign_id
LEFT JOIN gold.dim_date d 
ON f.date_key = d.date_key
WHERE f.campaign_id IS NOT NULL
GROUP BY d.year, d.month, f.campaign_id, c.campaign_name
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
cpc_metrics AS (
SELECT
    COALESCE(c.performance_year, s.performance_year) AS performance_year,
    COALESCE(c.performance_month, s.performance_month) AS performance_month,
    c.campaign_id, 
    c.campaign_name,
    c.clicks AS current_clicks,
    s.current_spend,
    s.current_spend/NULLIF(c.clicks, 0) AS cpc
FROM monthly_clicks c
FULL JOIN monthly_spend s 
ON c.performance_year = s.performance_year
    AND c.performance_month = s.performance_month 
    AND c.campaign_id = s.campaign_id
)

SELECT 
    performance_year,
    performance_month,
    campaign_id, 
    campaign_name,
    current_spend,
    current_clicks,
    cpc AS current_cpc,
    AVG(cpc) OVER(PARTITION BY campaign_id) AS avg_cpc,
    (cpc) - AVG(cpc) OVER(PARTITION BY campaign_id) AS diff_avg,
    CASE 
        WHEN (cpc) - AVG(cpc) OVER(PARTITION BY campaign_id) > 0 THEN 'Worsened (Above Avg)'
        WHEN (cpc) - AVG(cpc) OVER(PARTITION BY campaign_id) < 0 THEN 'Improved (Below Avg)' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(cpc) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS pm_cpc, 
    (cpc) - LAG(cpc) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS diff_pm_cpc,
    CASE 
        WHEN (cpc) - LAG(cpc) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) > 0 THEN 'Worsened (Higher)'
        WHEN (cpc) - LAG(cpc) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) < 0 THEN 'Improved (Lower)'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(cpc) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((cpc) - LAG(cpc) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month))/LAG(cpc) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM cpc_metrics
WHERE campaign_id IS NOT NULL;
GO

SELECT *
FROM gold.campaigns_cpc
ORDER BY campaign_id, performance_year, performance_month;
GO

-- 3.2) Top 10 Improvements MoM CPC campaigns
SELECT TOP 10 *
FROM gold.campaigns_cpc
WHERE diff_pm_cpc IS NOT NULL
ORDER BY diff_pm_cpc ASC; 

SELECT TOP 10 *
FROM gold.campaigns_cpc
WHERE pm_cpc IS NOT NULL
ORDER BY mom_percentage ASC;

-- 3.3) Top 10 Declines MoM CPC campaigns
SELECT TOP 10 *
FROM gold.campaigns_cpc
WHERE diff_pm_cpc IS NOT NULL
ORDER BY diff_pm_cpc DESC; 

SELECT TOP 10 *
FROM gold.campaigns_cpc
WHERE pm_cpc IS NOT NULL
ORDER BY mom_percentage DESC;


/*
===============================================================================
4) CHANNELS
===============================================================================
*/
-- 4.2) MoM by Monthly Ad Spend and Clicks
--      Analyze Month-over-Month CPC channel performance 
DROP VIEW IF EXISTS gold.channels_cpc;
GO

CREATE VIEW gold.channels_cpc AS
WITH monthly_clicks AS (
SELECT
    d.year AS performance_year,
    d.month AS performance_month, 
    f.click_channel, 
    COUNT(f.click_id) AS clicks
FROM gold.fact_clicks f
LEFT JOIN gold.dim_date d 
ON f.date_key = d.date_key
WHERE f.click_channel IS NOT NULL
GROUP BY d.year, d.month, f.click_channel
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
cpc_metrics AS (
SELECT
    COALESCE(c.performance_year, s.performance_year) AS performance_year,
    COALESCE(c.performance_month, s.performance_month) AS performance_month,
    c.click_channel, 
    c.clicks AS current_clicks,
    s.current_spend,
    s.current_spend/NULLIF(c.clicks, 0) AS cpc
FROM monthly_clicks c
FULL JOIN monthly_spend s 
ON c.performance_year = s.performance_year
    AND c.performance_month = s.performance_month 
    AND c.click_channel = s.channel
)

SELECT 
    performance_year,
    performance_month,
    click_channel, 
    current_spend,
    current_clicks,
    cpc AS current_cpc,
    AVG(cpc) OVER(PARTITION BY click_channel) AS avg_cpc,
    (cpc) - AVG(cpc) OVER(PARTITION BY click_channel) AS diff_avg,
    CASE 
        WHEN (cpc) - AVG(cpc) OVER(PARTITION BY click_channel) > 0 THEN 'Worsened (Above Avg)'
        WHEN (cpc) - AVG(cpc) OVER(PARTITION BY click_channel) < 0 THEN 'Improved (Below Avg)' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(cpc) OVER(PARTITION BY click_channel ORDER BY performance_year, performance_month) AS pm_cpc, 
    (cpc) - LAG(cpc) OVER(PARTITION BY click_channel ORDER BY performance_year, performance_month) AS diff_pm_cpc,
    CASE 
        WHEN (cpc) - LAG(cpc) OVER(PARTITION BY click_channel ORDER BY performance_year, performance_month) > 0 THEN 'Worsened (Higher)'
        WHEN (cpc) - LAG(cpc) OVER(PARTITION BY click_channel ORDER BY performance_year, performance_month) < 0 THEN 'Improved (Lower)'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(cpc) OVER(PARTITION BY click_channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((cpc) - LAG(cpc) OVER(PARTITION BY click_channel ORDER BY performance_year, performance_month))/LAG(cpc) OVER(PARTITION BY click_channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM cpc_metrics
WHERE click_channel IS NOT NULL;
GO

SELECT *
FROM gold.channels_cpc
ORDER BY click_channel, performance_year, performance_month;
GO

-- 4.2) Top 10 Improvements MoM CPC channels
SELECT TOP 10 *
FROM gold.channels_cpc
WHERE diff_pm_cpc IS NOT NULL
ORDER BY diff_pm_cpc ASC; 

SELECT TOP 10 *
FROM gold.channels_cpc
WHERE pm_cpc IS NOT NULL
ORDER BY mom_percentage ASC;

-- 4.3) Top 10 Declines MoM cpc channels
SELECT TOP 10 *
FROM gold.channels_cpc
WHERE diff_pm_cpc IS NOT NULL
ORDER BY diff_pm_cpc DESC; 

SELECT TOP 10 *
FROM gold.channels_cpc
WHERE pm_cpc IS NOT NULL
ORDER BY mom_percentage DESC;

