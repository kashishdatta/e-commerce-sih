# E-Commerce Strategic Intelligence Hub (SIH)

**Author:** Kashish Datta
**Role:** Senior Data Analyst / Product Manager  
**Tech Stack:** `dbt Core`, `Google BigQuery`, `Streamlit`, `Python`, `SQL`, `Gemini API`

---

## 🚀 Executive Summary
The **Strategic Intelligence Hub (SIH)** is a comprehensive Modern Data Stack (MDS) implementation built on top of the Google Analytics 4 (GA4) e-commerce public dataset. 

This project demonstrates the end-to-end lifecycle of analytics engineering and decision support:
1. **Data Ingestion & Warehousing**: Handling complex, nested JSON data in Google BigQuery.
2. **Data Transformation (dbt)**: Building modular, tested, and documented SQL pipelines.
3. **Advanced Statistical Modeling**: Implementing dynamic Recency, Frequency, Monetary (RFM) segmentation and algorithmic Churn Prediction using SQL Window Functions.
4. **Decision Support UI (Streamlit)**: Creating an interactive dashboard with "What-If" scenario simulation, cohort retention heatmaps, and AI-powered strategy generation.

**Business Impact Highlight**: Identified optimization opportunities that could shift $200k+ in LTV by actively managing "At Risk" audiences using dynamic standard-deviation-based churn flags.

---

## 🏗 System Architecture

The project follows standard Analytics Engineering best practices. 

### 1. Data Source (BigQuery)
Using the real-world `ga4_obfuscated_sample_ecommerce` dataset, the raw data consists of highly nested arrays requiring UNNEST operations to extract session IDs, page locations, and campaign parameters.

### 2. The Transformation Layer (dbt)
The `sih_dbt` directory contains a 3-layer architecture:
- **Staging (`stg_`)**: Normalizes column names, handles timestamps, and unrolls JSON/Arrays.
- **Intermediate (`int_`)**: 
  - **Sessionization**: Groups individual clickstream events into robust 30-minute sessions using `LAG()` and cumulative window sums.
  - **User Stitching**: Maps `anonymous_id` to true `user_id` cross-device.
  - **Marketing Attribution**: Computes First-Touch and Last-Touch using `FIRST_VALUE()` to define multi-touch channel impact.
- **Marts (`mart_`)**: Final consumption layers designed as a Star Schema.
  - `mart_customer_health`: Calculates dynamic Recency gaps, RFM quintiles via `NTILE()`, and StdDev-based Churn Probability.
  - `mart_cohort_retention`: Builds a dynamic N-Month retention matrix.

*Code Quality*: Includes extensive `schema.yml` configurations with `dbt_expectations` tests ensuring zero negative revenues and 100% uniqueness guarantees.

### 3. The Visualization Layer (Streamlit)
A multi-page Python web application serving as the UI layer:
- **Executive Overview**: High-level KPIs (LTV, CAC, Churn) and the dbt Data Health status flag.
- **Deep Dive (Audience Segmentation)**: Allows PMs and Marketers to slice the data by RFM segment to download target audiences directly to a CSV. Features a **Gemini AI integration** to analyze segment data and output strategic retention advice.
- **What-If Simulator**: Implements non-linear LTV projection models allowing stakeholders to simulate the 12-month revenue impact of tweaking retention and AOV by percentage points.

---

## 📊 The "Analyst" Insights
Through building this tool, several key strategic recommendations emerged:

1. **The Compounding Nature of Retention**: As shown in the "What-If" simulator, a mere 5% improvement in retention for the core cohort yields disproportionate (+20%) LTV growth over 12 months due to compounding subscription value.
2. **Dynamic Over Static Churn**: A flat "30-day" churn flag is ineffective. By building the `is_high_churn_risk` flag (calculating if a user's current absence is $> 2\sigma$ from their personal inter-purchase mean), we accurately identify churn *before* it happens, increasing reactivation campaign efficiency. 

---

## ⚙️ How to Run Locally

### 1. Requirements
Ensure you have a GCP Project ID with BigQuery enabled, Python 3.9+, and dbt-bigquery installed.

### 2. Setup dbt
Navigate to `sih_dbt` and verify your `profiles.yml` targets your GCP project.
```bash
cd sih_dbt
dbt deps
dbt seed
dbt run
dbt test
dbt docs generate
dbt docs serve
```

### 3. Run Streamlit App
Navigate to the root directory and start the Streamlit server.
```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt # (Contains streamlit, pandas, plotly)
streamlit run streamlit_app/app.py
```
