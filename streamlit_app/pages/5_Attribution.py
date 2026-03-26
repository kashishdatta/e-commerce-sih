import streamlit as st
import pandas as pd
import plotly.graph_objects as go
from mock_data import get_mock_mta_data

st.set_page_config(page_title="Multi-Touch Attribution", page_icon="🧩", layout="wide")

st.title("Advanced Multi-Touch Attribution (MTA)")
st.markdown("Comparing fractional revenue credit across complex journey touchpoints using different SQL attribution models (Linear, U-Shaped, Time-Decay).")

df = get_mock_mta_data()

models = ['First Touch', 'Last Touch', 'Linear', 'U-Shaped', 'Time Decay']
model_columns = ['first_touch_revenue', 'last_touch_revenue', 'linear_revenue', 'ushaped_revenue', 'time_decay_revenue']

st.subheader("Revenue Allocation by Attribution Model")

fig = go.Figure()

channels = df['channel'].tolist()

for i, col in enumerate(model_columns):
    fig.add_trace(go.Bar(
        x=channels,
        y=df[col].tolist(),
        name=models[i]
    ))

fig.update_layout(
    barmode='group',
    xaxis_title='Marketing Channel',
    yaxis_title='Attributed Revenue ($)',
    title='Channel Value Under Different MTA Lenses',
    height=500
)

st.plotly_chart(fig, use_container_width=True)

st.subheader("Attribution Data Table")
st.dataframe(
    df.style.format({
        'first_touch_revenue': '${:,.2f}',
        'last_touch_revenue': '${:,.2f}',
        'linear_revenue': '${:,.2f}',
        'ushaped_revenue': '${:,.2f}',
        'time_decay_revenue': '${:,.2f}'
    })
)

st.info("💡 **Analyst Insight**: Look at how 'Paid Search' spikes under First-Touch but drops off under Last-Touch. This means Paid Search is an *initiator* channel. Meanwhile, 'Direct' sweeps up the Last-Touch credit. Transitioning budget based on 'Linear' or 'U-Shaped' ensures top-of-funnel channels aren't starved of budget.")
