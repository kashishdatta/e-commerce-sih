WITH raw_events AS (
    SELECT
        *
    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
),

unnested_items AS (
    SELECT
        ecommerce.transaction_id,
        items.item_id,
        items.item_name,
        items.price
    FROM
        raw_events,
        UNNEST(items) AS items
    WHERE event_name = 'purchase'
      AND ecommerce.transaction_id IS NOT NULL
)

SELECT * FROM unnested_items
