import streamlit as st
import pandas as pd
import plotly.graph_objects as go
from mock_data import get_mock_anomaly_data

st.set_page_config(page_title="Statistical Anomalies", page_icon="🚨", layout="wide")

st.title("Statistical SQL Anomaly Detection")
st.markdown("Monitoring daily revenue for statistical deviations using 14-day rolling averages and Bollinger Bands ($Average \pm 2\sigma$) calculated natively in BigQuery using window functions.")

df = get_mock_anomaly_data()

fig = go.Figure()

# Upper Band
fig.add_trace(go.Scatter(
    x=df['purchase_date'], 
    y=df['upper_band'],
    line=dict(width=0),
    marker=dict(color="#444"),
    showlegend=False,
    name='Upper Band'
))

# Lower Band
fig.add_trace(go.Scatter(
    x=df['purchase_date'], 
    y=df['lower_band'],
    line=dict(width=0),
    marker=dict(color="#444"),
    fill='tonexty',
    fillcolor='rgba(68, 68, 68, 0.2)',
    showlegend=False,
    name='Lower Band'
))

# 14-Day Average
fig.add_trace(go.Scatter(
    x=df['purchase_date'],
    y=df['rolling_14d_avg_revenue'],
    mode='lines',
    line=dict(color='orange', width=2, dash='dash'),
    name='14-Day Rolling Avg'
))

# Daily Revenue (Actual)
fig.add_trace(go.Scatter(
    x=df['purchase_date'],
    y=df['daily_revenue'],
    mode='lines',
    line=dict(color='#8884d8', width=2),
    name='Daily Revenue'
))

# Anomalies (Spikes/Drops)
anomalies = df[df['anomaly_flag'] != 'Normal']
fig.add_trace(go.Scatter(
    x=anomalies['purchase_date'],
    y=anomalies['daily_revenue'],
    mode='markers',
    marker=dict(color='red', size=10, symbol='circle-x'),
    name='Statistical Anomaly'
))

fig.update_layout(
    title='Daily Revenue vs Bollinger Bands',
    xaxis_title='Date',
    yaxis_title='Revenue ($)',
    height=600,
    hovermode="x unified"
)

st.plotly_chart(fig, use_container_width=True)

st.subheader(f"Detected Anomalies: {len(anomalies)} Records")
st.dataframe(
    anomalies[['purchase_date', 'daily_revenue', 'rolling_14d_avg_revenue', 'upper_band', 'lower_band', 'anomaly_flag']]
    .style.format({
        'daily_revenue': '${:,.2f}',
        'rolling_14d_avg_revenue': '${:,.2f}',
        'upper_band': '${:,.2f}',
        'lower_band': '${:,.2f}'
    })
)

st.info("💡 **Analyst Insight**: Instead of manual BI alerting, this Data Pipeline natively flags dates where revenue variance strictly breaches mathematical confidence intervals. A spike might indicate a viral campaign; a drop could signal a broken payment gateway.")
