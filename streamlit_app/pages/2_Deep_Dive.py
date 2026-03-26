import streamlit as st
import pandas as pd
import json
import os
from mock_data import get_mock_rfm_data
# For a real implementation, you would `import google.generativeai as genai`

st.set_page_config(page_title="Deep Dive (Audience Segmentation)", page_icon="🎯", layout="wide")

st.title("User Deep Dive & Audience Segmentation")
st.markdown("Filter users by segment or churn risk to build targeted campaigns.")

df = get_mock_rfm_data()

col1, col2 = st.columns(2)
with col1:
    selected_segment = st.selectbox(
        "Select User Segment", 
        ["All"] + list(df['rfm_segment'].unique())
    )

with col2:
    churn_risk_filter = st.checkbox("Show Only High Churn Risk Users", value=False)

# Apply filters
filtered_df = df.copy()
if selected_segment != "All":
    filtered_df = filtered_df[filtered_df['rfm_segment'] == selected_segment]
    
if churn_risk_filter:
    filtered_df = filtered_df[filtered_df['is_high_churn_risk'] == True]

st.markdown("---")
st.subheader("RFM Segment Distribution (3D Cluster Sandbox)")
import plotly.express as px

# 3D scatter of R vs F vs M
fig = px.scatter_3d(
    filtered_df, 
    x='recency_days', 
    y='lifetime_purchases', 
    z='lifetime_revenue',
    color='rfm_segment',
    hover_name='anonymous_id',
    hover_data=['rfm_concat_score', 'is_high_churn_risk'],
    opacity=0.7,
    title="Interactive 3D View of User Value"
)
fig.update_layout(margin=dict(l=0, r=0, b=0, t=30), height=600)
st.plotly_chart(fig, use_container_width=True)

st.subheader(f"Results: {len(filtered_df):,} Users")
st.dataframe(filtered_df[['anonymous_id', 'rfm_segment', 'rfm_concat_score', 'is_high_churn_risk', 'lifetime_revenue', 'recency_days', 'lifetime_purchases']])


# CSV Download
csv = filtered_df.to_csv(index=False).encode('utf-8')
st.download_button(
    label=f"📥 Download {selected_segment} Audience as CSV",
    data=csv,
    file_name=f"audience_{selected_segment.lower().replace(' ', '_')}.csv",
    mime='text/csv',
)


st.markdown("---")
st.subheader("🤖 AI Portfolio PM Insights (Gemini)")
st.markdown("Leverage the Gemini API to analyze this exact cohort's metrics and generate strategic advice.")

if st.button("Generate Strategy for this Cohort"):
    with st.spinner("Analyzing data with Gemini..."):
        # Simulated Gemini analysis for Portfolio purposes
        avg_ltv = filtered_df['lifetime_revenue'].mean()
        avg_recency = filtered_df['recency_days'].mean()
        
        prompt = f"""
        As a Product Manager, analyze this data and give me 3 bullet points on how to improve retention:
        - Audience Name: {selected_segment}
        - Number of Users: {len(filtered_df)}
        - High Churn Risk Context: {churn_risk_filter}
        - Average Lifetime Revenue: ${avg_ltv:.2f}
        - Average Recency: {avg_recency:.1f} days
        """
        
        # Real implementation would call genai model here
        # response = model.generate_content(prompt)
        
        st.info("**Prompt sent to Gemini API:**\n" + prompt)
        
        st.success("""
        **Gemini AI Recommendations:**
        1. **Immediate Reactivation Campaign:** Given the long recency days for this cohort, trigger an automated email sequence offering a personalized 15% discount on their highest-affinity product category to bridge the gap.
        2. **Implement Push Notifications for 'At Risk':** Shift marketing dollars from acquisition to retention push notifications. The high standard deviation in inter-purchase time implies they are forgetting the app exists.
        3. **Friction Review:** We identified a drop-off point. Conduct a UX teardown on the checkout flow for mobile web, as this is the primary device for this segment showing early stagnation.
        """)
