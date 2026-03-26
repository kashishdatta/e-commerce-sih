WITH events AS (
    SELECT 
        anonymous_id,
        session_id,
        event_name,
        event_time
    FROM {{ ref('stg_ga4__events') }}
    WHERE event_name IN ('page_view', 'view_item', 'add_to_cart', 'begin_checkout', 'purchase')
      AND session_id IS NOT NULL
),

ranked_events AS (
    SELECT
        anonymous_id,
        session_id,
        event_name,
        event_time,
        -- Get the next event in the sequence to check progression
        LEAD(event_name) OVER (
            PARTITION BY anonymous_id, session_id 
            ORDER BY event_time ASC
        ) as next_event_name,
        
        -- Get the time of the next event
        LEAD(event_time) OVER (
            PARTITION BY anonymous_id, session_id 
            ORDER BY event_time ASC
        ) as next_event_time,
        
        -- Map GA4 events to chronological funnel steps
        CASE 
            WHEN event_name = 'page_view' THEN 1
            WHEN event_name = 'view_item' THEN 2
            WHEN event_name = 'add_to_cart' THEN 3
            WHEN event_name = 'begin_checkout' THEN 4
            WHEN event_name = 'purchase' THEN 5
            ELSE 0 
        END as funnel_step
    FROM events
)

SELECT * FROM ranked_events
