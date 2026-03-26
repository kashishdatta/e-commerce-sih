WITH purchases AS (
    SELECT 
        COALESCE(su.stitched_user_id, e.anonymous_id) as global_user_id,
        e.transaction_id,
        e.purchase_revenue,
        e.event_time as purchase_time
    FROM {{ ref('stg_ga4__events') }} e
    LEFT JOIN {{ ref('int_user_stitching') }} su ON e.anonymous_id = su.anonymous_id
    WHERE e.event_name = 'purchase'
),

user_first_purchase AS (
    SELECT 
        global_user_id,
        MIN(purchase_time) as first_purchase_time,
        DATE_TRUNC(DATE(MIN(purchase_time)), MONTH) as cohort_month
    FROM purchases
    GROUP BY 1
)

SELECT * FROM user_first_purchase
