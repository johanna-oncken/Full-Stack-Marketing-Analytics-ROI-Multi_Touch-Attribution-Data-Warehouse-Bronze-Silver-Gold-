/*
===============================================================================
CAC Customer Acquisition Cost Performance Analysis (Month-over-Month)
===============================================================================
Purpose:
    - To measure the CAC performance of marketing components such as campaigns and channels over time (CAC lower = better).
    - For benchmarking and identifying high-performing entities.
    - To track monthly 2024 trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.

Queries: 
    1) CAC overall 
    2) CAC Performance monthly
    3.1) Monthly CAC Performance and MOM-Analysis by Campaigns
    3.2) Top Ten Campaigns by CAC Monthly Improvements 
    3.3) Top Ten Campaigns by CAC Monthly Declines 
    4.1) Monthly CAC Performance and MOM-Analysis by Channels
    4.2) Top Ten Channels by CAC Monthly Improvements 
    4.3) Top Ten Channels by CAC Monthly Declinse

===============================================================================
*/
USE marketing_dw; 
GO


/*
===============================================================================
1) CAC overall
===============================================================================
*/
SELECT
    (SELECT COUNT(user_id) FROM gold.fact_purchases) AS new_users,
    (SELECT SUM(spend) FROm gold.fact_spend) AS current_spend,
    (SELECT SUM(spend) FROm gold.fact_spend)
    /
    (SELECT COUNT(user_id) FROM gold.fact_purchases) AS cac;


/*
===============================================================================
2) CAC Performance monthly
===============================================================================
*/
DROP VIEW IF EXISTS gold.cac;
GO

CREATE VIEW gold.cac AS
WITH monthly_users AS (
SELECT
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month, 
    COUNT(user_id) AS new_users
FROM gold.fact_purchases 
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
cac_metrics AS (
SELECT
    COALESCE(u.performance_year, s.performance_year) AS performance_year,
    COALESCE(u.performance_month, s.performance_month) AS performance_month,
    u.new_users AS current_new_users,
    s.current_spend,
    s.current_spend/NULLIF(u.new_users, 0) AS cac
FROM monthly_users u
FULL JOIN monthly_spend s 
ON u.performance_year = s.performance_year
    AND u.performance_month = s.performance_month 
)

SELECT 
    performance_year,
    performance_month,
    current_spend,
    current_new_users,
    cac AS current_cac,
    AVG(cac) OVER() AS avg_cac,
    (cac) - AVG(cac) OVER() AS diff_avg,
    CASE 
        WHEN (cac) - AVG(cac) OVER() > 0 THEN 'Worsened (Above Avg)'
        WHEN (cac) - AVG(cac) OVER() < 0 THEN 'Improved (Below Avg)' 
        ELSE 'Equals Average'
    END AS avg_change, 
    -- Month-over_Month Analysis 
    LAG(cac) OVER(ORDER BY performance_year, performance_month) AS pm_cac, 
    (cac) - LAG(cac) OVER(ORDER BY performance_year, performance_month) AS diff_pm_cac,
    CASE 
        WHEN (cac) - LAG(cac) OVER(ORDER BY performance_year, performance_month) > 0 THEN 'Worsened (Higher)'
        WHEN (cac) - LAG(cac) OVER(ORDER BY performance_year, performance_month) < 0 THEN 'Improved (Lower)'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(cac) OVER(ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((cac) - LAG(cac) OVER(ORDER BY performance_year, performance_month))/LAG(cac) OVER(ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM cac_metrics;
GO

SELECT *
FROM gold.cac
ORDER BY performance_year, performance_month;
GO


/*
===============================================================================
3) CAMPAIGNS
===============================================================================
*/
-- 3.1) MoM by Monthly Ad Spend and Newly Acquired Customers
--      Analyze Month-over-Month CAC campaign performance 
DROP VIEW IF EXISTS gold.campaigns_cac;
GO

CREATE VIEW gold.campaigns_cac AS
WITH monthly_users AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    f.acquisition_campaign, 
    c.campaign_name,
    COUNT(f.user_id) AS new_users
FROM gold.fact_purchases f
LEFT JOIN gold.dim_campaign c 
ON f.acquisition_campaign = c.campaign_id
WHERE f.acquisition_campaign IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), f.acquisition_campaign, c.campaign_name
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
cac_metrics AS (
SELECT
    COALESCE(u.performance_year, s.performance_year) AS performance_year,
    COALESCE(u.performance_month, s.performance_month) AS performance_month,
    u.acquisition_campaign, 
    u.campaign_name,
    u.new_users AS current_new_users,
    s.current_spend,
    s.current_spend/NULLIF(u.new_users, 0) AS cac
FROM monthly_users u
FULL JOIN monthly_spend s 
ON u.performance_year = s.performance_year
    AND u.performance_month = s.performance_month 
    AND u.acquisition_campaign = s.campaign_id
)

SELECT 
    performance_year,
    performance_month,
    acquisition_campaign, 
    campaign_name,
    current_spend,
    current_new_users,
    cac AS current_cac,
    AVG(cac) OVER(PARTITION BY acquisition_campaign) AS avg_cac,
    (cac) - AVG(cac) OVER(PARTITION BY acquisition_campaign) AS diff_avg,
    CASE 
        WHEN (cac) - AVG(cac) OVER(PARTITION BY acquisition_campaign) > 0 THEN 'Worsened (Above Avg)'
        WHEN (cac) - AVG(cac) OVER(PARTITION BY acquisition_campaign) < 0 THEN 'Improved (Below Avg)' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(cac) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) AS pm_cac, 
    (cac) - LAG(cac) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) AS diff_pm_cac,
    CASE 
        WHEN (cac) - LAG(cac) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) > 0 THEN 'Worsened (Higher)'
        WHEN (cac) - LAG(cac) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) < 0 THEN 'Improved (Lower)'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(cac) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((cac) - LAG(cac) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month))/LAG(cac) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM cac_metrics
WHERE acquisition_campaign IS NOT NULL;
GO

SELECT *
FROM gold.campaigns_cac
ORDER BY acquisition_campaign, performance_year, performance_month;
GO

-- 3.2) Top 10 Improvements MoM CAC campaigns
SELECT TOP 10 *
FROM gold.campaigns_cac
WHERE diff_pm_cac IS NOT NULL
ORDER BY diff_pm_cac ASC; 

SELECT TOP 10 *
FROM gold.campaigns_cac
WHERE pm_cac IS NOT NULL
ORDER BY mom_percentage ASC;

-- 3.3) Top 10 Declines MoM CAC campaigns
SELECT TOP 10 *
FROM gold.campaigns_cac
WHERE diff_pm_cac IS NOT NULL
ORDER BY diff_pm_cac DESC; 

SELECT TOP 10 *
FROM gold.campaigns_cac
WHERE pm_cac IS NOT NULL
ORDER BY mom_percentage DESC;


/*
===============================================================================
4) CHANNELS
===============================================================================
*/
-- 4.4) MoM by Monthly Ad Spend and Newly Acquired Customers
--      Analyze Month-over-Month CAC channel performance 
DROP VIEW IF EXISTS gold.channels_cac;
GO

CREATE VIEW gold.channels_cac AS
WITH monthly_users AS (
SELECT
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month, 
    acquisition_channel,
    COUNT(user_id) AS new_users
FROM gold.fact_purchases f
WHERE acquisition_channel IS NOT NULL
GROUP BY YEAR(purchase_date), MONTH(purchase_date), acquisition_channel
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
cac_metrics AS (
SELECT
    COALESCE(u.performance_year, s.performance_year) AS performance_year,
    COALESCE(u.performance_month, s.performance_month) AS performance_month,
    u.acquisition_channel, 
    u.new_users AS current_new_users,
    s.current_spend,
    s.current_spend/NULLIF(u.new_users, 0) AS cac
FROM monthly_users u
FULL JOIN monthly_spend s 
ON u.performance_year = s.performance_year
    AND u.performance_month = s.performance_month 
    AND u.acquisition_channel = s.channel
)

SELECT 
    performance_year,
    performance_month,
    acquisition_channel, 
    current_spend,
    current_new_users,
    cac AS current_cac,
    AVG(cac) OVER(PARTITION BY acquisition_channel) AS avg_cac,
    (cac) - AVG(cac) OVER(PARTITION BY acquisition_channel) AS diff_avg,
    CASE 
        WHEN (cac) - AVG(cac) OVER(PARTITION BY acquisition_channel) > 0 THEN 'Worsened (Above Avg)'
        WHEN (cac) - AVG(cac) OVER(PARTITION BY acquisition_channel) < 0 THEN 'Improved (Below Avg)' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(cac) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) AS pm_cac, 
    (cac) - LAG(cac) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) AS diff_pm_cac,
    CASE 
        WHEN (cac) - LAG(cac) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) > 0 THEN 'Worsened (Higher)'
        WHEN (cac) - LAG(cac) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) < 0 THEN 'Improved (Lower)'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(cac) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((cac) - LAG(cac) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month))/LAG(cac) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM cac_metrics
WHERE acquisition_channel IS NOT NULL;
GO

SELECT *
FROM gold.channels_cac
ORDER BY acquisition_channel, performance_year, performance_month;
GO

-- 4.2) Top 10 Improvements MoM CAC channels
SELECT TOP 10 *
FROM gold.channels_cac
WHERE diff_pm_cac IS NOT NULL
ORDER BY diff_pm_cac ASC; 

SELECT TOP 10 *
FROM gold.channels_cac
WHERE pm_cac IS NOT NULL
ORDER BY mom_percentage ASC;

-- 4.3) Top 10 Declines MoM CAC channels
SELECT TOP 10 *
FROM gold.channels_cac
WHERE diff_pm_cac IS NOT NULL
ORDER BY diff_pm_cac DESC; 

SELECT TOP 10 *
FROM gold.channels_cac
WHERE pm_cac IS NOT NULL
ORDER BY mom_percentage DESC;

