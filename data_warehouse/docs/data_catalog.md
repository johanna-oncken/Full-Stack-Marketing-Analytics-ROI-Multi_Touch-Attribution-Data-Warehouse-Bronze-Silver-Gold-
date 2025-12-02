# Data Catalog for Gold Layer

## Overview
The Gold Layer is the business-level data representation, structured to support analytical and reporting use cases. It consists of **dimension tables** and **fact tables** for specific business metrics.

---

### 1. **gold.dim_date**
- **Purpose:** Provides standardized calender dimension that enables time-based analysis, reporting and aggregation.
- **Grain:**   One row per calendar date
- **Columns:**

| Column Name      | Data Type     | Description                                                                                   |
|------------------|---------------|-----------------------------------------------------------------------------------------------|
| date_key         | INT           | Surrogate integer key uniquely identifying each calendar date in the dimension table.                 |
| full_date        | DATE          | The actual calendar date (YYYY-MM-DD) representing the day.                                   |
| year             | INT           | The four-digit calendar year used for year-over-year comparisons.                             |
| quarter          | INT           | The quarter of the year (1–4) used for quarterly business performance analysis.               |
| month            | INT           | The month number of the year (1–12) used for grouping monthly performance.                    |
| month_name       | VARCHAR(50)   | The name of the month (e.g., 'January') used for user-friendly reporting.                     |
| week             | INT           | The ISO week number(1-53) used for weekly analytics and reporting cycles.                     |
| day              | INT           | The day of the month (1-31) used for daily reporting.                                         |
| day_name         | VARCHAR(50)   | The name of the weekday (e.g., 'Monday') for readable time-based insights.                    |
| is_weekend       | BIT           | A flag indicating whether the date falls on a weekend, supporting behavior analysis.          |

---

### 2. **gold.dim_user**
- **Purpose:** Stores unique user identities so behaviors, conversions, and marketing interactions can be analyzed at customer level.
- **Grain:**   One row per unique user in the system
- **Columns:**

| Column Name         | Data Type     | Description                                                                                   |
|---------------------|---------------|-----------------------------------------------------------------------------------------------|
| user_key            | INT           | Surrogate primary key that uniquely identifies each user in the dimensional model.            |
| user_id             | INT           | The natural user identifier from source systems, used to join facts to the user dimension.    |

---

### 3. **gold.dim_campaign**
- **Purpose:** Defines marketing channels and their broader categories to support channel attribution and cross-channel analytics.
- **Grain:**   One row per unique marketing campaign
- **Columns:**

| Column Name         | Data Type     | Description                                                                                   |
|---------------------|---------------|-----------------------------------------------------------------------------------------------|
| campaign_key        | INT           | Surrogate primary key that uniquely identifies each marketing campaign.                       |
| campaign_id         | INT           | The natural campaign identifier from the source system, used for joining fact tables.         |
| campaign_name       | NVARCHAR(100) | The descriptive name of the marketing campaign used for reporting and analytics.              |
| channel             | NVARCHAR(50)  | The marketing channel through which the campaign is delivered (e.g. Google Search)            |
| start_date          | DATE          | The date on which the campaign is scheduled or recorded to start running.                     |
| end_date            | DATE          | The date on which the campaign stops running or is considered inactive.                       |
| objective           | NVARCHAR(50)  | The business goal of the campaign (e.g., Awareness, Traffic, Conversion)                      |
 
---

### 4. **gold.dim_channel**
- **Purpose:** Captures all marketing campaigns and their attributes to allow performance reporting and conncection to spend/click/touchpoint data.
- **Grain:**   One row per distinct marketing channel (e.g. Google Search, Facebook Ads, Email)
- **Columns:**

| Column Name         | Data Type     | Description                                                                                   |
|---------------------|---------------|-----------------------------------------------------------------------------------------------|
| channel_key         | INT           | Surrogate primary key that uniquely identifies each marketing channel.                        |
| channel_name        | NVARCHAR(50)  | The readable name of the channel (e.g., "Facebook Ads", "Email") used for reporting.          |
| category            | NVARCHAR(50)  | Groups marketing channels into broader logical categories (e.g., Paid Search).                |
 
---

### 5. **gold.fact_spend**
- **Purpose:** Tracks daily marketing spend per campaign and channel to support ROI, budget, and attribution analysis.
- **Grain:**   One row per daily spend record 
- **Columns:**

| Column Name         | Data Type     | Description                                                                                   |
|---------------------|---------------|-----------------------------------------------------------------------------------------------|
| spend_key           | INT           | Surrogate key uniquely identifying each spend record.                                         |
| spend_date          | DATE          | Date on which the spend occurred.                                                             |
| date_key            | INT           | Foreign key linking the spend to the calendar dimension.                                      | 
| channel             | NVARCHAR(50)  | Marketing channel where the spend was allocated.                                              |
| campaign_name       | NVARCHAR(100) | Name of the campaign associated with the spend.                                               |
| campaign_id         | INT           | Natural campaign identifier used for joining with dim_campaign.                               |
| objective           | NVARCHAR(50)  | Marketing objective the spend is intended to support (e.g., Awareness, Conversion).           |
| spend               | DECIMAL(10,2) | Amount of money spent on the given date and campaign.                                         |
 
---

### 6. **gold.fact_clicks**
- **Purpose:** Stores all ad click events to measure engagement, acquisition efficiency, and campaign performance.
- **Grain:**   One row per click event
- **Columns:**

| Column Name         | Data Type     | Description                                                                                   |
|---------------------|---------------|-----------------------------------------------------------------------------------------------|
| clicks_key          | INT           | Surrogate key uniquely identifying each click record.                                         |
| click_id            | INT           | Natural key representing the raw click event.                                                 |
| click_timestamp     | DATETIME2     | Timestamp when the click occurred                                                             |
| date_key            | INT           | Foreign key to the calendar dimension for the click date.                                     |
| user_id             | INT           | User who clicked the ad.                                                                      |
| click_channel       | NVARCHAR(50)  | Channel where the click originated.                                                           |
| campaign_id         | INT           | Campaign associated with the click.                                                           |
| acquisition_channel | NVARCHAR(50)  | User’s first-touch channel, used for attribution and journey analysis.                        |
 
---

### 7. **gold.fact_sessions**
- **Purpose:** Captures all website session activity to analyze user behavior, engagement, and channel performance.
- **Grain:**   One row per web session
- **Columns:**

| Column Name         | Data Type     | Description                                                                                   |
|---------------------|---------------|-----------------------------------------------------------------------------------------------|
| session_key         | INT           | Surrogate key uniquely identifying each session.                                              |
| session_id          | INT           | Natural key representing the session event.                                               |
| user_id             | INT           | User associated with the session.                                                             |
| device_category     | NVARCHAR(50)  | Device type used in the session (Mobile, Desktop, Tablet).                                    |
| source_channel      | NVARCHAR(50)  | Channel that initiated the session.                                                           |
| acquisition_channel | NVARCHAR(50)  | First-touch channel for the user.                                                             |
| date_key            | INT           | Foreign key linking the session to the calendar dimension.                                    |
| session_date        | DATE          | Date of the session.                                                                          |
| session_start       | DATETIME2     | Exact timestamp when the session started.                                                     |
| pages_viewed        | INT           | Count of pages viewed in the session.                                                         |
 
---

### 8. **gold.fact_touchpoints**
- **Purpose:** Captures all user marketing touchpoints to support multi-touch attribution and journey reconstruction.
- **Grain:**   One row per touchpoint (between a user and a marketing channel)
- **Columns:**

| Column Name         | Data Type     | Description                                                                                   |
|---------------------|---------------|-----------------------------------------------------------------------------------------------|
| touchpoint_key      | INT           | Surrogate key uniquely identifying each touchpoint.                                           |
| user_id             | INT           | User who generated the touchpoint.                                                            |
| tp_date             | DATE          | Date of the touchpoint.                                                                       |
| touchpoint_time     | DATETIME2     | Exact timestamp of the touchpoint event.                                                      |
| date_key            | INT           | Foreign key to the calendar dimension.                                                        |
| channel             | NVARCHAR(50)  | Channel through which the touchpoint occurred.                                                |
| campaign_id         | INT           | Campaign associated with the touchpoint.                                                      |
| campaign_name       | NVARCHAR(50)  | Name of the campaign associated with the touchpoint.                                          |
| interaction_type    | NVARCHAR(50)  | Type of interaction (View, Impression, Click).                                                |

---

### 9. **gold.fact_purchases**
- **Purpose:** Tracks all customer purchases to measure revenue, conversion behavior, and campaign effectiveness.
- **Grain:**   One row per purchase
- **Columns:**

| Column Name         | Data Type     | Description                                                                                   |
|---------------------|---------------|-----------------------------------------------------------------------------------------------|
| purchase_key        | INT           | Surrogate key uniquely identifying each purchase record.                                      |
| purchase_id         | INT           | Natural purchase identifier representing the purchase event  .                                 |
| user_id             | INT           | User who made the purchase.                                                                   |
| purchase_date       | DATE          | Date on which the purchase occurred.                                                          |
| date_key            | INT           | Foreign key linking to the calendar dimension.                                                |
| revenue             | DECIMAL(10,2) | Revenue amount generated by the purchase.                                                     |
| channel_last_touch  | NVARCHAR(50)  | Last marketing channel touched before conversion.                                             |
| acquisition_channel | NVARCHAR(50)  | User’s first-touch channel.                                                                   |
| acquisition_date    | DATE          | Date of the first-touch acquisition event.                                                    |
| acquistiion_campaign| INT           | Marketing campaign tied to the user’s acquisition.                                                      |
  
---

### 10. **gold.fact_touchpath**
- **Purpose:** Reconstructs the user’s pre-purchase path.
- **Grain:**   One row per touchpoint contributing to a purchase
- **Columns:**

| Column Name         | Data Type     | Description                                                                                   |
|---------------------|---------------|-----------------------------------------------------------------------------------------------|
| touchpath_key       | INT           | Surrogate key identifying each touchpoint in a journey.                                       |
| user_id             | INT           | User whose journey is being reconstructed.                                                    |
| purchase_id         | INT           | Purchase associated with the journey (NULL for non-converters).                               |
| touchpoint_number   | INT           | Ordering number of the touchpoint within the user journey.                                    |
| touchpoint_time     | DATETIME2     | Timestamp of the touchpoint.                                                                  |
| channel             | NVARCHAR(50)  | Channel name of the touchpoint (e.g. Facebook Ads, Email)                                     |
| campaign_id         | INT           | Marketing campaign associated with the touchpoint.                                            |
| interaction_type    | NVARCHAR(50)  | Type of interaction recorded (View, Impression, Click)                                        |
  
---

### 11. **gold.fact_attribution_linear**
- **Purpose:** Takes the journey data from fact_touchpath and computes the linear revenue share. For each purchase, revenue is divided evenly among all touchpoints in the use's conversion path.
- **Grain:**   One row per per **attributed** touchpoint contributing to a purchase  (1 purchase x N touchpoints -> N rows with revenue_share)
- **Columns:**

| Column Name         | Data Type     | Description                                                                                   |
|---------------------|---------------|-----------------------------------------------------------------------------------------------|
| attribution_key     | INT           | Surrogate key for each revenue allocation.                                                    |
| user_id             | INT           | User related to the purchase.                                                                 |
| purchase_id         | INT           | Purchase whose revenue is being split.                                                        |
| touchpoint_number   | INT           | Ordering number of the touchpoint within the user journey.                                    |
| channel             | NVARCHAR(50)  | Channel receiving a share of revenue.                                                         |
| campaign_id         | INT           | Marketing campaign associated with the touchpoint.                                            |
| interaction_type    | NVARCHAR(50)  | Type of interaction recorded (View, Impression, Click)                                        |
| touchpoint_time     | DATETIME2     | Timestamp of the touchpoint.                                                                  |
| revenue_share       | DECIMAL(10,2) | Revenue portion allocated to this touchpoint.                                                 |
| total_revenue       | DECIMAL(10,2) | Total purchase revenue.                                                                       |
| touchpoints_in_path | INT           | Total number of touchpoints in the path.                                                      |
| purchase_date       | DATE          | Date of the purchase.                                                                         |
  
---

### 12. **gold.fact_attribution_last_touch**
- **Purpose:** Assigns 100% of purchase revenue to the last touchpoint before conversion for classic last-touch attribution.
- **Grain:**   One row per single last_touch resulting in a purchase = one row per purchase
- **Columns:**

| Column Name         | Data Type     | Description                                                                                   |
|---------------------|---------------|-----------------------------------------------------------------------------------------------|
| attribution_key     | INT           | Surrogate key for each last-touch allocation.                                                 |
| user_id             | INT           | User who made the purchase.                                                                   |
| purchase_id         | INT           | Purchase being attributed.                                                                    |
| last_touch_channel  | NVARCHAR(50)  | Channel of the last touchpoint.                                                               |
| last_touch_campaign | INT           | Campaign of the last touchpoint.                                                              |
| revenue             | DECIMAL(10,2) | Full purchase revenue assigned to this channel.                                               |
| purchase_date       | DATE          | Date of the purchase.                                                                         |
  
---

