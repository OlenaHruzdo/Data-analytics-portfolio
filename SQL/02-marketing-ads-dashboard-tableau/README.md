# Marketing Ads Performance Dashboard

## Overview
This project analyses the performance of Facebook Ads and Google Ads campaigns in a single interactive dashboard.

The data was prepared with PostgreSQL in DBeaver. It was stored in four tables (three Facebook tables and one Google table), so it had to be joined, cleaned and combined into one analytical dataset before visualisation in Tableau Public.

## Objective
The goal is to build one dataset and one dashboard that show:

* spend, impressions, clicks and leads for both advertising platforms
* efficiency metrics: CTR, CPC, CPM, CPL and ROMI
* funnel conversion rates (clicks to leads, reach to leads)
* the relationship between advertising spend and the number of leads
* a ranking and comparison of individual campaigns

The observation period covers 2021–2022.

## SQL Approach
The query consists of a temporary function, three CTEs and a final aggregation:

* `pg_temp.decode_url_part` — temporary function that decodes URL-encoded text (including Cyrillic)
* `all_ads_data` — joins Facebook facts with the campaign and ad set lookup tables, then combines them with Google Ads using `UNION ALL` and adds the `source` field
* `raw_aggregated` — extracts the raw `utm_campaign` value with a regular expression and sums the metrics, replacing NULLs with 0 (`COALESCE`)
* `prepared_data` — decodes `utm_campaign`, converts it to lower case and returns NULL for missing, empty or `nan` values
* Final SELECT — aggregates the six metrics (`total_spend`, `total_impressions`, `total_reach`, `total_clicks`, `total_leads`, `total_value`) by date, source, campaign, ad set and UTM campaign

Data quality decisions:

* `LEFT JOIN` is used for the lookup tables, so no fact rows are lost
* completely empty rows (`ad_date IS NULL`) are excluded
* missing campaign and ad set names are labelled `Unknown campaign` and `Unknown adset`
* a second aggregation after decoding is needed because different raw values can decode to the same text (for example `%D0` vs `%d0`, or `+` vs `%20`)

## Tableau Dashboard
The SQL output was exported to CSV and used as the data source in Tableau Public.

[View the dashboard on Tableau Public →](PASTE_YOUR_PUBLIC_TABLEAU_LINK_HERE)

Dashboard components:

* **KPI cards** — Spend, Impressions, Clicks, Leads, CTR, CPC, CPL, CPM, ROMI
* **Metric Trend** — line chart of the selected metric over time, split by platform
* **Campaign Ranking** — horizontal bar chart ranking campaigns by the selected metric
* **Spend vs Leads Analysis** — dual-axis chart with a correlation card (floating container)
* **Campaign Efficiency Analysis** — scatter plot: one point per campaign, colour by platform, size by leads
* **Parameter** `Select Metric` — switches the metric in the trend, ranking and scatter charts
* **Filter Action** — clicking a campaign in the scatter plot filters the trend and spend vs leads charts (`campaign_name` and `source`)
* **Filters** — date (month), source, campaign name, ad set name, UTM campaign

Calculated fields: CTR, CPC, CPM, CPL, ROMI, Clicks to Leads Conversion, Reach to Leads Conversion, `monthly_leads` and `monthly_spend` (FIXED LOD), `corr leads spend` (correlation between monthly spend and leads), `Selected Metric`.

## Tools

* PostgreSQL
* DBeaver
* Tableau Public

## Files

* `marketing_ads_dataset.sql` — SQL query used to prepare the analytical dataset
* `marketing_ads_dataset.csv` — exported dataset used in Tableau

## Skills demonstrated
SQL (CTEs, joins, UNION ALL, regular expressions, COALESCE, user-defined functions, aggregation) · PostgreSQL · DBeaver · Tableau (calculated fields, LOD expressions, parameters, dual-axis charts, dashboard actions, filters) · Marketing analytics (CTR, CPC, CPM, CPL, ROMI)
