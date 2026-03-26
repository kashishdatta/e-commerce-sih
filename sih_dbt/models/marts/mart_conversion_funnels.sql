WITH session_events AS (
    SELECT * FROM {{ ref('int_session_events') }}
),

-- Find the deepest step reached by each session and the exact timestamps
session_funnel_depth AS (
    SELECT
        anonymous_id,
        session_id,
        MAX(funnel_step) as max_funnel_step,
        MIN(CASE WHEN funnel_step = 1 THEN event_time END) as first_page_view_time,
        MIN(CASE WHEN funnel_step = 5 THEN event_time END) as purchase_time
    FROM session_events
    GROUP BY 1, 2
),

funnel_counts AS (
    SELECT
        COUNT(DISTINCT session_id) as total_sessions,
        COUNT(DISTINCT CASE WHEN max_funnel_step >= 1 THEN session_id END) as step_1_page_view,
        COUNT(DISTINCT CASE WHEN max_funnel_step >= 2 THEN session_id END) as step_2_view_item,
        COUNT(DISTINCT CASE WHEN max_funnel_step >= 3 THEN session_id END) as step_3_add_to_cart,
        COUNT(DISTINCT CASE WHEN max_funnel_step >= 4 THEN session_id END) as step_4_checkout,
        COUNT(DISTINCT CASE WHEN max_funnel_step = 5 THEN session_id END) as step_5_purchase,
        
        -- Compute exact time to convert in minutes for successful conversions via TIMESTAMP_DIFF
        AVG(TIMESTAMP_DIFF(purchase_time, first_page_view_time, MINUTE)) as avg_time_to_convert_minutes
    FROM session_funnel_depth
)

SELECT * FROM funnel_counts
