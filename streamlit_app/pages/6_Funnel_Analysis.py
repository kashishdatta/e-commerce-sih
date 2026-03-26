import streamlit as st
import pandas as pd
import plotly.graph_objects as go
from mock_data import get_mock_funnel_data

st.set_page_config(page_title="Funnel Analysis", page_icon="🔽", layout="wide")

st.title("Dynamic Conversion Funnels")
st.markdown("A deep dive into sequential user journeys using advanced SQL analytical indexing to measure precise step drop-offs and true Time-to-Convert.")

df = get_mock_funnel_data()

# Read the single row
row = df.iloc[0]

# Calculate progression metrics
steps = ['Page View', 'View Item', 'Add to Cart', 'Begin Checkout', 'Purchase']
values = [row['step_1_page_view'], row['step_2_view_item'], row['step_3_add_to_cart'], row['step_4_checkout'], row['step_5_purchase']]

col1, col2 = st.columns([3, 1])

with col1:
    fig = go.Figure(go.Funnel(
        y=steps,
        x=values,
        textinfo="value+percent initial",
        marker={"color": ["#8884d8", "#82ca9d", "#ffc658", "#ff8042", "#0088FE"]}
    ))
    
    fig.update_layout(
        title="Chronological User Journey Funnel",
        height=500
    )
    st.plotly_chart(fig, use_container_width=True)

with col2:
    st.subheader("Conversion KPIs")
    
    # Calculate drops
    overall_conv = values[-1] / values[0]
    st.metric("Overall Conversion Rate", f"{overall_conv * 100:.1f}%")
    
    avg_minutes = row['avg_time_to_convert_minutes']
    st.metric("Avg Time-to-Convert", f"{avg_minutes:.1f} mins")
    
    # Find biggest drop
    drops = [(values[i] - values[i+1]) / values[i] for i in range(len(values)-1)]
    max_drop_idx = drops.index(max(drops))
    st.metric("Largest Drop Step", f"{steps[max_drop_idx]} \u2192 {steps[max_drop_idx+1]}", f"-{drops[max_drop_idx]*100:.1f}%", delta_color="inverse")

st.info("💡 **Analyst Insight**: The time-to-convert allows Product Managers to distinguish between impulse buyers and those requiring long consideration phases. SQL natively identified this exact timestamp gap utilizing the `MIN()` and `MAX()` conditional boundary rules.")
