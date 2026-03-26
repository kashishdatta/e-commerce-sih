WITH pairs AS (
    SELECT * FROM {{ ref('int_item_pairs') }}
),

total_transactions AS (
    SELECT COUNT(DISTINCT transaction_id) AS total_txn 
    FROM {{ ref('stg_ga4__items') }}
),

item_frequencies AS (
    SELECT
        item_name,
        COUNT(DISTINCT transaction_id) AS item_txn_count
    FROM {{ ref('stg_ga4__items') }}
    GROUP BY 1
),

pair_frequencies AS (
    SELECT
        item_a,
        item_b,
        COUNT(DISTINCT transaction_id) AS pair_txn_count
    FROM pairs
    GROUP BY 1, 2
),

market_basket_metrics AS (
    SELECT
        pf.item_a,
        pf.item_b,
        pf.pair_txn_count,
        ifa.item_txn_count as item_a_txn_count,
        ifb.item_txn_count as item_b_txn_count,
        
        -- Support(A, B) = P(A & B) = pair matches / total txns
        CAST(pf.pair_txn_count AS FLOAT64) / NULLIF(tt.total_txn, 0) AS support,
        
        -- Confidence(A -> B) = P(B | A) = pair matches / item A matches
        CAST(pf.pair_txn_count AS FLOAT64) / NULLIF(ifa.item_txn_count, 0) AS confidence_a_to_b,
        
        -- Confidence(B -> A) = P(A | B) = pair matches / item B matches
        CAST(pf.pair_txn_count AS FLOAT64) / NULLIF(ifb.item_txn_count, 0) AS confidence_b_to_a,
        
        -- Lift(A, B) = Confidence(A -> B) / P(B) = P(A & B) / (P(A) * P(B))
        (CAST(pf.pair_txn_count AS FLOAT64) / NULLIF(tt.total_txn, 0)) / 
        NULLIF(
            (CAST(ifa.item_txn_count AS FLOAT64) / NULLIF(tt.total_txn, 0)) * 
            (CAST(ifb.item_txn_count AS FLOAT64) / NULLIF(tt.total_txn, 0)), 0
        ) AS lift

    FROM pair_frequencies pf
    CROSS JOIN total_transactions tt
    JOIN item_frequencies ifa ON pf.item_a = ifa.item_name
    JOIN item_frequencies ifb ON pf.item_b = ifb.item_name
)

SELECT * FROM market_basket_metrics
-- Filter out pairs that are statistically insignificant
WHERE lift > 1.0 
  AND pair_txn_count >= 5
ORDER BY lift DESC
