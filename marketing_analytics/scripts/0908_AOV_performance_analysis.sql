/*
===============================================================================
AOV Average Order Value Performance Analysis (Month-over-Month)
===============================================================================
Purpose:
    - To measure the performance of marketing components such as campagins and channels over time.
    - For benchmarking and identifying high-performing entities.
    - To track monthly 2024 trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis. 

Queries: 
    1) AOV overall 
    2) AOV Performance monthly
    3.1) Mid of Funnel (MOFU) Monthly AOV Performance and MOM-Analysis by Campaigns
    3.2) Top of Funnel (TOFU) Monthly AOV Performance and MOM-Analysis by Campaigns
    3.3) Bottom of Funnel (BOFU) Monthly AOV Performance and MOM-Analysis by Campaigns
    4.1) Mid of Funnel (MOFU) Monthly AOV Performance and MOM-Analysis by Channels
    4.2) Top of Funnel (TOFU) Monthly AOV Performance and MOM-Analysis by Channels
    4.3) Bottom of Funnel (BOFU) Monthly AOV Performance and MOM-Analysis by Channels

===============================================================================
*/
USE marketing_dw; 
GO

/*
===============================================================================
1) AOV overall
===============================================================================
*/
SELECT 
    (SELECT SUM(revenue_share) FROM gold.fact_attribution_linear) AS revenue, 
    (SELECT COUNT(distinct purchase_id) FROM gold.fact_attribution_linear) AS orders,
    (SELECT SUM(revenue_share) FROM gold.fact_attribution_linear) 
    / 
    (SELECT COUNT(distinct purchase_id) FROM gold.fact_attribution_linear) AS aov;


/*
===============================================================================
2) AOV Performance monthly
===============================================================================
*/
DROP VIEW IF EXISTS gold.aov;
GO

CREATE VIEW gold.aov AS
WITH monthly_revenue AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    SUM(f.revenue_share) AS current_revenue 
FROM gold.fact_attribution_linear f
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date)
), 
monthly_orders AS (
SELECT 
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month,
    COUNT(DISTINCT purchase_id) AS current_orders
FROM gold.fact_attribution_linear
GROUP BY YEAR(purchase_date), MONTH(purchase_date)
), 
aov_metrics AS (
SELECT
    COALESCE(r.performance_year, o.performance_year) AS performance_year,
    COALESCE(r.performance_month, o.performance_month) AS performance_month,
    r.current_revenue,
    o.current_orders,
    r.current_revenue/NULLIF(o.current_orders, 0) AS aov
FROM monthly_revenue r
INNER JOIN monthly_orders o
ON r.performance_year = o.performance_year
    AND r.performance_month = o.performance_month 
)

SELECT 
    performance_year,
    performance_month,
    current_revenue,
    current_orders,
    aov AS current_aov,
    AVG(aov) OVER() AS avg_aov,
    (aov) - AVG(aov) OVER() AS diff_avg,
    CASE 
        WHEN (aov) - AVG(aov) OVER() > 0 THEN 'Above Avg'
        WHEN (aov) - AVG(aov) OVER() < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(aov) OVER(ORDER BY performance_year, performance_month) AS pm_aov, 
    (aov) - LAG(aov) OVER(ORDER BY performance_year, performance_month) AS diff_pm_aov,
    CASE 
        WHEN (aov) - LAG(aov) OVER(ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN (aov) - LAG(aov) OVER(ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(aov) OVER(ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((aov) - LAG(aov) OVER(ORDER BY performance_year, performance_month))/LAG(aov) OVER(ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM aov_metrics;
GO

SELECT *
FROM gold.aov
ORDER BY performance_year, performance_month;
GO


/*
===============================================================================
3) CAMPAIGNS
===============================================================================
*/
--===================================
-- 3.1) MOFU Full-Funnel Contributers
--=================================== 
-- MoM by Multi-Touch Revenue Shares and Monthly Orders
-- Analyze Month-over-Month AOV performance of campaigns by comparing their AOV to both the average AOV performance of the campaign and the previous month AOV 
DROP VIEW IF EXISTS gold.campaigns_aov;
GO

CREATE VIEW gold.campaigns_aov AS
WITH monthly_revenue AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    f.campaign_id, 
    c.campaign_name,
    SUM(f.revenue_share) AS current_revenue 
FROM gold.fact_attribution_linear f
LEFT JOIN gold.dim_campaign c 
ON f.campaign_id = c.campaign_id
WHERE f.campaign_id IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), f.campaign_id, c.campaign_name
), 
monthly_orders AS (
SELECT 
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month,
    campaign_id, 
    COUNT(DISTINCT purchase_id) AS current_orders
FROM gold.fact_attribution_linear
WHERE campaign_id IS NOT NULL 
GROUP BY YEAR(purchase_date), MONTH(purchase_date), campaign_id
), 
aov_metrics AS (
SELECT
    COALESCE(r.performance_year, o.performance_year) AS performance_year,
    COALESCE(r.performance_month, o.performance_month) AS performance_month,
    r.campaign_id, 
    r.campaign_name,
    r.current_revenue,
    o.current_orders,
    r.current_revenue/NULLIF(o.current_orders, 0) AS aov
FROM monthly_revenue r
INNER JOIN monthly_orders o
ON r.performance_year = o.performance_year
    AND r.performance_month = o.performance_month 
    AND r.campaign_id = o.campaign_id

)

SELECT 
    performance_year,
    performance_month,
    campaign_id, 
    campaign_name,
    current_revenue,
    current_orders,
    aov AS current_aov,
    AVG(aov) OVER(PARTITION BY campaign_id) AS avg_aov,
    (aov) - AVG(aov) OVER(PARTITION BY campaign_id) AS diff_avg,
    CASE 
        WHEN (aov) - AVG(aov) OVER(PARTITION BY campaign_id) > 0 THEN 'Above Avg'
        WHEN (aov) - AVG(aov) OVER(PARTITION BY campaign_id) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(aov) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS pm_aov, 
    (aov) - LAG(aov) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS diff_pm_aov,
    CASE 
        WHEN (aov) - LAG(aov) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN (aov) - LAG(aov) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(aov) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((aov) - LAG(aov) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month))/LAG(aov) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM aov_metrics;
GO

SELECT *
FROM gold.campaigns_aov
WHERE current_orders > 0
ORDER BY campaign_id, performance_year, performance_month;
GO


--=====================================
-- 3.2) TOFU Top of Funnel Contributers
--=====================================
-- MoM by Full Purchase Revenues and Monthly Orders
-- Analyze Month-over-Month aov performance by acquisition campaign to see the quality of new users
DROP VIEW IF EXISTS gold.acquisition_campaigns_aov;
GO

CREATE VIEW gold.acquisition_campaigns_aov AS
WITH monthly_revenue AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    p.acquisition_campaign, 
    c.campaign_name,
    SUM(f.revenue_share) AS current_revenue 
FROM gold.fact_attribution_linear f
LEFT JOIN gold.fact_purchases p 
ON f.purchase_id = p.purchase_id
LEFT JOIN gold.dim_campaign c 
ON p.acquisition_campaign = c.campaign_id
WHERE p.acquisition_campaign IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), p.acquisition_campaign, c.campaign_name
), 
monthly_orders AS (
SELECT 
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month,
    p.acquisition_campaign, 
    COUNT(DISTINCT f.purchase_id) AS current_orders
FROM gold.fact_attribution_linear f 
LEFT JOIN gold.fact_purchases p 
ON f.purchase_id = p.purchase_id 
WHERE p.acquisition_campaign IS NOT NULL 
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), p.acquisition_campaign
), 
aov_metrics AS (
SELECT
    COALESCE(r.performance_year, o.performance_year) AS performance_year,
    COALESCE(r.performance_month, o.performance_month) AS performance_month,
    r.acquisition_campaign, 
    r.campaign_name,
    r.current_revenue,
    o.current_orders,
    r.current_revenue/NULLIF(o.current_orders, 0) AS aov
FROM monthly_revenue r
INNER JOIN monthly_orders o
ON r.performance_year = o.performance_year
    AND r.performance_month = o.performance_month 
    AND r.acquisition_campaign = o.acquisition_campaign
)

SELECT 
    performance_year,
    performance_month,
    acquisition_campaign, 
    campaign_name,
    current_revenue,
    current_orders,
    aov AS current_aov,
    AVG(aov) OVER(PARTITION BY acquisition_campaign) AS avg_aov,
    (aov) - AVG(aov) OVER(PARTITION BY acquisition_campaign) AS diff_avg,
    CASE 
        WHEN (aov) - AVG(aov) OVER(PARTITION BY acquisition_campaign) > 0 THEN 'Above Avg'
        WHEN (aov) - AVG(aov) OVER(PARTITION BY acquisition_campaign) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(aov) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) AS pm_aov, 
    (aov) - LAG(aov) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) AS diff_pm_aov,
    CASE 
        WHEN (aov) - LAG(aov) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN (aov) - LAG(aov) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(aov) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((aov) - LAG(aov) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month))/LAG(aov) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM aov_metrics;
GO

SELECT *
FROM gold.acquisition_campaigns_aov
WHERE current_orders > 0
ORDER BY acquisition_campaign, performance_year, performance_month;
GO


--==============================================
-- 3.3) BOFU Bottom of Funnel Conversion Drivers
--==============================================
-- MoM by Full Purchase Revenues and Monthly Orders
-- Analyze Month-over-Month aov performance by last-touch campaign to see closing stage value
DROP VIEW IF EXISTS gold.last_touch_campaigns_aov;
GO

CREATE VIEW gold.last_touch_campaigns_aov AS
WITH monthly_revenue AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    f.last_touch_campaign, 
    c.campaign_name,
    SUM(f.revenue) AS current_revenue 
FROM gold.fact_attribution_last_touch f
LEFT JOIN gold.dim_campaign c 
ON f.last_touch_campaign = c.campaign_id
WHERE f.last_touch_campaign IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), f.last_touch_campaign, c.campaign_name
), 
monthly_orders AS (
SELECT 
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month,
    last_touch_campaign, 
    COUNT(purchase_id) AS current_orders
FROM gold.fact_attribution_last_touch
WHERE last_touch_campaign IS NOT NULL 
GROUP BY YEAR(purchase_date), MONTH(purchase_date), last_touch_campaign
), 
aov_metrics AS (
SELECT
    COALESCE(r.performance_year, o.performance_year) AS performance_year,
    COALESCE(r.performance_month, o.performance_month) AS performance_month,
    r.last_touch_campaign, 
    r.campaign_name,
    r.current_revenue,
    o.current_orders,
    r.current_revenue/NULLIF(o.current_orders, 0) AS aov
FROM monthly_revenue r
INNER JOIN monthly_orders o
ON r.performance_year = o.performance_year
    AND r.performance_month = o.performance_month 
    AND r.last_touch_campaign = o.last_touch_campaign
)

SELECT 
    performance_year,
    performance_month,
    last_touch_campaign, 
    campaign_name,
    current_revenue,
    current_orders,
    aov AS current_aov,
    AVG(aov) OVER(PARTITION BY last_touch_campaign) AS avg_aov,
    (aov) - AVG(aov) OVER(PARTITION BY last_touch_campaign) AS diff_avg,
    CASE 
        WHEN (aov) - AVG(aov) OVER(PARTITION BY last_touch_campaign) > 0 THEN 'Above Avg'
        WHEN (aov) - AVG(aov) OVER(PARTITION BY last_touch_campaign) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(aov) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) AS pm_aov, 
    (aov) - LAG(aov) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) AS diff_pm_aov,
    CASE 
        WHEN (aov) - LAG(aov) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN (aov) - LAG(aov) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(aov) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((aov) - LAG(aov) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month))/LAG(aov) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM aov_metrics;
GO

SELECT *
FROM gold.last_touch_campaigns_aov
WHERE current_orders > 0 
ORDER BY last_touch_campaign, performance_year, performance_month;
GO


/*
===============================================================================
4) CHANNELS
===============================================================================
*/
--===================================
-- 4.1) MOFU Full-Funnel Contributers
--=================================== 
-- MoM by Multi-Touch Revenue Shares and Monthly Orders
-- Analyze Month-over-Month AOV performance of channels by comparing their AOV to both the average AOV performance of the channel and the previous month AOV 
DROP VIEW IF EXISTS gold.channels_aov;
GO

CREATE VIEW gold.channels_aov AS
WITH monthly_revenue AS (
SELECT
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month, 
    channel,
    SUM(revenue_share) AS current_revenue 
FROM gold.fact_attribution_linear 
WHERE channel IS NOT NULL
GROUP BY YEAR(purchase_date), MONTH(purchase_date), channel
), 
monthly_orders AS (
SELECT 
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month,
    channel, 
    COUNT(DISTINCT purchase_id) AS current_orders
FROM gold.fact_attribution_linear
WHERE channel IS NOT NULL 
GROUP BY YEAR(purchase_date), MONTH(purchase_date), channel
), 
aov_metrics AS (
SELECT
    COALESCE(r.performance_year, o.performance_year) AS performance_year,
    COALESCE(r.performance_month, o.performance_month) AS performance_month,
    r.channel,
    r.current_revenue,
    o.current_orders,
    r.current_revenue/NULLIF(o.current_orders, 0) AS aov
FROM monthly_revenue r
INNER JOIN monthly_orders o
ON r.performance_year = o.performance_year
    AND r.performance_month = o.performance_month 
    AND r.channel = o.channel

)

SELECT 
    performance_year,
    performance_month,
    channel,
    current_revenue,
    current_orders,
    aov AS current_aov,
    AVG(aov) OVER(PARTITION BY channel) AS avg_aov,
    (aov) - AVG(aov) OVER(PARTITION BY channel) AS diff_avg,
    CASE 
        WHEN (aov) - AVG(aov) OVER(PARTITION BY channel) > 0 THEN 'Above Avg'
        WHEN (aov) - AVG(aov) OVER(PARTITION BY channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(aov) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) AS pm_aov, 
    (aov) - LAG(aov) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) AS diff_pm_aov,
    CASE 
        WHEN (aov) - LAG(aov) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN (aov) - LAG(aov) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(aov) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((aov) - LAG(aov) OVER(PARTITION BY channel ORDER BY performance_year, performance_month))/LAG(aov) OVER(PARTITION BY channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM aov_metrics;
GO

SELECT *
FROM gold.channels_aov
WHERE current_orders > 0
ORDER BY channel, performance_year, performance_month;
GO


--=====================================
-- 4.2) TOFU Top of Funnel Contributers
--=====================================
-- MoM by Full Purchase Revenues and Monthly Orders
-- Analyze Month-over-Month aov performance by acquisition channel to see the quality of new users
DROP VIEW IF EXISTS gold.acquisition_channels_aov;
GO

CREATE VIEW gold.acquisition_channels_aov AS
WITH monthly_revenue AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    p.acquisition_channel, 
    SUM(f.revenue_share) AS current_revenue 
FROM gold.fact_attribution_linear f
LEFT JOIN gold.fact_purchases p 
ON f.purchase_id = p.purchase_id
WHERE p.acquisition_channel IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), p.acquisition_channel
), 
monthly_orders AS (
SELECT 
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month,
    p.acquisition_channel, 
    COUNT(DISTINCT f.purchase_id) AS current_orders
FROM gold.fact_attribution_linear f 
LEFT JOIN gold.fact_purchases p 
ON f.purchase_id = p.purchase_id 
WHERE p.acquisition_channel IS NOT NULL 
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), p.acquisition_channel
),
aov_metrics AS (
SELECT
    COALESCE(r.performance_year, o.performance_year) AS performance_year,
    COALESCE(r.performance_month, o.performance_month) AS performance_month,
    r.acquisition_channel, 
    r.current_revenue,
    o.current_orders,
    r.current_revenue/NULLIF(o.current_orders, 0) AS aov
FROM monthly_revenue r
INNER JOIN monthly_orders o
ON r.performance_year = o.performance_year
    AND r.performance_month = o.performance_month 
    AND r.acquisition_channel = o.acquisition_channel
)

SELECT 
    performance_year,
    performance_month,
    acquisition_channel, 
    current_revenue,
    current_orders,
    aov AS current_aov,
    AVG(aov) OVER(PARTITION BY acquisition_channel) AS avg_aov,
    (aov) - AVG(aov) OVER(PARTITION BY acquisition_channel) AS diff_avg,
    CASE 
        WHEN (aov) - AVG(aov) OVER(PARTITION BY acquisition_channel) > 0 THEN 'Above Avg'
        WHEN (aov) - AVG(aov) OVER(PARTITION BY acquisition_channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(aov) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) AS pm_aov, 
    (aov) - LAG(aov) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) AS diff_pm_aov,
    CASE 
        WHEN (aov) - LAG(aov) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN (aov) - LAG(aov) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(aov) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((aov) - LAG(aov) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month))/LAG(aov) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM aov_metrics;
GO

SELECT *
FROM gold.acquisition_channels_aov
WHERE current_orders > 0
ORDER BY acquisition_channel, performance_year, performance_month;
GO



--==============================================
-- 4.3) BOFU Bottom of Funnel Conversion Drivers
--==============================================
-- MoM by Full Purchase Revenues and Monthly Orders
-- Analyze Month-over-Month aov performance by last-touch channels to see closing stage value
DROP VIEW IF EXISTS gold.last_touch_channels_aov;
GO

CREATE VIEW gold.last_touch_channels_aov AS
WITH monthly_revenue AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    f.last_touch_channel, 
    SUM(f.revenue) AS current_revenue 
FROM gold.fact_attribution_last_touch f
WHERE f.last_touch_channel IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), f.last_touch_channel
), 
monthly_orders AS (
SELECT 
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month,
    last_touch_channel, 
    COUNT(purchase_id) AS current_orders
FROM gold.fact_attribution_last_touch
WHERE last_touch_channel IS NOT NULL 
GROUP BY YEAR(purchase_date), MONTH(purchase_date), last_touch_channel
), 
aov_metrics AS (
SELECT
    COALESCE(r.performance_year, o.performance_year) AS performance_year,
    COALESCE(r.performance_month, o.performance_month) AS performance_month,
    r.last_touch_channel,
    r.current_revenue,
    o.current_orders,
    r.current_revenue/NULLIF(o.current_orders, 0) AS aov
FROM monthly_revenue r
INNER JOIN monthly_orders o
ON r.performance_year = o.performance_year
    AND r.performance_month = o.performance_month 
    AND r.last_touch_channel = o.last_touch_channel
)

SELECT 
    performance_year,
    performance_month,
    last_touch_channel,
    current_revenue,
    current_orders,
    aov AS current_aov,
    AVG(aov) OVER(PARTITION BY last_touch_channel) AS avg_aov,
    (aov) - AVG(aov) OVER(PARTITION BY last_touch_channel) AS diff_avg,
    CASE 
        WHEN (aov) - AVG(aov) OVER(PARTITION BY last_touch_channel) > 0 THEN 'Above Avg'
        WHEN (aov) - AVG(aov) OVER(PARTITION BY last_touch_channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,

    -- Month-over_Month Analysis 
    LAG(aov) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) AS pm_aov, 
    (aov) - LAG(aov) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) AS diff_pm_aov,
    CASE 
        WHEN (aov) - LAG(aov) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN (aov) - LAG(aov) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(aov) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((aov) - LAG(aov) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month))/LAG(aov) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM aov_metrics;
GO

SELECT *
FROM gold.last_touch_channels_aov
WHERE current_orders > 0 
ORDER BY last_touch_channel, performance_year, performance_month;
GO