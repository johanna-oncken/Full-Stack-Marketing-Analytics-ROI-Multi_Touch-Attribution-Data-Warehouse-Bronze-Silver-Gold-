/*
===============================================================================
ARPU Average Revenue per User Performance Analysis (Month-over-Month)
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
    1) ARPU overall 
    2) ARPU Performances monthly 
    3.1) Mid of Funnel (MOFU) Monthly ARPU Performance and MOM-Analysis by Campaigns
    3.2) Top of Funnel (TOFU) Monthly ARPU Performance and MOM-Analysis by Campaigns
    3.3) Bottom of Funnel (BOFU) Monthly ARPU Performance and MOM-Analysis by Campaigns
    4.1) Mid of Funnel (MOFU) Monthly ARPU Performance and MOM-Analysis by Channels
    4.2) Top of Funnel (TOFU) Monthly ARPU Performance and MOM-Analysis by Channels
    4.3) Bottom of Funnel (BOFU) Monthly ARPU Performance and MOM-Analysis by Channels

===============================================================================
*/
USE marketing_dw; 
GO

/*
===============================================================================
1) ARPU overall
===============================================================================
*/
SELECT 
    (SELECT SUM(revenue_share) FROM gold.fact_attribution_linear) AS revenue,
    (SELECT COUNT(distinct user_id) FROM gold.fact_attribution_linear) AS users,
    (SELECT SUM(revenue_share) FROM gold.fact_attribution_linear) 
    / 
    (SELECT COUNT(distinct user_id) FROM gold.fact_attribution_linear) AS arpu;


/*
===============================================================================
2) ARPU Performances monthly
===============================================================================
*/
DROP VIEW IF EXISTS gold.arpu;
GO

CREATE VIEW gold.arpu AS
WITH monthly_revenue AS (
SELECT
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month, 
    SUM(revenue_share) AS current_revenue 
FROM gold.fact_attribution_linear 
GROUP BY YEAR(purchase_date), MONTH(purchase_date)
), 
monthly_users AS (
SELECT 
    YEAR(p.purchase_date) AS performance_year,
    MONTH(p.purchase_date) AS performance_month,
    COUNT(DISTINCT p.user_id) AS current_users
FROM gold.fact_attribution_linear f 
LEFT JOIN gold.fact_purchases p 
ON f.purchase_id = p.purchase_id 
GROUP BY YEAR(p.purchase_date), MONTH(p.purchase_date)
), 
arpu_metrics AS (
SELECT
    COALESCE(r.performance_year, u.performance_year) AS performance_year,
    COALESCE(r.performance_month, u.performance_month) AS performance_month,
    r.current_revenue,
    u.current_users,
    r.current_revenue/NULLIF(u.current_users, 0) AS arpu
FROM monthly_revenue r
INNER JOIN monthly_users u
ON r.performance_year = u.performance_year
    AND r.performance_month = u.performance_month 
)

SELECT 
    performance_year,
    performance_month,
    current_revenue,
    current_users AS active_users,
    arpu AS current_arpu,
    AVG(arpu) OVER() AS avg_arpu,
    (arpu) - AVG(arpu) OVER() AS diff_avg,
    CASE 
        WHEN (arpu) - AVG(arpu) OVER() > 0 THEN 'Above Avg'
        WHEN (arpu) - AVG(arpu) OVER() < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(arpu) OVER(ORDER BY performance_year, performance_month) AS pm_arpu, 
    (arpu) - LAG(arpu) OVER(ORDER BY performance_year, performance_month) AS diff_pm_arpu,
    CASE 
        WHEN (arpu) - LAG(arpu) OVER(ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN (arpu) - LAG(arpu) OVER(ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(arpu) OVER(ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((arpu) - LAG(arpu) OVER(ORDER BY performance_year, performance_month))/LAG(arpu) OVER(ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM arpu_metrics;
GO

SELECT *
FROM gold.arpu
WHERE active_users > 0
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
-- MoM by Multi-Touch Revenue Shares and Active Users
-- Analyze Month-over-Month ARPU performance of campaigns by comparing their ARPU to both the average ARPU performance of the campaign and the previous month ARPU
DROP VIEW IF EXISTS gold.campaigns_arpu;
GO

CREATE VIEW gold.campaigns_arpu AS
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
monthly_users AS (
SELECT 
    YEAR(p.purchase_date) AS performance_year,
    MONTH(p.purchase_date) AS performance_month,
    f.campaign_id, 
    COUNT(DISTINCT p.user_id) AS current_users
FROM gold.fact_attribution_linear f 
LEFT JOIN gold.fact_purchases p 
ON f.purchase_id = p.purchase_id
WHERE f.campaign_id IS NOT NULL 
GROUP BY YEAR(p.purchase_date), MONTH(p.purchase_date), f.campaign_id
), 
arpu_metrics AS (
SELECT
    COALESCE(r.performance_year, u.performance_year) AS performance_year,
    COALESCE(r.performance_month, u.performance_month) AS performance_month,
    r.campaign_id, 
    r.campaign_name,
    r.current_revenue,
    u.current_users,
    r.current_revenue/NULLIF(u.current_users, 0) AS arpu
FROM monthly_revenue r
INNER JOIN monthly_users u
ON r.performance_year = u.performance_year
    AND r.performance_month = u.performance_month 
    AND r.campaign_id = u.campaign_id

)

SELECT 
    performance_year,
    performance_month,
    campaign_id, 
    campaign_name,
    current_revenue,
    current_users AS active_users,
    arpu AS current_arpu,
    AVG(arpu) OVER(PARTITION BY campaign_id) AS avg_arpu,
    (arpu) - AVG(arpu) OVER(PARTITION BY campaign_id) AS diff_avg,
    CASE 
        WHEN (arpu) - AVG(arpu) OVER(PARTITION BY campaign_id) > 0 THEN 'Above Avg'
        WHEN (arpu) - AVG(arpu) OVER(PARTITION BY campaign_id) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(arpu) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS pm_arpu, 
    (arpu) - LAG(arpu) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS diff_pm_arpu,
    CASE 
        WHEN (arpu) - LAG(arpu) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN (arpu) - LAG(arpu) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(arpu) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((arpu) - LAG(arpu) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month))/LAG(arpu) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM arpu_metrics;
GO

SELECT *
FROM gold.campaigns_arpu
WHERE active_users > 0
ORDER BY campaign_id, performance_year, performance_month;
GO


--==================================
-- 3.2) TOFU Top of Funnel Contributers
--=================================
-- MoM by Full Purchase Revenues and Active Users
-- Analyze Month-over-Month ARPU performance by acquisition campaign 
DROP VIEW IF EXISTS gold.acquisition_campaigns_arpu;
GO

CREATE VIEW gold.acquisition_campaigns_arpu AS
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
monthly_users AS (
SELECT 
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month,
    acquisition_campaign, 
    COUNT(DISTINCT user_id) AS current_users
FROM gold.fact_purchases 
WHERE acquisition_campaign IS NOT NULL 
GROUP BY YEAR(purchase_date), MONTH(purchase_date), acquisition_campaign
), 
arpu_metrics AS (
SELECT
    COALESCE(r.performance_year, u.performance_year) AS performance_year,
    COALESCE(r.performance_month, u.performance_month) AS performance_month,
    r.acquisition_campaign, 
    r.campaign_name,
    r.current_revenue,
    u.current_users,
    r.current_revenue/NULLIF(u.current_users, 0) AS arpu
FROM monthly_revenue r
INNER JOIN monthly_users u
ON r.performance_year = u.performance_year
    AND r.performance_month = u.performance_month 
    AND r.acquisition_campaign = u.acquisition_campaign
)

SELECT 
    performance_year,
    performance_month,
    acquisition_campaign, 
    campaign_name,
    current_revenue,
    current_users AS active_users,
    arpu AS current_arpu,
    AVG(arpu) OVER(PARTITION BY acquisition_campaign) AS avg_arpu,
    (arpu) - AVG(arpu) OVER(PARTITION BY acquisition_campaign) AS diff_avg,
    CASE 
        WHEN (arpu) - AVG(arpu) OVER(PARTITION BY acquisition_campaign) > 0 THEN 'Above Avg'
        WHEN (arpu) - AVG(arpu) OVER(PARTITION BY acquisition_campaign) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(arpu) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) AS pm_arpu, 
    (arpu) - LAG(arpu) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) AS diff_pm_arpu,
    CASE 
        WHEN (arpu) - LAG(arpu) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN (arpu) - LAG(arpu) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(arpu) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((arpu) - LAG(arpu) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month))/LAG(arpu) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM arpu_metrics;
GO

SELECT *
FROM gold.acquisition_campaigns_arpu
WHERE active_users > 0
ORDER BY acquisition_campaign, performance_year, performance_month;
GO


--==========================================
-- 3.3) BOFU Bottom of Funnel Conversion Drivers
--==========================================
-- MoM by Full Purchase Revenues and Active Users
-- Analyze Month-over-Month ARPU performance by last-touch campaign 
DROP VIEW IF EXISTS gold.last_touch_campaigns_arpu;
GO

CREATE VIEW gold.last_touch_campaigns_arpu AS
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
monthly_users AS (
SELECT 
    YEAR(p.purchase_date) AS performance_year,
    MONTH(p.purchase_date) AS performance_month,
    f.last_touch_campaign, 
    COUNT(DISTINCT p.user_id) AS current_users
FROM gold.fact_attribution_last_touch f 
LEFT JOIN gold.fact_purchases p 
ON f.purchase_id = p.purchase_id
WHERE f.last_touch_campaign IS NOT NULL 
GROUP BY YEAR(p.purchase_date), MONTH(p.purchase_date), f.last_touch_campaign
), 
arpu_metrics AS (
SELECT
    COALESCE(r.performance_year, u.performance_year) AS performance_year,
    COALESCE(r.performance_month, u.performance_month) AS performance_month,
    r.last_touch_campaign, 
    r.campaign_name,
    r.current_revenue,
    u.current_users,
    r.current_revenue/NULLIF(u.current_users, 0) AS arpu
FROM monthly_revenue r
INNER JOIN monthly_users u
ON r.performance_year = u.performance_year
    AND r.performance_month = u.performance_month 
    AND r.last_touch_campaign = u.last_touch_campaign
)

SELECT 
    performance_year,
    performance_month,
    last_touch_campaign, 
    campaign_name,
    current_revenue,
    current_users AS active_users,
    arpu AS current_arpu,
    AVG(arpu) OVER(PARTITION BY last_touch_campaign) AS avg_arpu,
    (arpu) - AVG(arpu) OVER(PARTITION BY last_touch_campaign) AS diff_avg,
    CASE 
        WHEN (arpu) - AVG(arpu) OVER(PARTITION BY last_touch_campaign) > 0 THEN 'Above Avg'
        WHEN (arpu) - AVG(arpu) OVER(PARTITION BY last_touch_campaign) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(arpu) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) AS pm_arpu, 
    (arpu) - LAG(arpu) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) AS diff_pm_arpu,
    CASE 
        WHEN (arpu) - LAG(arpu) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN (arpu) - LAG(arpu) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(arpu) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((arpu) - LAG(arpu) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month))/LAG(arpu) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM arpu_metrics;
GO

SELECT *
FROM gold.last_touch_campaigns_arpu
WHERE active_users > 0 
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
-- MoM by Multi-Touch Revenue Shares and Active Users
-- Analyze Month-over-Month ARPU performance of channels by comparing their ARPU to both the average ARPU performance of the channel and the previous month ARPU 
DROP VIEW IF EXISTS gold.channels_arpu;
GO

CREATE VIEW gold.channels_arpu AS
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
monthly_users AS (
SELECT 
    YEAR(p.purchase_date) AS performance_year,
    MONTH(p.purchase_date) AS performance_month,
    f.channel, 
    COUNT(DISTINCT p.user_id) AS current_users
FROM gold.fact_attribution_linear f 
LEFT JOIN gold.fact_purchases p 
ON f.purchase_id = p.purchase_id
WHERE f.channel IS NOT NULL 
GROUP BY YEAR(p.purchase_date), MONTH(p.purchase_date), f.channel
), 
arpu_metrics AS (
SELECT
    COALESCE(r.performance_year, u.performance_year) AS performance_year,
    COALESCE(r.performance_month, u.performance_month) AS performance_month,
    r.channel,
    r.current_revenue,
    u.current_users,
    r.current_revenue/NULLIF(u.current_users, 0) AS arpu
FROM monthly_revenue r
INNER JOIN monthly_users u
ON r.performance_year = u.performance_year
    AND r.performance_month = u.performance_month 
    AND r.channel = u.channel

)

SELECT 
    performance_year,
    performance_month,
    channel,
    current_revenue,
    current_users AS active_users,
    arpu AS current_arpu,
    AVG(arpu) OVER(PARTITION BY channel) AS avg_arpu,
    (arpu) - AVG(arpu) OVER(PARTITION BY channel) AS diff_avg,
    CASE 
        WHEN (arpu) - AVG(arpu) OVER(PARTITION BY channel) > 0 THEN 'Above Avg'
        WHEN (arpu) - AVG(arpu) OVER(PARTITION BY channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(arpu) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) AS pm_arpu, 
    (arpu) - LAG(arpu) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) AS diff_pm_arpu,
    CASE 
        WHEN (arpu) - LAG(arpu) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN (arpu) - LAG(arpu) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(arpu) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((arpu) - LAG(arpu) OVER(PARTITION BY channel ORDER BY performance_year, performance_month))/LAG(arpu) OVER(PARTITION BY channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM arpu_metrics;
GO

SELECT *
FROM gold.channels_arpu
WHERE active_users > 0
ORDER BY channel, performance_year, performance_month;
GO


--=====================================
-- 3.2) TOFU Top of Funnel Contributers
--=====================================
-- MoM by Full Purchase Revenues and Active Users
-- Analyze Month-over-Month ARPU performance by acquisition channel to see the quality of new users
DROP VIEW IF EXISTS gold.acquisition_channels_arpu;
GO

CREATE VIEW gold.acquisition_channels_arpu AS
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
monthly_users AS (
SELECT 
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month,
    acquisition_channel, 
    COUNT(DISTINCT user_id) AS current_users
FROM gold.fact_purchases 
WHERE acquisition_channel IS NOT NULL 
GROUP BY YEAR(purchase_date), MONTH(purchase_date), acquisition_channel
),
arpu_metrics AS (
SELECT
    COALESCE(r.performance_year, u.performance_year) AS performance_year,
    COALESCE(r.performance_month, u.performance_month) AS performance_month,
    r.acquisition_channel, 
    r.current_revenue,
    u.current_users,
    r.current_revenue/NULLIF(u.current_users, 0) AS arpu
FROM monthly_revenue r
INNER JOIN monthly_users u
ON r.performance_year = u.performance_year
    AND r.performance_month = u.performance_month 
    AND r.acquisition_channel = u.acquisition_channel
)

SELECT 
    performance_year,
    performance_month,
    acquisition_channel, 
    current_revenue,
    current_users AS active_users,
    arpu AS current_arpu,
    AVG(arpu) OVER(PARTITION BY acquisition_channel) AS avg_arpu,
    (arpu) - AVG(arpu) OVER(PARTITION BY acquisition_channel) AS diff_avg,
    CASE 
        WHEN (arpu) - AVG(arpu) OVER(PARTITION BY acquisition_channel) > 0 THEN 'Above Avg'
        WHEN (arpu) - AVG(arpu) OVER(PARTITION BY acquisition_channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(arpu) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) AS pm_arpu, 
    (arpu) - LAG(arpu) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) AS diff_pm_arpu,
    CASE 
        WHEN (arpu) - LAG(arpu) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN (arpu) - LAG(arpu) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(arpu) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((arpu) - LAG(arpu) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month))/LAG(arpu) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM arpu_metrics;
GO

SELECT *
FROM gold.acquisition_channels_arpu
WHERE active_users > 0
ORDER BY acquisition_channel, performance_year, performance_month;
GO


--==============================================
-- 3.3) BOFU Bottom of Funnel Conversion Drivers
--==============================================
-- MoM by Full Purchase Revenues and Active Users
-- Analyze Month-over-Month ARPU performance by last-touch channels to see closing stage value
DROP VIEW IF EXISTS gold.last_touch_channels_arpu;
GO

CREATE VIEW gold.last_touch_channels_arpu AS
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
monthly_users AS (
SELECT 
    YEAR(p.purchase_date) AS performance_year,
    MONTH(p.purchase_date) AS performance_month,
    f.last_touch_channel, 
    COUNT(DISTINCT p.user_id) AS current_users
FROM gold.fact_attribution_last_touch f
LEFT JOIN gold.fact_purchases p 
ON f.purchase_id = p.purchase_id
WHERE f.last_touch_channel IS NOT NULL 
GROUP BY YEAR(p.purchase_date), MONTH(p.purchase_date), f.last_touch_channel
), 
arpu_metrics AS (
SELECT
    COALESCE(r.performance_year, u.performance_year) AS performance_year,
    COALESCE(r.performance_month, u.performance_month) AS performance_month,
    r.last_touch_channel,
    r.current_revenue,
    u.current_users,
    r.current_revenue/NULLIF(u.current_users, 0) AS arpu
FROM monthly_revenue r
INNER JOIN monthly_users u
ON r.performance_year = u.performance_year
    AND r.performance_month = u.performance_month 
    AND r.last_touch_channel = u.last_touch_channel
)

SELECT 
    performance_year,
    performance_month,
    last_touch_channel,
    current_revenue,
    current_users AS active_users,
    arpu AS current_arpu,
    AVG(arpu) OVER(PARTITION BY last_touch_channel) AS avg_arpu,
    (arpu) - AVG(arpu) OVER(PARTITION BY last_touch_channel) AS diff_avg,
    CASE 
        WHEN (arpu) - AVG(arpu) OVER(PARTITION BY last_touch_channel) > 0 THEN 'Above Avg'
        WHEN (arpu) - AVG(arpu) OVER(PARTITION BY last_touch_channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,

    -- Month-over_Month Analysis 
    LAG(arpu) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) AS pm_arpu, 
    (arpu) - LAG(arpu) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) AS diff_pm_arpu,
    CASE 
        WHEN (arpu) - LAG(arpu) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN (arpu) - LAG(arpu) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(arpu) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((arpu) - LAG(arpu) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month))/LAG(arpu) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM arpu_metrics;
GO

SELECT *
FROM gold.last_touch_channels_arpu
WHERE active_users > 0 
ORDER BY last_touch_channel, performance_year, performance_month;
GO

