WITH raw_events AS (
    SELECT
        *
    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
),

extracted_params AS (
    SELECT
        event_date,
        event_timestamp,
        TIMESTAMP_MICROS(event_timestamp) as event_time,
        event_name,
        user_pseudo_id AS anonymous_id,
        user_id,
        device.category AS device_category,
        device.operating_system,
        device.web_info.browser,
        geo.continent,
        geo.country,
        geo.city,
        traffic_source.source AS start_source,
        traffic_source.medium AS start_medium,
        traffic_source.name AS start_campaign,
        
        -- Extract nested event parameters using UNNEST
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS page_location,
        (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
        (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number') AS session_number,
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source') AS param_source,
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'medium') AS param_medium,
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'campaign') AS param_campaign,
        
        -- Ecommerce specific
        ecommerce.purchase_revenue_in_usd AS purchase_revenue,
        ecommerce.transaction_id,
        ecommerce.total_item_quantity
    FROM
        raw_events
)

SELECT * FROM extracted_params
