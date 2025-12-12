/*
===============================================================================
Dimensions Exploration
===============================================================================
Purpose:
    - To explore the structure of dimension tables.
	
SQL Functions Used:
    - DISTINCT
    - ORDER BY
===============================================================================
*/
USE marketing_dw;
GO

-- Retrieve a list of unique marketing campaigns, channels and objectives
SELECT DISTINCT 
    campaign_name,
    channel,
    objective
FROM gold.dim_campaign
ORDER BY campaign_name, channel, objective;


-- Retrieve a list of unique channels and categories
SELECT DISTINCT 
    channel_name, 
    category
FROM gold.dim_channel
ORDER BY channel_name, category;


-- Retrieve a list of unique users 
SELECT COUNT(*)
FROM gold.dim_user;

SELECT DISTINCT TOP 30 user_id
FROM gold.dim_user
ORDER BY user_id;
