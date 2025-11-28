# Data Catalog for Gold Layer

## Overview
The Gold Layer is the business-level data representation, structured to support analytical and reporting use cases. It consists of **dimension tables** and **fact tables** for specific business metrics.

---

### 1. **gold.dim_date**
- **Purpose:** Provides standardized calender dimension that enables time-based analysis, reporting and aggregation.
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
| day_name         | VARCHAR       | The name of the weekday (e.g., 'Monday') for readable time-based insights.                    |
| is_weekend       | BIT           | A flag indicating whether the date falls on a weekend, supporting behavior analysis.          |

---

### 2. **gold.dim_user**
- **Purpose:** Stores unique user identities so behaviors, conversions, and marketing interactions can be analyzed at customer level.
- **Columns:**

| Column Name         | Data Type     | Description                                                                                   |
|---------------------|---------------|-----------------------------------------------------------------------------------------------|
| user_key            | INT           | Surrogate primary key that uniquely identifies each user in the dimensional model.            |
| user_id             | INT           | The natural user identifier from source systems, used to join facts to the user dimension.    |

---

### 3. **gold.dim_campaign**
- **Purpose:** Defines marketing channels and their broader categories to support channel attribution and cross-channel analytics.
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
- **Columns:**

| Column Name         | Data Type     | Description                                                                                   |
|---------------------|---------------|-----------------------------------------------------------------------------------------------|
| channel_key         | INT           | Surrogate primary key that uniquely identifies each marketing channel.                        |
| channel_name        | NVARCHAR(50)  | The human-readable name of the channel (e.g., "Facebook", "Email") used for reporting.        |
| category            | NVARCHAR(50)  | Groups marketing channels into broader logical categories (e.g., Paid Search).                |
 
---

