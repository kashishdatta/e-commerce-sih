import streamlit as st

st.set_page_config(
    page_title="E-Commerce Strategic Intelligence Hub",
    page_icon="📊",
    layout="wide",
)

st.title("E-Commerce Strategic Intelligence Hub (SIH)")

st.markdown("""
Welcome to the SIH. This dashboard serves as a Decision Support System leveraging standard Modern Data Stack practices. Use the navigation sidebar to explore:

- **Executive Overview**: High-level KPIs and Cohort Retention / CLV heatmaps.
- **Deep Dive**: Filter RFM 3D segments and get AI-powered insights.
- **What-If Simulator**: Project revenue impacts by adjusting retention parameters.
- **Market Basket**: Discover top product associations using Lift and Confidence.
- **Attribution**: Linear, U-Shaped, and Time-Decay fractional modeling comparisons.
- **Funnel Analysis**: Exact drop-offs and time-to-convert tracking natively in SQL.
- **Anomaly Detection**: Bollinger Band monitoring of volatile revenue streams.

---

### System Architecture
- **Data Warehouse**: Google BigQuery
- **Data Transformation**: dbt Core
- **BI Layer**: Streamlit
- **Intelligence**: Gemini API
""")
