/*
===============================================================================
DDL Script: Create Gold Fact Multi Touch Tables
===============================================================================
Script Purpose:
    This script creates additional fact tables for the Gold layer in the marketing
    data warehouse. 
    The Gold layer represents the final dimension and fact tables.

    Each table performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

How to: 
    - Before running this script, run ddl_gold_dim first to create the dimension 
    tables

Usage:
    - These gold tables can be queried directly for analytics and reporting.
===============================================================================
*/
USE marketing_dw;
GO

--============================================================================
-- Create Fact: gold.fact_touchpath - Track multi touchpoints
--============================================================================
IF OBJECT_ID('gold.fact_touchpath', 'U') IS NOT NULL
    DROP TABLE gold.fact_touchpath;
GO

CREATE TABLE gold.fact_touchpath (
    touchpath_key      INT IDENTITY(1,1) PRIMARY KEY,
    user_id            INT NOT NULL,
    purchase_id        INT NOT NULL,
    touchpoint_number  INT NOT NULL,
    touchpoint_time    DATETIME2 NOT NULL,
    channel            NVARCHAR(50) NOT NULL,
    campaign_id        INT NULL,
    interaction_type   NVARCHAR(50) NOT NULL
);

-- Build touchpoints for ALL purchases
WITH all_tp AS (
    SELECT
        t.user_id,
        p.purchase_id,
        p.purchase_date,
        t.touchpoint_time,
        t.channel,
        t.campaign_id,
        t.interaction_type
    FROM silver.web_touchpoints t
    LEFT JOIN silver.crm_purchases p
        ON t.user_id = p.user_id
       AND t.touchpoint_time < p.purchase_date
), tp_numbered AS (
    SELECT
        user_id,
        purchase_id,
        touchpoint_time,
        channel,
        campaign_id,
        interaction_type,
        ROW_NUMBER() OVER (
            PARTITION BY user_id, purchase_id
            ORDER BY touchpoint_time
        ) AS touchpoint_number
    FROM all_tp
)

INSERT INTO gold.fact_touchpath (
    user_id, purchase_id, touchpoint_number, touchpoint_time,
    channel, campaign_id, interaction_type
)
SELECT
    user_id,
    purchase_id,
    touchpoint_number,
    touchpoint_time,
    channel,
    campaign_id,
    interaction_type
FROM tp_numbered
WHERE touchpoint_time IS NOT NULL
    AND user_id IS NOT NULL
    AND touchpoint_number IS NOT NULL 
    AND interaction_type IS NOT NULL
    AND channel IS NOT NULL
    AND purchase_id IS NOT NULL
ORDER BY user_id, purchase_id, touchpoint_number;
GO

--============================================================================
-- Create Fact: gold.fact_attribution_linear - revenue share and touchpoints in path
--============================================================================
IF OBJECT_ID('gold.fact_attribution_linear', 'U') IS NOT NULL
    DROP TABLE gold.fact_attribution_linear;
GO

CREATE TABLE gold.fact_attribution_linear (
    attribution_key        INT IDENTITY(1,1) PRIMARY KEY,
    user_id                INT           NOT NULL,
    purchase_id            INT           NOT NULL,
    channel                NVARCHAR(50)  NOT NULL,
    revenue_share          DECIMAL(10,2) NOT NULL,
    total_revenue          DECIMAL(10,2) NOT NULL,
    touchpoints_in_path    INT           NOT NULL,
    purchase_date          DATE          NOT NULL
);
GO

-- a) Exclude non-purchases for touchpoints per purchase
WITH tp AS (
    SELECT
        t.user_id,
        t.purchase_id,
        t.channel,
        t.touchpoint_time
    FROM gold.fact_touchpath t
    WHERE t.purchase_id IS NOT NULL           
) -- b) Count touchpoints per purchase
, tp_counts AS (
    SELECT
        user_id,
        purchase_id,
        COUNT(*) AS touchpoints_in_path
    FROM tp
    GROUP BY user_id, purchase_id
) -- c) Join with purchase revenue
, joined AS (
    SELECT
        tc.user_id,
        tc.purchase_id,
        tc.touchpoints_in_path,
        p.revenue AS total_revenue,
        p.purchase_date
    FROM tp_counts tc
    JOIN gold.fact_purchases p
        ON tc.user_id = p.user_id
       AND tc.purchase_id = p.purchase_id
)-- d) final source and revenue share
, attribution AS (
    SELECT
        t.user_id,
        t.purchase_id,
        t.channel,
        j.total_revenue,
        j.touchpoints_in_path,
        j.purchase_date,
        CASE 
            WHEN j.touchpoints_in_path = 0 THEN 0
            ELSE j.total_revenue / j.touchpoints_in_path
        END AS revenue_share
    FROM tp t
    JOIN joined j
       ON t.user_id = j.user_id
      AND t.purchase_id = j.purchase_id
)

INSERT INTO gold.fact_attribution_linear (
    user_id, purchase_id, channel, revenue_share,
    total_revenue, touchpoints_in_path, purchase_date
)
SELECT
    user_id,
    purchase_id,
    channel,
    revenue_share,
    total_revenue,
    touchpoints_in_path,
    purchase_date
FROM attribution
WHERE user_id IS NOT NULL
    AND purchase_date IS NOT NULL
    AND channel IS NOT NULL
    AND revenue_share >= 0
    AND total_revenue IS NOT NULL;
GO
--============================================================================
-- Create Fact: gold.fact_attribution_last_touch - last touch info
--============================================================================
IF OBJECT_ID('gold.fact_attribution_last_touch', 'U') IS NOT NULL
    DROP TABLE gold.fact_attribution_last_touch;
GO

CREATE TABLE gold.fact_attribution_last_touch (
    attribution_key        INT IDENTITY(1,1) PRIMARY KEY,
    user_id                INT          NOT NULL,
    purchase_id            INT          NOT NULL,
    last_touch_channel     NVARCHAR(50) NOT NULL,
    last_touch_campaign    INT          NULL,
    revenue                DECIMAL(10,2) NOT NULL,
    purchase_date          DATE         NOT NULL
);
GO

-- a) rank touchpoints so that rn = 1 = LAST touch before purchase
WITH ranked AS (
    SELECT
        user_id,
        purchase_id,
        channel AS last_touch_channel,
        campaign_id AS last_touch_campaign,
        touchpoint_time,
        ROW_NUMBER() OVER (
            PARTITION BY user_id, purchase_id
            ORDER BY touchpoint_time DESC
        ) AS rn
    FROM gold.fact_touchpath 
    WHERE purchase_id IS NOT NULL       -- Only paths that led to purchase
), last_touch AS (
    SELECT
        user_id,
        purchase_id,
        last_touch_channel,
        last_touch_campaign
    FROM ranked
    WHERE rn = 1
)

INSERT INTO gold.fact_attribution_last_touch (
    user_id,
    purchase_id,
    last_touch_channel,
    last_touch_campaign,
    revenue,
    purchase_date
)
SELECT
    lt.user_id,
    lt.purchase_id,
    lt.last_touch_channel,
    lt.last_touch_campaign,
    p.revenue,
    p.purchase_date
FROM last_touch lt
JOIN gold.fact_purchases p
ON lt.user_id = p.user_id
    AND lt.purchase_id = p.purchase_id
WHERE last_touch_channel IS NOT NULL 
    AND revenue IS NOT NULL
    AND p.purchase_date IS NOT NULL;
GO



