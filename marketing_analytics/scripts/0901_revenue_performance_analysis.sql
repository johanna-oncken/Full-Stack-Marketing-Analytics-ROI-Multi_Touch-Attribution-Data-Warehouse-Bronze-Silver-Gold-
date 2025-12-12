/*
===============================================================================
Revenue Performance Analysis (Month-over-Month)
===============================================================================
Purpose:
    - To measure the performance of marketing components such as campagins, channels and interaction types over time.
    - For benchmarking and identifying high-performing entities.
    - To track monthly 2024 trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis. 

Queries: 
    1) Revenue Performance monthly
    2.1) Mid of Funnel (MOFU) Monthly Revenue Performance and MOM-Analysis by Campaigns
    2.2) Top of Funnel (TOFU) Monthly Revenue Performance and MOM-Analysis by Campaigns
    2.3) Bottom of Funnel (BOFU) Monthly Revenue Performance and MOM-Analysis by Campaigns
    2.4) Top Ten MOM Campaigns by TOFU/MOFU/BOFU 
    3.1) Mid of Funnel (MOFU) Monthly Revenue Performance and MOM-Analysis by Channels
    3.2) Top of Funnel (TOFU) Monthly Revenue Performance and MOM-Analysis by Channels
    3.3) Bottom of Funnel (BOFU) Monthly Revenue Performance and MOM-Analysis by Channels
    3.4) Top Ten MOM Channels by TOFU/MOFU/BOFU 
    4.1) Mid of Funnel (MOFU) Monthly Revenue Performance and MOM-Analysis by Interaction Type
    4.2) Top Ten MOM Interaction Types by MUFO

===============================================================================
*/
USE marketing_dw; 
GO

/*
===============================================================================
1) Revenue Performance monthly
===============================================================================
*/ 
DROP VIEW IF EXISTS gold.revenue;
GO

CREATE VIEW gold.revenue AS
WITH monthly_revenue AS (
    SELECT 
        YEAR(purchase_date) AS performance_year,
        MONTH(purchase_date) AS performance_month,
        SUM(revenue) AS current_revenue 
    FROM gold.fact_purchases 
    GROUP BY YEAR(purchase_date), MONTH(purchase_date)
)

SELECT 
    performance_year,
    performance_month,
    current_revenue,
    AVG(current_revenue) OVER() AS avg_current_revenue,
    (current_revenue) - AVG(current_revenue) OVER() AS diff_avg,
    CASE 
        WHEN (current_revenue) - AVG(current_revenue) OVER() > 0 THEN 'Above Avg'
        WHEN (current_revenue) - AVG(current_revenue) OVER() < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(current_revenue) OVER(ORDER BY performance_year, performance_month) AS pm_current_revenue, 
    (current_revenue) - LAG(current_revenue) OVER(ORDER BY performance_year, performance_month) AS diff_pm_current_revenue,
    CASE 
        WHEN (current_revenue) - LAG(current_revenue) OVER(ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN (current_revenue) - LAG(current_revenue) OVER(ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(current_revenue) OVER(ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE ((current_revenue) - LAG(current_revenue) OVER(ORDER BY performance_year, performance_month))/LAG(current_revenue) OVER(ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM monthly_revenue;
GO

SELECT *
FROM gold.revenue
ORDER BY performance_year, performance_month;
GO


/*
===============================================================================
2) CAMPAIGNS
===============================================================================
*/
--===================================
-- 2.1) MOFU Full-Funnel Contributers
--=================================== 
-- MoM by Multi-Touch Revenue Shares
-- Analyze Month-over-Month performance of campaigns by comparing their revenue to both the average revenue performance of the campaign and the previous month evenue 
DROP VIEW IF EXISTS gold.funnel_campaigns_performance;
GO

CREATE VIEW gold.funnel_campaigns_performance AS
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
) 
SELECT 
    performance_year,
    performance_month,
    campaign_id, 
    campaign_name,
    current_revenue,
    AVG(current_revenue) OVER(PARTITION BY campaign_id) AS avg_revenue,
    current_revenue - AVG(current_revenue) OVER(PARTITION BY campaign_id) AS diff_avg,
    CASE 
        WHEN current_revenue - AVG(current_revenue) OVER(PARTITION BY campaign_id) > 0 THEN 'Above Avg'
        WHEN current_revenue - AVG(current_revenue) OVER(PARTITION BY campaign_id) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(current_revenue) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS pm_revenue, 
    current_revenue - LAG(current_revenue) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) AS diff_pm,
    CASE 
        WHEN current_revenue - LAG(current_revenue) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN current_revenue - LAG(current_revenue) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(current_revenue) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE (current_revenue - LAG(current_revenue) OVER(PARTITION BY   campaign_id ORDER BY performance_year, performance_month))/LAG(current_revenue) OVER(PARTITION BY campaign_id ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM monthly_revenue;
GO

SELECT *
FROM gold.funnel_campaigns_performance
ORDER BY campaign_id, performance_year, performance_month;
GO

--=====================================
-- 2.2) TOFU Top of Funnel Contributers
--=====================================
-- MoM by Full Purchase Revenues
-- Analyze Month-over-Month performance by acquisition campaign to see which campaigns are bringing users in
DROP VIEW IF EXISTS gold.acquisition_campaigns_performance;
GO

CREATE VIEW gold.acquisition_campaigns_performance AS
WITH monthly_revenue AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    f.acquisition_campaign, 
    c.campaign_name,
    SUM(revenue) AS current_revenue 
FROM gold.fact_purchases f 
LEFT JOIN gold.dim_campaign c 
ON f.acquisition_campaign = c.campaign_id
WHERE f.acquisition_campaign IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), f.acquisition_campaign, c.campaign_name
) 
SELECT 
    performance_year,
    performance_month,
    acquisition_campaign, 
    campaign_name,
    current_revenue,
    AVG(current_revenue) OVER(PARTITION BY acquisition_campaign) AS avg_revenue,
    current_revenue - AVG(current_revenue) OVER(PARTITION BY acquisition_campaign) AS diff_avg,
    CASE 
        WHEN current_revenue - AVG(current_revenue) OVER(PARTITION BY acquisition_campaign) > 0 THEN 'Above Avg'
        WHEN current_revenue - AVG(current_revenue) OVER(PARTITION BY acquisition_campaign) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(current_revenue) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) AS pm_revenue, 
    current_revenue - LAG(current_revenue) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) AS diff_pm,
    CASE 
        WHEN current_revenue - LAG(current_revenue) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN current_revenue - LAG(current_revenue) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(current_revenue) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE (current_revenue - LAG(current_revenue) OVER(PARTITION BY   acquisition_campaign ORDER BY performance_year, performance_month))/LAG(current_revenue) OVER(PARTITION BY acquisition_campaign ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM monthly_revenue;
GO 

SELECT * 
FROM gold.acquisition_campaigns_performance
ORDER BY acquisition_campaign, performance_year, performance_month;
GO

--==============================================
-- 2.3) BOFU Bottom of Funnel Conversion Drivers
--==============================================
-- MoM by Full Purchase Revenues 
-- Analyze Month-over-Month performance by last-touch campaign to see which campaigns are driving conversion
DROP VIEW IF EXISTS gold.last_touch_campaigns_performance;
GO

CREATE VIEW gold.last_touch_campaigns_performance AS
WITH monthly_revenue AS (
SELECT
    YEAR(f.purchase_date) AS performance_year,
    MONTH(f.purchase_date) AS performance_month, 
    f.last_touch_campaign, 
    c.campaign_name,
    SUM(revenue) AS current_revenue 
FROM gold.fact_attribution_last_touch f 
LEFT JOIN gold.dim_campaign c 
ON f.last_touch_campaign = c.campaign_id
WHERE f.last_touch_campaign IS NOT NULL
GROUP BY YEAR(f.purchase_date), MONTH(f.purchase_date), f.last_touch_campaign, c.campaign_name
) 
SELECT 
    performance_year,
    performance_month,
    last_touch_campaign, 
    campaign_name,
    current_revenue,
    AVG(current_revenue) OVER(PARTITION BY last_touch_campaign) AS avg_revenue,
    current_revenue - AVG(current_revenue) OVER(PARTITION BY last_touch_campaign) AS diff_avg,
    CASE 
        WHEN current_revenue - AVG(current_revenue) OVER(PARTITION BY last_touch_campaign) > 0 THEN 'Above Avg'
        WHEN current_revenue - AVG(current_revenue) OVER(PARTITION BY last_touch_campaign) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(current_revenue) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) AS pm_revenue, 
    current_revenue - LAG(current_revenue) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) AS diff_pm,
    CASE 
        WHEN current_revenue - LAG(current_revenue) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN current_revenue - LAG(current_revenue) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(current_revenue) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE (current_revenue - LAG(current_revenue) OVER(PARTITION BY   last_touch_campaign ORDER BY performance_year, performance_month))/LAG(current_revenue) OVER(PARTITION BY last_touch_campaign ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM monthly_revenue;
GO 

SELECT * 
FROM gold.last_touch_campaigns_performance
ORDER BY last_touch_campaign, performance_year, performance_month;


--==================================
-- 2.4) TOP 10 MoM TOFU/Multi/BOFU 
--==================================
-- Top 10 MoM campaigns within funnel
SELECT TOP 10 *
FROM gold.funnel_campaigns_performance
ORDER BY diff_pm DESC; 

SELECT TOP 10 *
FROM gold.funnel_campaigns_performance
WHERE pm_revenue > 0
ORDER BY mom_percentage DESC;

-- Top 10 MoM acquisition campaigns
SELECT TOP 10 *
FROM gold.acquisition_campaigns_performance
ORDER BY diff_pm DESC; 

SELECT TOP 10 *
FROM gold.acquisition_campaigns_performance
WHERE pm_revenue > 0
ORDER BY mom_percentage DESC;

-- Top 10 MoM last-touch campaigns
SELECT TOP 10 *
FROM gold.last_touch_campaigns_performance
ORDER BY diff_pm DESC; 

SELECT TOP 10 *
FROM gold.last_touch_campaigns_performance
WHERE pm_revenue > 0
ORDER BY mom_percentage DESC;


/*
===============================================================================
3) CHANNELS
===============================================================================
*/
--===================================
-- 3.1) MOFU Full-Funnel Contributers
--=================================== 
-- MoM by Multi-Touch Revenue Shares
-- Analyze Month-over-Month performance of channels by comparing their revenue to both the average revenue performance of the channel and the previous month revenue 
DROP VIEW IF EXISTS gold.funnel_channels_performance;
GO

CREATE VIEW gold.funnel_channels_performance AS
WITH monthly_revenue AS (
SELECT
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month, 
    channel, 
    SUM(revenue_share) AS current_revenue 
FROM gold.fact_attribution_linear 
GROUP BY YEAR(purchase_date), MONTH(purchase_date), channel
) 
SELECT 
    performance_year,
    performance_month,
    channel,
    current_revenue,
    AVG(current_revenue) OVER(PARTITION BY channel) AS avg_revenue,
    current_revenue - AVG(current_revenue) OVER(PARTITION BY channel) AS diff_avg,
    CASE 
        WHEN current_revenue - AVG(current_revenue) OVER(PARTITION BY channel) > 0 THEN 'Above Avg'
        WHEN current_revenue - AVG(current_revenue) OVER(PARTITION BY channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(current_revenue) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) AS pm_revenue, 
    current_revenue - LAG(current_revenue) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) AS diff_pm,
    CASE 
        WHEN current_revenue - LAG(current_revenue) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN current_revenue - LAG(current_revenue) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(current_revenue) OVER(PARTITION BY channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE (current_revenue - LAG(current_revenue) OVER(PARTITION BY   channel ORDER BY performance_year, performance_month))/LAG(current_revenue) OVER(PARTITION BY channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM monthly_revenue;
GO

SELECT *
FROM gold.funnel_channels_performance
ORDER BY channel, performance_year, performance_month;
GO

--=====================================
-- 3.2) TOFU Top of Funnel Contributers
--=====================================
-- MoM by Full Purchase Revenues
-- Analyze Month-over-Month performance by acquisition channel to see which channels are bringing users in
DROP VIEW IF EXISTS gold.acquisition_channels_performance;
GO

CREATE VIEW gold.acquisition_channels_performance AS
WITH monthly_revenue AS (
SELECT
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month, 
    acquisition_channel, 
    SUM(revenue) AS current_revenue 
FROM gold.fact_purchases 
GROUP BY YEAR(purchase_date), MONTH(purchase_date), acquisition_channel
) 
SELECT 
    performance_year,
    performance_month,
    acquisition_channel,
    current_revenue,
    AVG(current_revenue) OVER(PARTITION BY acquisition_channel) AS avg_revenue,
    current_revenue - AVG(current_revenue) OVER(PARTITION BY acquisition_channel) AS diff_avg,
    CASE 
        WHEN current_revenue - AVG(current_revenue) OVER(PARTITION BY acquisition_channel) > 0 THEN 'Above Avg'
        WHEN current_revenue - AVG(current_revenue) OVER(PARTITION BY acquisition_channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(current_revenue) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) AS pm_revenue, 
    current_revenue - LAG(current_revenue) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) AS diff_pm,
    CASE 
        WHEN current_revenue - LAG(current_revenue) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN current_revenue - LAG(current_revenue) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(current_revenue) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE (current_revenue - LAG(current_revenue) OVER(PARTITION BY   acquisition_channel ORDER BY performance_year, performance_month))/LAG(current_revenue) OVER(PARTITION BY acquisition_channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM monthly_revenue;
GO 

SELECT * 
FROM gold.acquisition_channels_performance
ORDER BY acquisition_channel, performance_year, performance_month;
GO


--==============================================
-- 3.3) BOFU Bottom of Funnel Conversion Drivers
--==============================================
-- MoM by Full Purchase Revenues 
-- Analyze Month-over-Month performance by last-touch channel to see which channels are driving conversion
DROP VIEW IF EXISTS gold.last_touch_channels_performance;
GO

CREATE VIEW gold.last_touch_channels_performance AS
WITH monthly_revenue AS (
SELECT
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month, 
    last_touch_channel, 
    SUM(revenue) AS current_revenue 
FROM gold.fact_attribution_last_touch 
GROUP BY YEAR(purchase_date), MONTH(purchase_date), last_touch_channel
) 
SELECT 
    performance_year,
    performance_month,
    last_touch_channel, 
    current_revenue,
    AVG(current_revenue) OVER(PARTITION BY last_touch_channel) AS avg_revenue,
    current_revenue - AVG(current_revenue) OVER(PARTITION BY last_touch_channel) AS diff_avg,
    CASE 
        WHEN current_revenue - AVG(current_revenue) OVER(PARTITION BY last_touch_channel) > 0 THEN 'Above Avg'
        WHEN current_revenue - AVG(current_revenue) OVER(PARTITION BY last_touch_channel) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(current_revenue) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) AS pm_revenue, 
    current_revenue - LAG(current_revenue) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) AS diff_pm,
    CASE 
        WHEN current_revenue - LAG(current_revenue) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN current_revenue - LAG(current_revenue) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(current_revenue) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE (current_revenue - LAG(current_revenue) OVER(PARTITION BY   last_touch_channel ORDER BY performance_year, performance_month))/LAG(current_revenue) OVER(PARTITION BY last_touch_channel ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM monthly_revenue;
GO 

SELECT * 
FROM gold.last_touch_channels_performance
ORDER BY last_touch_channel, performance_year, performance_month;


--==================================
-- 3.4) TOP 10 MoM TOFU/Multi/BOFU 
--==================================
-- Top 10 MoM channels within funnel
SELECT TOP 10 *
FROM gold.funnel_channels_performance
ORDER BY diff_pm DESC;

SELECT TOP 10 *
FROM gold.funnel_channels_performance
WHERE pm_revenue > 0
ORDER BY mom_percentage DESC;

-- Top 10 MoM acquisition channels
SELECT TOP 10 *
FROM gold.acquisition_channels_performance
ORDER BY diff_pm DESC;

SELECT TOP 10 *
FROM gold.acquisition_channels_performance
WHERE pm_revenue > 0
ORDER BY mom_percentage DESC;

-- Top 10 MoM last-touch campaigns
SELECT TOP 10 *
FROM gold.last_touch_channels_performance
ORDER BY diff_pm DESC;

SELECT TOP 10 *
FROM gold.last_touch_channels_performance
WHERE pm_revenue > 0
ORDER BY mom_percentage DESC;


/*
===============================================================================
4) INTERACTION TYPES
===============================================================================
*/

--===================================
-- 4.1) MOFU Full-Funnel Contributers
--=================================== 
-- MoM by Multi-Touch Revenue Shares
-- Analyze Month-over-Month performance of interaction types by comparing their revenue to both the average revenue performance of the interaction type and the previous month revenue 
DROP VIEW IF EXISTS gold.funnel_interaction_types_performance;
GO

CREATE VIEW gold.funnel_interaction_types_performance AS
WITH monthly_revenue AS (
SELECT
    YEAR(purchase_date) AS performance_year,
    MONTH(purchase_date) AS performance_month, 
    interaction_type, 
    SUM(revenue_share) AS current_revenue 
FROM gold.fact_attribution_linear 
GROUP BY YEAR(purchase_date), MONTH(purchase_date), interaction_type
) 
SELECT 
    performance_year,
    performance_month,
    interaction_type,
    current_revenue,
    AVG(current_revenue) OVER(PARTITION BY interaction_type) AS avg_revenue,
    current_revenue - AVG(current_revenue) OVER(PARTITION BY interaction_type) AS diff_avg,
    CASE 
        WHEN current_revenue - AVG(current_revenue) OVER(PARTITION BY interaction_type) > 0 THEN 'Above Avg'
        WHEN current_revenue - AVG(current_revenue) OVER(PARTITION BY interaction_type) < 0 THEN 'Below Avg' 
        ELSE 'Equals Average'
    END AS avg_change,
    -- Month-over_Month Analysis 
    LAG(current_revenue) OVER(PARTITION BY interaction_type ORDER BY performance_year, performance_month) AS pm_revenue, 
    current_revenue - LAG(current_revenue) OVER(PARTITION BY interaction_type ORDER BY performance_year, performance_month) AS diff_pm,
    CASE 
        WHEN current_revenue - LAG(current_revenue) OVER(PARTITION BY interaction_type ORDER BY performance_year, performance_month) > 0 THEN 'Increase'
        WHEN current_revenue - LAG(current_revenue) OVER(PARTITION BY interaction_type ORDER BY performance_year, performance_month) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS pm_change,
    ROUND(
        CASE 
            WHEN LAG(current_revenue) OVER(PARTITION BY interaction_type ORDER BY performance_year, performance_month) = 0 THEN NULL 
            ELSE (current_revenue - LAG(current_revenue) OVER(PARTITION BY interaction_type ORDER BY performance_year, performance_month))/LAG(current_revenue) OVER(PARTITION BY interaction_type ORDER BY performance_year, performance_month)*100 
        END
    ,2) AS mom_percentage
FROM monthly_revenue;
GO

SELECT *
FROM gold.funnel_interaction_types_performance
ORDER BY interaction_type, performance_year, performance_month;
GO

-- 4.2) Top 5 MoM interaction types within funnel
SELECT TOP 5 *
FROM gold.funnel_interaction_types_performance
ORDER BY diff_pm DESC; 

SELECT TOP 5 *
FROM gold.funnel_interaction_types_performance
WHERE pm_revenue > 0
ORDER BY mom_percentage DESC;
