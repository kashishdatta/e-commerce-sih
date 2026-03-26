WITH events AS (
    SELECT * FROM {{ ref('stg_ga4__events') }}
),

-- 1. Sort events and calculate time difference to the previous event for each user
ordered_events AS (
    SELECT
        *,
        LAG(event_time) OVER (
            PARTITION BY anonymous_id 
            ORDER BY event_time
        ) AS previous_event_time
    FROM events
),

-- 2. Flag when a new session starts (gap > 30 minutes, or first event)
session_flags AS (
    SELECT
        *,
        CASE
            WHEN previous_event_time IS NULL THEN 1
            WHEN TIMESTAMP_DIFF(event_time, previous_event_time, MINUTE) > 30 THEN 1
            ELSE 0
        END AS is_new_session_flag
    FROM ordered_events
),

-- 3. Create a unique session identifier by a running sum of the flags
assigned_sessions AS (
    SELECT
        *,
        SUM(is_new_session_flag) OVER (
            PARTITION BY anonymous_id 
            ORDER BY event_time 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS generated_session_index
    FROM session_flags
),

-- 4. Aggregate session metrics natively using Window Functions logic
session_aggregation AS (
    SELECT
        anonymous_id,
        CONCAT(anonymous_id, '-', CAST(generated_session_index AS STRING)) AS custom_session_id,
        MIN(event_time) AS session_start_time,
        MAX(event_time) AS session_end_time,
        COUNT(event_name) AS events_in_session,
        SUM(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS total_purchases,
        SUM(purchase_revenue) AS session_revenue,
        MAX(device_category) AS primary_device,
        MAX(country) AS geo_country,
        -- Get the first traffic source of the session
        MAX(CASE WHEN rank_in_session = 1 THEN param_source END) AS start_source,
        MAX(CASE WHEN rank_in_session = 1 THEN param_medium END) AS start_medium
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY anonymous_id, generated_session_index ORDER BY event_time) as rank_in_session
        FROM assigned_sessions
    ) sub
    GROUP BY 
        1, 2
)

SELECT * FROM session_aggregation
