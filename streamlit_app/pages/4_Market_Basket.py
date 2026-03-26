import streamlit as st
import pandas as pd
import numpy as np
import plotly.graph_objects as go
from mock_data import get_mock_market_basket_data

st.set_page_config(page_title="Market Basket Analysis", page_icon="🛒", layout="wide")

st.title("Market Basket Analysis (Association Rules)")
st.markdown("Discover which products are frequently purchased together using Support, Confidence, and Lift metrics.")

df = get_mock_market_basket_data()

# Summary Metrics
col1, col2, col3 = st.columns(3)
col1.metric("Total Rules Discovered", len(df))
col2.metric("Highest Lift", f"{df['lift'].max():.2f}")
col3.metric("Highest Confidence", f"{df['confidence_a_to_b'].max() * 100:.1f}%")

st.markdown("---")

st.subheader("Product Affinities Network")
st.markdown("Visualizing product relationships where Lift > 1.5.")

top_rules = df[df['lift'] > 1.5].head(20)

# Build a Network Graph using Plotly
nodes = list(set(top_rules['item_a'].tolist() + top_rules['item_b'].tolist()))
node_indices = {node: i for i, node in enumerate(nodes)}

# Create Sankey diagram or Heatmap. Let's do a Heatmap of Lift for simplicity and clarity.
pivot = top_rules.pivot(index='item_a', columns='item_b', values='lift').fillna(0)

fig = go.Figure(data=go.Heatmap(
    z=pivot.values,
    x=pivot.columns,
    y=pivot.index,
    colorscale='Plasma',
    hoverongaps=False
))

fig.update_layout(
    title='Product Pair Lift (Heatmap)',
    xaxis_title='Product B',
    yaxis_title='Product A',
    height=600
)

st.plotly_chart(fig, use_container_width=True)

st.subheader("Association Rules Data")
st.dataframe(
    df[['item_a', 'item_b', 'pair_txn_count', 'support', 'confidence_a_to_b', 'lift']]
    .sort_values(by='lift', ascending=False)
    .style.format({
        'support': '{:.4f}',
        'confidence_a_to_b': '{:.2%}',
        'lift': '{:.2f}'
    })
)

st.info("💡 **Analyst Insight**: High Lift (> 1.0) indicates that the presence of Product A strongly increases the probability of purchasing Product B. Use these pairs for targeted upselling or product bundling.")
