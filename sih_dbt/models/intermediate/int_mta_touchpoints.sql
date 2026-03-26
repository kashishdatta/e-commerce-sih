WITH conversions AS (
    SELECT
        transaction_id,
        anonymous_id,
        event_time AS conversion_time,
        purchase_revenue
    FROM {{ ref('stg_ga4__events') }}
    WHERE event_name = 'purchase' 
      AND transaction_id IS NOT NULL
),

sessions AS (
    SELECT
        custom_session_id,
        anonymous_id,
        session_start_time,
        start_source,
        start_medium
    FROM {{ ref('int_sessions') }}
),

-- Join all sessions that happened before or at the time of the conversion
journey_touchpoints AS (
    SELECT
        c.transaction_id,
        c.conversion_time,
        c.purchase_revenue,
        s.custom_session_id,
        s.session_start_time,
        COALESCE(s.start_source, 'direct') AS channel,
        
        -- Chronological rank of the touchpoint leading to conversion
        ROW_NUMBER() OVER (
            PARTITION BY c.transaction_id 
            ORDER BY s.session_start_time ASC
        ) AS touchpoint_rank,
        
        -- Total number of touchpoints in this journey
        COUNT(*) OVER (
            PARTITION BY c.transaction_id
        ) AS total_touchpoints
        
    FROM conversions c
    JOIN sessions s 
      ON c.anonymous_id = s.anonymous_id
     AND s.session_start_time <= c.conversion_time
)

SELECT * FROM journey_touchpoints
