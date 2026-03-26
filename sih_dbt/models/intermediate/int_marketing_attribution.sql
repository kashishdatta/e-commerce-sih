WITH events AS (
    SELECT * FROM {{ ref('stg_ga4__events') }}
    WHERE event_name = 'purchase'
),

stitched_users AS (
    SELECT * FROM {{ ref('int_user_stitching') }}
),

-- Get the session context for the purchases
mapped_events AS (
    SELECT 
        COALESCE(su.stitched_user_id, e.anonymous_id) AS global_user_id,
        e.transaction_id,
        e.purchase_revenue,
        e.event_time,
        e.param_source,
        e.param_medium,
        e.param_campaign
    FROM events e
    LEFT JOIN stitched_users su ON e.anonymous_id = su.anonymous_id
),

-- Use Window functions to get the first touch and last touch for the user
attributed_revenue AS (
    SELECT
        global_user_id,
        transaction_id,
        purchase_revenue,
        event_time,
        FIRST_VALUE(param_source) OVER (PARTITION BY global_user_id ORDER BY event_time ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as first_touch_source,
        FIRST_VALUE(param_medium) OVER (PARTITION BY global_user_id ORDER BY event_time ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as first_touch_medium,
        
        LAST_VALUE(param_source) OVER (PARTITION BY global_user_id ORDER BY event_time ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as last_touch_source,
        LAST_VALUE(param_medium) OVER (PARTITION BY global_user_id ORDER BY event_time ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as last_touch_medium

    FROM mapped_events
)

SELECT DISTINCT * FROM attributed_revenue
