import streamlit as st
import pandas as pd
import numpy as np
import plotly.graph_objects as go
from mock_data import get_mock_kpis

st.set_page_config(page_title="What-If Simulator", page_icon="🎛️", layout="wide")

st.title("Strategic What-If Simulator")
st.markdown("Use this tool to see the 12-month downstream impact of altering key metrics.")

kpis = get_mock_kpis()
current_retention = 1 - kpis['churn_rate']
current_ltv = kpis['ltv']
current_users = 10000

st.sidebar.header("Simulation Parameters")
retention_shift = st.sidebar.slider("Retention Improvement (%)", min_value=-10.0, max_value=20.0, value=5.0, step=0.5)
aov_shift = st.sidebar.slider("AOV Shift (%)", min_value=-5.0, max_value=25.0, value=2.0, step=0.5)

# Calculations
new_retention = current_retention * (1 + (retention_shift / 100))
new_ltv = current_ltv * (new_retention / current_retention) * (1 + (aov_shift / 100))

projected_revenue_current = current_users * current_ltv
projected_revenue_new = current_users * new_ltv
revenue_delta = projected_revenue_new - projected_revenue_current

col1, col2, col3 = st.columns(3)
col1.metric("Projected 12M LTV (Current)", f"${current_ltv:.2f}")
col2.metric("Projected 12M LTV (Simulated)", f"${new_ltv:.2f}", f"${new_ltv-current_ltv:+.2f}")
col3.metric("Total Revenue Impact", f"${projected_revenue_new:,.0f}", f"${revenue_delta:+,.0f}")

# Chart
months = np.arange(1, 13)
current_decay = [current_users * (current_retention ** m) * (current_ltv/12) for m in months]
simulated_decay = [current_users * (new_retention ** m) * (new_ltv/12) for m in months]

fig = go.Figure()
fig.add_trace(go.Bar(x=months, y=current_decay, name='Current Baseline', marker_color='#8884d8'))
fig.add_trace(go.Bar(x=months, y=simulated_decay, name='Simulated Impact', marker_color='#82ca9d'))
fig.update_layout(title="Monthly Projected Lifetime Revenue (12 Months)", xaxis_title="Month", yaxis_title="Revenue ($)", barmode='group')

st.plotly_chart(fig, use_container_width=True)

st.info("💡 **Analyst Insight**: This demonstrates the compound impact of retention. A small percentage increase in retention disproportionately impacts cumulative LTV.")
