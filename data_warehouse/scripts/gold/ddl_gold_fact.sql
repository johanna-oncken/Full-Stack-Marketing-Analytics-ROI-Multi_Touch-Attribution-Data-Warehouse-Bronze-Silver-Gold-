/*
===============================================================================
DDL Script: Create Gold Fact Tables
===============================================================================
Script Purpose:
    This script creates enriched fact tables for the Gold layer in the marketing
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
-- FACT TABLES
--============================================================================
--============================================================================
-- Create Fact: gold.fact_spend - Enriched version of silver.mrkt_ad_spend
--============================================================================
IF OBJECT_ID('gold.fact_spend', 'U') IS NOT NULL
    DROP TABLE gold.fact_spend;
GO

CREATE TABLE gold.fact_spend (
    spend_key       INT IDENTITY(1,1) PRIMARY KEY,
    spend_date      DATE              NOT NULL,
    date_key        INT               NOT NULL,
    channel         NVARCHAR(50)      NULL,
    campaign_name   NVARCHAR(100)     NULL,
    campaign_id     INT               NULL,
    objective       NVARCHAR(50)      NULL,
    spend           DECIMAL(10,2)     NOT NULL
);
GO

INSERT INTO gold.fact_spend (   
    spend_date, 
    date_key,   
    channel, 
    campaign_name, 
    campaign_id, 
    objective, 
    spend
)
SELECT 
    s.spend_date,
    d.date_key,
    s.channel, -- (or c.channel)
    c.campaign_name,
    c.campaign_id,
    c.objective,
    s.spend
FROM silver.mrkt_ad_spend s
LEFT JOIN gold.dim_date d 
    ON s.spend_date = d.full_date
LEFT JOIN silver.mrkt_campaigns c 
    ON s.campaign_id = c.campaign_id
WHERE s.spend_date IS NOT NULL
    AND s.spend IS NOT NULL
    AND d.date_key IS NOT NULL;
GO
--============================================================================
-- Create Fact: gold.fact_clicks - Enriched version of silver.mrkt_clicks
--============================================================================
IF OBJECT_ID('gold.fact_clicks', 'U') IS NOT NULL
    DROP TABLE gold.fact_clicks;
GO

CREATE TABLE gold.fact_clicks (
    clicks_key       INT IDENTITY(1,1) PRIMARY KEY,
    click_id         INT               NOT NULL,-- natural key        
    click_timestamp  DATETIME2         NOT NULL,
    date_key         INT,
    user_id          INT               NOT NULL,
    click_channel    NVARCHAR(50)      NOT NULL, 
    campaign_id      INT               NOT NULL,
    acquisition_channel NVARCHAR(50)
);
INSERT INTO gold.fact_clicks (
    click_id, click_timestamp, date_key, user_id, click_channel, campaign_id, 
    acquisition_channel
)
SELECT
    c.click_id,           
    c.click_timestamp,
    d.date_key,       
    c.user_id,       
    c.channel AS click_channel,      
    c.campaign_id,  
    a.acquisition_channel 
FROM silver.mrkt_clicks c 
LEFT JOIN gold.dim_date d 
ON CAST(c.click_timestamp AS DATE) = d.full_date
LEFT JOIN (                                 -- first-touch acquistion channel
    SELECT user_id, acquisition_channel
    FROM (
        SELECT 
            user_id,
            acquisition_channel,
            ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY acquisition_date) AS rn
        FROM silver.crm_user_acquisitions
    )t
    WHERE rn = 1
)a 
ON c.user_id = a.user_id
WHERE c.click_timestamp IS NOT NULL
    AND c.channel IS NOT NULL
    AND c.campaign_id IS NOT NULL
    AND c.user_id IS NOT NULL;
GO
--============================================================================
-- Create Fact: gold.fact_sessions - Enriched version of silver.web_sessions
--============================================================================
IF OBJECT_ID('gold.fact_sessions', 'U') IS NOT NULL
    DROP TABLE gold.fact_sessions;
GO

CREATE TABLE gold.fact_sessions (
    session_key       INT IDENTITY(1,1) PRIMARY KEY,
    session_id        INT               NOT NULL,-- natural key
    user_id           INT               NOT NULL,
    device_category   NVARCHAR(50)      NOT NULL,
    source_channel    NVARCHAR(50)      NOT NULL,
    acquisition_channel NVARCHAR(50),
    date_key          INT,
    session_date      DATE,    --(date_key)
    session_start     DATETIME2         NOT NULL,
    pages_viewed      INT               NOT NULL,

    UNIQUE(session_id)         -- constraint
);
INSERT INTO gold.fact_sessions (
    session_id, user_id, device_category, source_channel, acquisition_channel,
    date_key, session_date, session_start, pages_viewed
)
SELECT 
    s.session_id,
    s.user_id,
    s.device AS device_category,
    s.source_channel,
    a.acquisition_channel,
    d.date_key,
    CAST(s.session_start AS DATE) AS session_date,
    s.session_start,
    s.pages_viewed 
FROM silver.web_sessions s 
LEFT JOIN (                                 -- first-touch acquistion channel
    SELECT user_id, acquisition_channel
    FROM (
        SELECT 
            user_id,
            acquisition_channel,
            ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY acquisition_date) AS rn
        FROM silver.crm_user_acquisitions
    )t
    WHERE rn = 1
)a 
ON s.user_id = a.user_id
LEFT JOIN gold.dim_date d 
ON CAST(s.session_start AS DATE) = d.full_date
WHERE s.session_start IS NOT NULL
    AND s.user_id IS NOT NULL
    AND s.pages_viewed IS NOT NULL
    AND s.source_channel IS NOT NULL
    AND s.device IS NOT NULL;
GO
--============================================================================
-- Create Fact: gold.fact_touchpoints - Enriched version of silver.web_touchpoints
--============================================================================
IF OBJECT_ID('gold.fact_touchpoints', 'U') IS NOT NULL
    DROP TABLE gold.fact_touchpoints;
GO

CREATE TABLE gold.fact_touchpoints (
    touchpoint_key       INT IDENTITY(1,1) PRIMARY KEY,
    user_id              INT               NOT NULL,
    tp_date              DATE,
    touchpoint_time      DATETIME2         NOT NULL,
    date_key             INT,
    channel              NVARCHAR(50)      NOT NULL,
    campaign_id          INT               NULL,
    campaign_name        NVARCHAR(100),
    interaction_type     NVARCHAR(50)      NOT NULL,

    UNIQUE (user_id, touchpoint_time, channel, interaction_type)  -- constraint

);
INSERT INTO gold.fact_touchpoints (
    user_id, tp_date, touchpoint_time, date_key, channel, campaign_id, campaign_name,
    interaction_type
) 
SELECT
    t.user_id,
    CAST(t.touchpoint_time AS DATE) AS tp_date,
    t.touchpoint_time,
    d.date_key,
    t.channel,
    t.campaign_id,
    c.campaign_name,
    t.interaction_type 
FROM silver.web_touchpoints t 
LEFT JOIN gold.dim_date d 
ON CAST(t.touchpoint_time AS DATE) = d.full_date
LEFT JOIN silver.mrkt_campaigns c 
ON t.campaign_id = c.campaign_id
WHERE t.user_id IS NOT NULL 
    AND t.touchpoint_time IS NOT NULL
    AND t.interaction_type IS NOT NULL
    AND t.channel IS NOT NULL
GO
--============================================================================
-- Create Fact: gold.fact_purchases - Enriched version of silver.crm_purchases
--============================================================================
 IF OBJECT_ID('gold.fact_purchases', 'U') IS NOT NULL
    DROP TABLE gold.fact_purchases;
GO

CREATE TABLE gold.fact_purchases (
    purchase_key       INT IDENTITY(1,1) PRIMARY KEY,
    purchase_id        INT               NOT NULL,
    user_id            INT               NOT NULL,
    purchase_date      DATE              NOT NULL,
    date_key           INT,
    revenue            DECIMAL(10,2),
    channel_last_touch NVARCHAR(50),
    acquisition_channel NVARCHAR(50),
    acquisition_date   DATE,
    acquisition_campaign INT,

    UNIQUE(purchase_id)                  -- constraint
);
INSERT INTO gold.fact_purchases (
    purchase_id, user_id, purchase_date, date_key, revenue, channel_last_touch,
    acquisition_channel, acquisition_date, acquisition_campaign
)
SELECT  
    p.purchase_id,
    p.user_id,
    p.purchase_date,
    d.date_key,
    p.revenue,
    p.channel_last_touch,
    a.acquisition_channel,
    a.acquisition_date, 
    a.acquisition_campaign
FROM silver.crm_purchases p
LEFT JOIN gold.dim_date d
ON p.purchase_date = d.full_date 
LEFT JOIN (                                 -- first-touch acquistion channel
    SELECT 
        user_id, acquisition_channel, acquisition_date, acquisition_campaign
    FROM (
        SELECT 
            user_id,
            acquisition_channel,
            acquisition_date,
            acquisition_campaign,
            ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY acquisition_date) AS rn
        FROM silver.crm_user_acquisitions
    )t
    WHERE rn = 1
)a 
ON p.user_id = a.user_id
WHERE p.user_id IS NOT NULL AND p.purchase_date IS NOT NULL;
GO

