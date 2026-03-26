WITH transaction_items AS (
    SELECT DISTINCT
        transaction_id,
        item_name
    FROM {{ ref('stg_ga4__items') }}
    WHERE item_name IS NOT NULL
),

item_pairs AS (
    SELECT
        a.transaction_id,
        a.item_name AS item_a,
        b.item_name AS item_b
    FROM transaction_items a
    JOIN transaction_items b
      ON a.transaction_id = b.transaction_id
     AND a.item_name < b.item_name
)

SELECT * FROM item_pairs
