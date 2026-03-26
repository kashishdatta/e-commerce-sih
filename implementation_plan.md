# SIH Upgrade Implementation Plan

**Objective:** Upgrade the E-Commerce Strategic Intelligence Hub (SIH) with 6 advanced analytical features leveraging complex BigQuery SQL (dbt) and Streamlit visualizations.

## Feature 1: Market Basket Analysis (Association Rules)
- **dbt Models:**
  - `int_item_pairs.sql`: Self-join `stg_ga4__events` items on `transaction_id`.
  - `mart_market_basket.sql`: Calculate Support, Confidence, and Lift for product pairs.
- **Streamlit UI:** `pages/4_Market_Basket.py` with a Plotly network graph or heatmap.

## Feature 2: Advanced Multi-Touch Attribution (MTA)
- **dbt Models:**
  - `int_mta_touchpoints.sql`: Use window functions to chronologically order all touchpoints before purchase.
  - `mart_mta_models.sql`: Distribute conversion revenue fractionally across linear, u-shaped, and time-decay models.
- **Streamlit UI:** Update `pages/2_Deep_Dive.py` or new page `pages/5_Attribution.py` with stacked bar charts comparing models.

## Feature 3: Cohort Retention & Customer Lifetime Value (CLV)
- **dbt Models:**
  - `int_user_first_purchase.sql`: Identify the first purchase date.
  - `mart_cohort_clv.sql`: Map subsequent purchases to relative months and calculate cumulative CLV.
- **Streamlit UI:** Update `pages/1_Executive_Overview.py` with Plotly triangle cohort retention heatmap.

## Feature 4: Dynamic Conversion Funnels & Time-to-Convert
- **dbt Models:**
  - `int_session_events.sql`: Use `LEAD()` to track step-by-step sequential events (Home -> Product -> Cart -> Checkout).
  - `mart_conversion_funnels.sql`: Compute funnel drop-offs and median time-to-convert based on timestamp diffs.
- **Streamlit UI:** `pages/6_Funnel_Analysis.py` with a Plotly Sankey diagram or Funnel chart.

## Feature 5: RFM Segmentation (Recency, Frequency, Monetary)
- **dbt Models:**
  - Update `mart_customer_health.sql` to strictly use `NTILE(5)` for R, F, M bucketing and assigning business segments like "Champions", "At Risk".
- **Streamlit UI:** Update `pages/2_Deep_Dive.py` with a Plotly Treemap or 3D scatter plot of RFM segments.

## Feature 6: Statistical SQL Anomaly Detection (Bollinger Bands)
- **dbt Models:**
  - `mart_daily_revenue_anomalies.sql`: Calculate rolling 14-day averages and standard deviations using `OVER()` window rows, flagging `value > avg + 2*sigma`.
- **Streamlit UI:** `pages/7_Anomaly_Detection.py` with Plotly time-series line chart featuring shaded confidence bands and anomaly markers.
