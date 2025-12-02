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
-- Create Fact: gold.fact_attribution_linear (Complete Multi-Touch Attribution)
--============================================================================
IF OBJECT_ID('gold.fact_attribution_linear', 'U') IS NOT NULL
    DROP TABLE gold.fact_attribution_linear;
GO

CREATE TABLE gold.fact_attribution_linear (
    attribution_key        INT IDENTITY(1,1) PRIMARY KEY,
    user_id                INT           NOT NULL,
    purchase_id            INT           NOT NULL,
    touchpoint_number      INT           NOT NULL,
    channel                NVARCHAR(50)  NOT NULL,
    campaign_id            INT           NULL,
    interaction_type       NVARCHAR(50)  NOT NULL,
    touchpoint_time        DATETIME2     NOT NULL,
    revenue_share          DECIMAL(12,2) NOT NULL,
    total_revenue          DECIMAL(12,2) NOT NULL,
    touchpoints_in_path    INT           NOT NULL,
    purchase_date          DATE          NOT NULL
);
GO

-- a) Use only touchpoints tied to actual conversions
WITH tp AS (
    SELECT
        user_id,
        purchase_id,
        touchpoint_number,
        channel,
        campaign_id,
        interaction_type,
        touchpoint_time
    FROM gold.fact_touchpath
    WHERE purchase_id IS NOT NULL
),
-- b) Count touchpoints per purchase_id
tp_counts AS (
    SELECT
        purchase_id,
        COUNT(*) AS touchpoints_in_path
    FROM tp
    GROUP BY purchase_id
),
-- c) Join with revenue + purchase date
joined AS (
    SELECT
        t.user_id,
        t.purchase_id,
        t.touchpoint_number,
        t.channel,
        t.campaign_id,
        t.interaction_type,
        t.touchpoint_time,
        c.touchpoints_in_path,
        p.revenue AS total_revenue,
        p.purchase_date
    FROM tp t
    JOIN tp_counts c    
        ON t.purchase_id = c.purchase_id
    JOIN gold.fact_purchases p
         ON t.purchase_id = p.purchase_id
),

-- d) Calculate linear (equal weight) attribution
attribution AS (
    SELECT
        user_id,
        purchase_id,
        touchpoint_number,
        channel,
        campaign_id,
        interaction_type,
        touchpoint_time,
        total_revenue / touchpoints_in_path AS revenue_share,
        total_revenue,
        touchpoints_in_path,
        purchase_date
    FROM joined
)

-- e) Load into fact table
INSERT INTO gold.fact_attribution_linear (
    user_id, purchase_id, touchpoint_number, channel, campaign_id,
    interaction_type, touchpoint_time, revenue_share, total_revenue,
    touchpoints_in_path, purchase_date
)
SELECT
    user_id,
    purchase_id,
    touchpoint_number,
    channel,
    campaign_id,
    interaction_type,
    touchpoint_time,
    revenue_share,
    total_revenue,
    touchpoints_in_path,
    purchase_date
FROM attribution
WHERE revenue_share >= 0
    AND total_revenue IS NOT NULL;
GO

--============================================================================
-- Create Fact: gold.fact_attribution_last_touch - last touch info
--============================================================================
IF OBJECT_ID('gold.fact_attribution_last_touch', 'U') IS NOT NULL
    DROP TABLE gold.fact_attribution_last_touch;
GO

CREATE TABLE gold.fact_attribution_last_touch (
    attribution_key       INT IDENTITY(1,1) PRIMARY KEY,
    user_id               INT           NOT NULL,
    purchase_id           INT           NOT NULL,
    touchpoint_number     INT           NOT NULL,  
    touchpoint_time       DATETIME2     NOT NULL,
    last_touch_channel    NVARCHAR(50)  NOT NULL,
    last_touch_campaign   INT           NULL,
    interaction_type      NVARCHAR(50)  NOT NULL,
    revenue               DECIMAL(10,2) NOT NULL,
    purchase_date         DATE          NOT NULL
);
GO

-- a) Use last touchpoint per purchase
WITH last_touch AS (
    SELECT
        user_id,
        purchase_id,
        touchpoint_number,
        touchpoint_time,
        channel,
        campaign_id,
        interaction_type,
        ROW_NUMBER() OVER (
            PARTITION BY purchase_id
            ORDER BY touchpoint_time DESC
        ) AS rn
    FROM gold.fact_touchpath
    WHERE purchase_id IS NOT NULL
),
-- b) add purchse revenue + purchase date 
purchases AS (
    SELECT 
        purchase_id,
        user_id,
        revenue,
        purchase_date
    FROM gold.fact_purchases
)

-- insert only rn= 1 (touchpoint_time DESC)
INSERT INTO gold.fact_attribution_last_touch (
    user_id,
    purchase_id,
    touchpoint_number,
    touchpoint_time,
    last_touch_channel,
    last_touch_campaign,
    interaction_type,
    revenue,
    purchase_date
)
SELECT 
    lt.user_id,
    lt.purchase_id,
    lt.touchpoint_number,
    lt.touchpoint_time,
    lt.channel AS last_touch_channel,
    lt.campaign_id AS last_touch_campaign,
    lt.interaction_type,
    p.revenue,
    p.purchase_date
FROM last_touch lt
JOIN purchases p
  ON lt.purchase_id = p.purchase_id
WHERE lt.rn = 1
    AND revenue IS NOT NULL;
GO

