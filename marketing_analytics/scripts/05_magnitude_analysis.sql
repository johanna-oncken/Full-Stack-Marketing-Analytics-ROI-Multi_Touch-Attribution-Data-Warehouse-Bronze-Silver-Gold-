/*
===============================================================================
Magnitude Analysis
===============================================================================
Purpose:
    - To quantify data and group results by specific dimensions.
    - For understanding data distribution across categories.

SQL Functions Used:
    - Aggregate Functions: SUM(), COUNT(), AVG()
    - GROUP BY, ORDER BY, LEFT JOIN

Queries:
    1) Number of Campaigns by Objective
    2) Number of Channels by Category 
    - Ad Spend
    3.1) Total Ad Spend by Campaign 
    3.2) Total Ad Spend by Channel 
    3.3) Average Ad Speng by Campaign 
    3.4) Average Af Soend by Channel 
    3.5) Total Ad Spend by Business Objective 
    3.6) Total Ad Spend by Chanel Category 
    - Clicks
    4.1) Total Clicks by Campaign 
    4.2) Total Clicks by Business Object 
    4.3) Total Clicks by Channel 
    4.4) Total Clicks by Channel Category 
    4.5) Total Clicks by Acquisition Channel 
    - Sessions
    5.1) Number of Sessions by Device Category 
    5.2) Number of Sessions by Pages Viewed
    5.3) Total Sessions by Source Channel 
    5.4) Total Sessions by Source Channel Category 
    5.5) Total Sessions by Acquisition Channel 
    - Touchpoints
    6.1) Number of Users by Touchpoint Count 
    6.2) Total Touchpoints by Interaction Type 
    6.3) Total Touchpoints by Campaign 
    6.4) Total Touchpoints by Business Objective 
    6.5) Total Touchpoints by Channel 
    6.6) Total Touchpoints by Channel Category
    - Purchases
    7.1) Number of Users by Purchase Count 
    7.2) Total Revenue by User 
    7.3) Purchases by Last-Touch Channel 
    7.4) Purchases by Acquisition Channel 
    7.5) Purchases by Acquisition Campaign -
    - Touchpath
    8.1) Number of Purchases grouped by Touchpath Length (Journey Complexity)
    8.2) Distribution of Interaction Types in Converting Journeys 
    8.3) Channel Frequency in Converting Journeys 
    8.4) Campaign Frequency in Converting Journeys 
    8.5) Funnel Stage Composition in Converting Journeys (Upper vs. Lower Funnel)
    - Attribution Linear
    9.1) Attributed Revenue by Channel
    9.2) Average Revenue Share by Channel
    9.3) Attributed Revenue by Campagin
    9.4) Attributed Revenue by Interaction Type 
    9.5) Average Total Revenue by Touchpoints in Path
    9.6) Early vs. Late Funnel Dominating Channels 
    9.7) Attributed Revenue by User 
    9.8) Avergae Attributed Revenue by User 
    9.9) Revenue Share by Touchpoint Number
    9.10) Average Share Distribution on Short Paths
    9.11) Average Share Distribution on Long Paths
    9.12) Frequency of Channel Co-Appearence in Converting Journeys (Cross-Channel Synergy)
    - Attribution Last-Touch
    10.1) Total Revenue by Last-Touch Channel 
    10.2) Total Revenue by Last-Touch Campaign 
    10.3) Distribution of Channel by Last-Touch (Interaction before Conversion)
    10.4) User Count by Last-Touch Channel 
    10.5) Distribution of Campaign by Last-Touch 
    10.6) Campaigns with highest Conversion Impact relative to Appearence
    10.7) Number of Purchases by Last-Touch Channel  
    10.8) Number of Purchases by Last-Touch Campaign
    10.9) Total Revenue by Last-Touch Interaction Type 
    10.10) Channel Frequency by Last-Touch 
    10.11) Campaign Frequency by Last-Touch 
    10.12) Average Revenue per Purchase by Last-Touch Channel
    10.13) Average Touchpoint Count before Purchase
    10.14) Pearson's r Formula: Testing Correlation between Touchpoint Number and Revenue 
    10.15) Inspecting if Shorter or Longer Journeys are associated with Higher-Value Purchases
    10.16) Inspecting if specific Last-Touch Channels are associated with Higher-Value Purchases
    10.17) Channel Frequency by New vs. Returning Customers 
    10.18) Interaction Type Frequency by Higher-Value Purchases
    10.19) Channel-Campaign Combinations by Revenue 


===============================================================================
*/
USE marketing_dw;
GO
/*
===============================================================================
1) Campaigns
===============================================================================
*/ 
-- 1) Find number of campaigns by business objective
SELECT
    objective,
    COUNT(*) AS total_campaigns
FROM gold.dim_campaign
GROUP BY objective
ORDER BY COUNT(campaign_id) DESC;
/*
===============================================================================
2) Channels
===============================================================================
*/
-- 2) Find number of channels by category 
SELECT 
    category,
    COUNT(*) AS total_channels
FROM gold.dim_channel
GROUP BY category
ORDER BY COUNT(channel_key) DESC;

/*
===============================================================================
3) Ad Spend
===============================================================================
*/

-- 3.1) Find total ad spend by campaign
SELECT 
    campaign_id,
    campaign_name,
    SUM(spend) AS total_spend
FROM gold.fact_spend
GROUP BY campaign_id, campaign_name
ORDER BY SUM(spend) DESC;

-- 3.2) Find total ad spend by channel
SELECT 
    channel,
    SUM(spend) AS total_spend
FROM gold.fact_spend
GROUP BY channel
ORDER BY SUM(spend) DESC;

-- 3.3) Find average ad spend by campaign
SELECT 
    campaign_id,
    campaign_name,
    AVG(spend) AS average_spend
FROM gold.fact_spend
GROUP BY campaign_id, campaign_name
ORDER BY AVG(spend) DESC;

-- 3.4) Find average ad spend by channel
SELECT 
    channel,
    AVG(spend) AS average_spend
FROM gold.fact_spend
GROUP BY channel
ORDER BY AVG(spend) DESC;

-- 3.5) Find total ad spend by business objective
SELECT
    d.objective,
    SUM(f.spend) AS total_spend
FROM gold.fact_spend f
LEFT JOIN gold.dim_campaign d
ON f.campaign_id = d.campaign_id
GROUP BY d.objective
ORDER BY SUM(f.spend) DESC;

-- 3.6) Find total ad spend by channel category
SELECT
    d.category,
    SUM(f.spend) AS total_spend
FROM gold.fact_spend f
LEFT JOIN gold.dim_channel d
ON f.channel = d.channel_name
GROUP BY d.category
ORDER BY SUM(f.spend) DESC;

/*
===============================================================================
4) Clicks
===============================================================================
*/
-- 4.1) Find total clicks by marketing campaign
SELECT 
    f.campaign_id,
    d.campaign_name,
    COUNT(f.click_id) AS total_clicks
FROM gold.fact_clicks f
LEFT JOIN gold.dim_campaign d 
ON f.campaign_id = d.campaign_id
GROUP BY f.campaign_id, d.campaign_name
ORDER BY COUNT(f.click_id) DESC;

-- 4.2) Find total clicks by business objective
SELECT 
    d.objective,
    COUNT(f.click_id) AS total_clicks
FROM gold.fact_clicks f
LEFT JOIN gold.dim_campaign d 
ON f.campaign_id = d.campaign_id
GROUP BY d.objective
ORDER BY COUNT(f.click_id) DESC;

-- 4.3) Find total clicks by click channel
SELECT 
    click_channel,
    COUNT(click_id) AS total_clicks
FROM gold.fact_clicks f
GROUP BY click_channel
ORDER BY COUNT(click_id) DESC;

-- 4.4) Find total clicks by click channel category
SELECT 
    d.category AS click_channel_category,
    COUNT(f.click_id) AS total_clicks
FROM gold.fact_clicks f
LEFT JOIN gold.dim_channel d 
ON f.click_channel = d.channel_name
GROUP BY d.category
ORDER BY COUNT(f.click_id) DESC;

-- 4.5) Find total clicks by acquisition channel
SELECT 
    acquisition_channel,
    COUNT(click_id) AS total_clicks
FROM gold.fact_clicks f
GROUP BY acquisition_channel
ORDER BY COUNT(click_id) DESC;

/*
===============================================================================
5) Sessions
===============================================================================
*/
-- 5.1) Find number of sessions by device category
SELECT 
    device_category,
    COUNT(session_id) AS total_sessions
FROM gold.fact_sessions
GROUP BY device_category
ORDER BY COUNT(session_id) DESC;

-- 5.2) Find number of sessions by pages viewed 
SELECT 
    pages_viewed,
    COUNT(session_id) AS total_sessions
FROM gold.fact_sessions
GROUP BY pages_viewed
ORDER BY COUNT(session_id) DESC;

-- 5.3) Find total sessions by source channel 
SELECT 
    source_channel,
    COUNT(session_id) AS total_sessions
FROM gold.fact_sessions
GROUP BY source_channel
ORDER BY COUNT(session_id) DESC;

-- 5.4) Find total sessions by source channel category
SELECT 
    d.category AS source_channel_category,
    COUNT(f.session_id) AS total_sessions
FROM gold.fact_sessions f
LEFT JOIN gold.dim_channel d 
ON f.source_channel = d.channel_name
GROUP BY d.category
ORDER BY COUNT(f.session_id) DESC;

-- 5.5) Find total sessions by acquisition channel
SELECT 
    acquisition_channel,
    COUNT(session_id) AS total_sessions
FROM gold.fact_sessions
GROUP BY acquisition_channel
ORDER BY COUNT(session_id) DESC;

/*
===============================================================================
6) Touchpoints
===============================================================================
*/
-- 6.1) Find number of users by touchpoint count
SELECT 
    total_touchpoints AS touchpoint_count,
    COUNT(user_id) AS total_users
FROM(
    SELECT 
        d.user_id,
        COUNT(f.touchpoint_key) AS total_touchpoints
    FROM gold.dim_user d 
    LEFT JOIN gold.fact_touchpoints f 
    ON d.user_id = f.user_id
    GROUP BY d.user_id) t 
GROUP BY total_touchpoints 
ORDER BY COUNT(user_id) DESC;

-- 6.2) Find total touchpoints by interaction type
SELECT 
    interaction_type,
    COUNT(touchpoint_key) AS total_touchpoints 
FROM gold.fact_touchpoints 
GROUP BY interaction_type 
ORDER BY COUNT(touchpoint_key) DESC;

-- 6.3) Find total touchpoints by marketing campaign
SELECT 
    campaign_id,
    campaign_name,
    COUNT(touchpoint_key) AS total_touchpoints 
FROM gold.fact_touchpoints 
GROUP BY campaign_id, campaign_name 
ORDER BY COUNT(touchpoint_key) DESC;

-- 6.4) Find total touchpoints by business objective
SELECT 
    d.objective AS business_objective,
    COUNT(f.touchpoint_key) AS total_touchpoints 
FROM gold.fact_touchpoints f
LEFT JOIN gold.dim_campaign d
ON f.campaign_id = d.campaign_id
GROUP BY d.objective
ORDER BY COUNT(f.touchpoint_key) DESC;

-- 6.5) Find total touchpoints by channel
SELECT 
    channel,
    COUNT(touchpoint_key) AS total_touchpoints 
FROM gold.fact_touchpoints 
GROUP BY channel 
ORDER BY COUNT(touchpoint_key) DESC;

-- 6.6) Find total touchpoints by channel category
SELECT 
    d.category AS channel_category,
    COUNT(f.touchpoint_key) AS total_touchpoints 
FROM gold.fact_touchpoints f
LEFT JOIN gold.dim_channel d
ON f.channel = d.channel_name
GROUP BY d.category
ORDER BY COUNT(f.touchpoint_key) DESC;

/*
===============================================================================
7) Purchases
===============================================================================
*/

-- 7.1) Find number of users by purchase count
SELECT 
    total_purchases AS purchase_count,
    COUNT(user_id) AS total_users
FROM(
    SELECT 
        d.user_id,
        COUNT(f.purchase_id) AS total_purchases
    FROM gold.dim_user d 
    LEFT JOIN gold.fact_purchases f 
    ON d.user_id = f.user_id
    GROUP BY d.user_id) t 
GROUP BY total_purchases
ORDER BY COUNT(user_id) DESC;

-- 7.2) Find total revenue by user
SELECT 
    d.user_id,
    SUM(f.revenue) AS total_revenue
FROM gold.dim_user d 
LEFT JOIN gold.fact_purchases f 
ON d.user_id = f.user_id
GROUP BY d.user_id
ORDER BY SUM(f.revenue) DESC;
    
-- 7.3) Find purchases by last touch channel 
SELECT 
    channel_last_touch,
    COUNT(purchase_id) AS total_purchases
FROM gold.fact_purchases
GROUP BY channel_last_touch 
ORDER BY COUNT(purchase_id) DESC;

-- 7.4) Find purchases by acquisition channel 
SELECT 
    acquisition_channel,
    COUNT(purchase_id) AS total_purchases
FROM gold.fact_purchases
GROUP BY acquisition_channel
ORDER BY COUNT(purchase_id) DESC;

-- 7.5) First-touch campaign performance
--      Find purchase by acquisition campaign
SELECT 
    f.acquisition_campaign,
    d.campaign_name,
    COUNT(f.purchase_id) AS total_purchases
FROM gold.fact_purchases f
LEFT JOIN gold.dim_campaign d
ON f.acquisition_campaign = d.campaign_id
GROUP BY f.acquisition_campaign, d.campaign_name
ORDER BY COUNT(f.purchase_id) DESC;

/*
===============================================================================
8) Touchpath
===============================================================================
*/
-- 💡 touchpath = converting journey

-- 8.1) Number of purchases grouped by touchpath length 
--    Journey Complexity - Purchases
SELECT
    touchpath_length,
    COUNT(purchase_id) AS purchase_count
FROM (
    SELECT 
        purchase_id,
        COUNT(*) AS touchpath_length
    FROM gold.fact_touchpath
    GROUP BY purchase_id
) t
GROUP BY touchpath_length
ORDER BY touchpath_length;

-- 8.2) Distribution of interaction types in converting jouneys
SELECT 
    interaction_type,
    COUNT(*) AS total_touchpoints
FROM gold.fact_touchpath
GROUP BY interaction_type
ORDER BY COUNT(*) DESC;

-- 8.3) Channel frequency in converting journeys
SELECT 
    channel,
    COUNT(*) AS total_touchpoints
FROM gold.fact_touchpath
GROUP BY channel
ORDER BY COUNT(*) DESC;

-- 8.4) Campaign frequency in converting journeys
SELECT 
    campaign_id,
    COUNT(*) AS total_touchpoints
FROM gold.fact_touchpath
GROUP BY campaign_id
ORDER BY COUNT(*) DESC;

-- 8.5) Funnel Stage Composition in converting journeys
--      (Upper vs. Lower Funnel)
WITH classified AS (
    SELECT
        interaction_type,
        CASE 
            WHEN interaction_type IN ('Impression', 'View') THEN 'Upper Funnel'
            WHEN interaction_type = 'Click' THEN 'Lower Funnel'
            ELSE 'Unknown'
        END AS funnel_stage
    FROM gold.fact_touchpath
)
SELECT 
    funnel_stage,
    COUNT(*) AS total_touchpoints
FROM classified
GROUP BY funnel_stage
ORDER BY total_touchpoints DESC;

/*
===============================================================================
9) Attribution Linear
===============================================================================
*/
-- 9.1) Find attributed revenue by channel
SELECT 
    channel,
    SUM(revenue_share) AS attributed_revenue
FROM gold.fact_attribution_linear
GROUP BY channel 
ORDER BY SUM(revenue_share) DESC;

-- 9.2) Find average revenue share size by channel 
SELECT 
    channel, 
    AVG(revenue_share) AS avg_revenue_share
FROM gold.fact_attribution_linear
GROUP BY channel 
ORDER BY AVG(revenue_share) DESC;

-- 9.3) Find attributed revenue by campaign_id 
SELECT 
    f.campaign_id,
    d.campaign_name,
    SUM(f.revenue_share) AS attributed_revenue
FROM gold.fact_attribution_linear f
LEFT JOIN gold.dim_campaign d 
ON f.campaign_id = d.campaign_id
GROUP BY f.campaign_id, d.campaign_name 
ORDER BY SUM(f.revenue_share) DESC;

-- 9.4) Find attributed revenue by interaction_type
SELECT 
    interaction_type,
    SUM(revenue_share) AS attributed_revenue
FROM gold.fact_attribution_linear 
GROUP BY interaction_type 
ORDER BY SUM(revenue_share) DESC;

-- 9.5) Find average total revenue by touchpoints in path
--      revenue per purchase steps (early vs late touchpoints)
SELECT 
    touchpoints_in_path,
    AVG(total_revenue) AS avg_total_revenue 
FROM (
    SELECT distinct 
        purchase_id,
        touchpoints_in_path,
        total_revenue
    FROM gold.fact_attribution_linear
) t
GROUP BY touchpoints_in_path 
ORDER BY AVG(total_revenue) DESC;

-- 9.6) Identify channels dominating early vs. late funnel
SELECT 
    channel,
    SUM(CASE 
        WHEN interaction_type IN ('Impression', 'View') THEN 1 ELSE 0 END) AS upper_funnel_count, 
    SUM(CASE 
        WHEN interaction_type = 'Click' THEN 1 ELSE 0 END) AS lower_funnel_count   
FROM gold.fact_attribution_linear 
GROUP BY channel
ORDER BY lower_funnel_count DESC;

-- 9.7) Find attributed revenue by user
SELECT 
    user_id, 
    SUM(revenue_share) AS attributed_revenue 
FROM gold.fact_attribution_linear 
GROUP BY user_id 
ORDER BY SUM(revenue_share) DESC; 

-- 9.8) Avg attributed revenue per user by channel 
SELECT 
    channel,
    AVG(user_revenue) AS avg_revenue_per_user
FROM (
    SELECT 
        channel,
        user_id,
        SUM(revenue_share) AS user_revenue
    FROM gold.fact_attribution_linear
    GROUP BY channel, user_id
) t
GROUP BY channel
ORDER BY AVG(user_revenue) DESC;


-- 9.9) Revenue share by touchpoint_number 
SELECT 
    touchpoint_number,
    AVG(revenue_share) AS avg_share
FROM gold.fact_attribution_linear 
GROUP BY touchpoint_number 
ORDER BY AVG(revenue_share) DESC;

-- 9.10) Find average share distribution across long vs short paths
--       Short paths 
SELECT 
    touchpoints_in_path,
    AVG(revenue_share) AS avg_total_revenue 
FROM gold.fact_attribution_linear
WHERE touchpoints_in_path <= (SELECT AVG(touchpoints_in_path) FROM gold.fact_attribution_linear)
GROUP BY touchpoints_in_path 
ORDER BY AVG(total_revenue) DESC;

-- 9.11) Long paths 
SELECT 
    touchpoints_in_path,
    AVG(revenue_share) AS avg_total_revenue 
FROM gold.fact_attribution_linear
WHERE touchpoints_in_path > (SELECT AVG(touchpoints_in_path) FROM gold.fact_attribution_linear)
GROUP BY touchpoints_in_path 
ORDER BY AVG(total_revenue) DESC;


-- 9.12) Find how often channels co-appear in converting journeys 
--       Cross-Channel Synergy 
SELECT 
    channel, 
    AVG(channel_count) AS avg_count_per_journey 
FROM (
    SELECT 
        channel,
        purchase_id,
        CAST(COUNT(*) AS DECIMAL(10,2)) AS channel_count
    FROM gold.fact_attribution_linear 
    GROUP BY channel, purchase_id) t 
GROUP BY channel 
ORDER BY AVG(channel_count) DESC; 


/*
===============================================================================
10) Attribution Last Touch
===============================================================================
*/
-- 10.1) Find total revenue by last touch channel 
SELECT 
    last_touch_channel, 
    SUM(revenue) AS revenue_attrib_to_last_touch
FROM gold.fact_attribution_last_touch 
GROUP BY last_touch_channel 
ORDER BY SUM(revenue) DESC;

-- 10.2) Find total revenue by last touch campaign
--       Are there "power campaigns" whose last-touch role dominates revenues?
SELECT 
    last_touch_campaign, 
    SUM(revenue) AS revenue_attrib_to_last_touch
FROM gold.fact_attribution_last_touch 
GROUP BY last_touch_campaign
ORDER BY SUM(revenue) DESC;

-- 10.3) Are certain channels more likely to be the final interaction before conversion?
--       Find distribution of channel by last touch 
SELECT 
    last_touch_channel,
    COUNT(*) AS channel_count 
FROM gold.fact_attribution_last_touch
GROUP BY last_touch_channel 
ORDER BY COUNT(*) DESC;

-- 10.4) Find user count by last touch channel 
SELECT 
    last_touch_channel, 
    COUNT(user_id) AS user_count
FROM gold.fact_attribution_last_touch 
GROUP BY last_touch_channel 
ORDER BY COUNT(user_id) DESC;

-- 10.5) Find distribution of campaign by last touch 
SELECT 
    f.last_touch_campaign,
    d.campaign_name,
    COUNT(*) AS campaign_count 
FROM gold.fact_attribution_last_touch f
LEFT JOIN gold.dim_campaign d
ON f.last_touch_campaign = d.campaign_id
GROUP BY f.last_touch_campaign, d.campaign_name
ORDER BY COUNT(*) DESC;

-- 10.6) Which campaigns have the highest conversion impact relative to how often they appear?
WITH last AS (
    SELECT 
        f.last_touch_campaign,
        d.campaign_name,
        COUNT(*) AS last_count
    FROM gold.fact_attribution_last_touch f
    LEFT JOIN gold.dim_campaign d
    ON f.last_touch_campaign = d.campaign_id
    GROUP BY f.last_touch_campaign, d.campaign_name
), 
all_tp AS (
    SELECT 
        campaign_id,
        COUNT(*) AS all_count 
    FROM gold.fact_touchpoints
    GROUP BY campaign_id      
)

SELECT 
    l.last_touch_campaign,
    l.campaign_name,
    l.last_count, 
    a.all_count 
FROM last l 
LEFT JOIN all_tp a 
ON l.last_touch_campaign = a.campaign_id
ORDER BY last_count DESC;

-- 10.7) Find number of purchases by last touch channel
SELECT 
    last_touch_channel, 
    COUNT(purchase_id) AS purchases
FROM gold.fact_attribution_last_touch 
GROUP BY last_touch_channel 
ORDER BY COUNT(purchase_id) DESC;

-- 10.8) Find number of purchases by last touch campaign
SELECT 
    last_touch_campaign, 
    COUNT(purchase_id) AS purchases
FROM gold.fact_attribution_last_touch 
GROUP BY last_touch_campaign 
ORDER BY COUNT(purchase_id) DESC; 

-- 10.9) Find total revenue by last-touch interaction type 
SELECT 
    interaction_type, 
    SUM(revenue) AS revenue_attrib_to_last_touch
FROM gold.fact_attribution_last_touch 
GROUP BY interaction_type 
ORDER BY SUM(revenue) DESC;

-- 10.10) Which channels drive the most last-touch conversion 
SELECT 
    last_touch_channel, 
    COUNT(purchase_id) AS purchases,
    SUM(revenue) AS revenue_attrib_to_last_touch
FROM gold.fact_attribution_last_touch 
GROUP BY last_touch_channel 
ORDER BY SUM(revenue) DESC;

-- 10.11) Which campaigns dirve the most last-touch conversion
SELECT 
    f.last_touch_campaign,
    d.campaign_name, 
    COUNT(f.purchase_id) AS purchases,
    SUM(f.revenue) AS revenue_attrib_to_last_touch
FROM gold.fact_attribution_last_touch f
LEFT JOIN gold.dim_campaign d
ON f.last_touch_campaign = d.campaign_id
GROUP BY f.last_touch_campaign, d.campaign_name
ORDER BY SUM(f.revenue) DESC;

-- 10.12) What is the average revenue per purchase by last-touch channel
SELECT 
    last_touch_channel, 
    AVG(revenue) AS avg_revenue_attrib_to_last_touch
FROM gold.fact_attribution_last_touch 
GROUP BY last_touch_channel 
ORDER BY AVG(revenue) DESC;

-- 10.13) How many touchpoints typically occur before a purchase?
SELECT 
    AVG(touchpoint_number) AS avg_touchpoints_before_purchase 
FROM gold.fact_attribution_last_touch; 

-- 10.14) Does the touchpoint number (position in the journey) correlate with revenue?
SELECT 
    (SUM(aabb))/(SQRT(SUM(a_2))*SQRT(SUM(b_2))) as r_correlation
FROM (
SELECT 
    touchpoint_number,
    revenue,
    (touchpoint_number - avg_tp)*(revenue - avg_revenue) AS aabb,
    POWER(touchpoint_number - avg_tp, 2) AS a_2,
    POWER(revenue - avg_revenue, 2) AS b_2 
FROM (
    SELECT
        touchpoint_number,
        revenue, 
        AVG(touchpoint_number) OVER()AS avg_tp,
        AVG(revenue) OVER() AS avg_revenue 
    FROM gold.fact_attribution_last_touch
) t ) b;

-- 10.15) Are shorter or longer journeys associated with higher-value purchases?
SELECT 
    AVG(revenue) AS avg_revenue_short_path 
FROM gold.fact_attribution_last_touch 
WHERE touchpoint_number <= (SELECT AVG(touchpoints_in_path) FROM gold.fact_attribution_linear);

SELECT 
    AVG(revenue) AS avg_revenue_long_path 
FROM gold.fact_attribution_last_touch 
WHERE touchpoint_number > (SELECT AVG(touchpoints_in_path) FROM gold.fact_attribution_linear);

-- 10.16) Do high-value users tend to come form specific last-touch channels? 
    SELECT 
        last_touch_channel,
        COUNT(*) AS channel_distribution_high_value
    FROM(
SELECT
    purchase_id, 
    last_touch_channel,
    revenue
FROM gold.fact_attribution_last_touch 
WHERE revenue > (SELECT AVG(revenue) FROM gold.fact_attribution_last_touch)
) t 
    GROUP BY last_touch_channel 
    ORDER BY COUNT(*) DESC;

-- 10.17) Are some channels more common for new customers vs returning customers? 
WITH returning AS (
SELECT 
    user_id
FROM gold.fact_attribution_last_touch 
GROUP BY user_id 
HAVING COUNT(purchase_id) >= 2 
) 

SELECT 
     f.last_touch_channel,
     COUNT(r.user_id) AS channel_count_returning
FROM returning r
LEFT JOIN gold.fact_attribution_last_touch f
ON r.user_id = f.user_id 
GROUP BY f.last_touch_channel
ORDER BY COUNT(r.user_id) DESC;

;WITH new_cust AS (
SELECT 
    user_id
FROM gold.fact_attribution_last_touch 
GROUP BY user_id 
HAVING COUNT(purchase_id) = 1 
)

SELECT 
     f.last_touch_channel,
     COUNT(n.user_id) AS channel_count_new_customer
FROM new_cust n
LEFT JOIN gold.fact_attribution_last_touch f
ON n.user_id = f.user_id 
GROUP BY f.last_touch_channel
ORDER BY COUNT(n.user_id) DESC;


-- 10.18) Do certain interaction types correlate with higher purchase amounts? 
    SELECT 
        interaction_type,
        COUNT(*) AS channel_distribution_high_value
    FROM(
SELECT
    purchase_id, 
    interaction_type,
    revenue
FROM gold.fact_attribution_last_touch 
WHERE revenue > (SELECT AVG(revenue) FROM gold.fact_attribution_last_touch)
) t 
    GROUP BY interaction_type
    ORDER BY COUNT(*) DESC;

-- 10.19) Which channel-campaign combinations generate the highest share of revenue? 
SELECT 
    CONCAT(f.last_touch_channel, ' - ', f.last_touch_campaign, ' ', d.campaign_name) AS channel_campaign_combination, 
    SUM(f.revenue) AS total_revenue
FROM gold.fact_attribution_last_touch f
LEFT JOIN gold.dim_campaign d
ON f.last_touch_campaign = d.campaign_id
GROUP BY CONCAT(f.last_touch_channel, ' - ', f.last_touch_campaign, ' ', d.campaign_name)
ORDER BY SUM(f.revenue) DESC;



















