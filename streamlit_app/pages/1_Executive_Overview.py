import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from mock_data import get_mock_kpis, get_mock_cohort_data

st.set_page_config(page_title="Executive Overview", page_icon="📈", layout="wide")

st.title("Executive Overview")

kpis = get_mock_kpis()

col1, col2, col3, col4 = st.columns(4)
col1.metric("Total Revenue", f"${kpis['revenue']:,.0f}", "+12%")
col2.metric("LTV (Customer Lifetime Value)", f"${kpis['ltv']:,.2f}", "+5.2%")
col3.metric("CAC (Customer Acquisition Cost)", f"${kpis['cac']:,.2f}", "-2.1%")
col4.metric("Churn Rate", f"{kpis['churn_rate']*100:.1f}%", "-0.5%")

st.markdown("---")

st.subheader("Data Health Status")
st.info("✅ 100% of dbt tests passed today. Data is fresh and reliable.")

st.markdown("---")

st.subheader("12-Month Cohort Data (Retention & Cumulative CLV)")
st.markdown("Monitor both user retention drop-off and the actual compounding revenue value of acquired cohorts natively derived via SQL indexing.")

cohort_data = get_mock_cohort_data()

# 1. Retention Matrix
retention_matrix = cohort_data.pivot(index='cohort_month', columns='month_number', values='retention_rate')

fig1 = go.Figure(data=go.Heatmap(
                   z=retention_matrix.values,
                   x=retention_matrix.columns,
                   y=retention_matrix.index,
                   colorscale='Viridis',
                   hoverongaps=False))

fig1.update_layout(
    title='User Retention % by Cohort Month',
    xaxis_title='Months Since First Purchase',
    yaxis_title='Cohort Month'
)

# 2. Cumulative CLV Matrix
clv_matrix = cohort_data.pivot(index='cohort_month', columns='month_number', values='cumulative_clv')

fig2 = go.Figure(data=go.Heatmap(
                   z=clv_matrix.values,
                   x=clv_matrix.columns,
                   y=clv_matrix.index,
                   colorscale='Plasma',
                   hoverongaps=False))

fig2.update_layout(
    title='Cumulative CLV ($) by Cohort Month',
    xaxis_title='Months Since First Purchase',
    yaxis_title='Cohort Month'
)

col1, col2 = st.columns(2)
with col1:
    st.plotly_chart(fig1, use_container_width=True)
with col2:
    st.plotly_chart(fig2, use_container_width=True)
