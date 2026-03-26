WITH purchases AS (
    SELECT 
        COALESCE(su.stitched_user_id, e.anonymous_id) as global_user_id,
        e.purchase_revenue,
        DATE_TRUNC(DATE(e.event_time), MONTH) as purchase_month
    FROM {{ ref('stg_ga4__events') }} e
    LEFT JOIN {{ ref('int_user_stitching') }} su ON e.anonymous_id = su.anonymous_id
    WHERE e.event_name = 'purchase'
),

cohorts AS (
    SELECT * FROM {{ ref('int_user_first_purchase') }}
),

cohort_sizes AS (
    SELECT 
        cohort_month, 
        COUNT(DISTINCT global_user_id) as cohort_size 
    FROM cohorts
    GROUP BY 1
),

cohort_monthly_revenue AS (
    SELECT
        c.cohort_month,
        DATE_DIFF(p.purchase_month, c.cohort_month, MONTH) as month_index,
        SUM(p.purchase_revenue) as month_revenue,
        COUNT(DISTINCT p.global_user_id) as active_purchasers
    FROM purchases p
    JOIN cohorts c ON p.global_user_id = c.global_user_id
    GROUP BY 1, 2
),

cohort_cumulative AS (
    SELECT
        r.cohort_month,
        r.month_index,
        s.cohort_size,
        r.active_purchasers,
        r.month_revenue,
        -- Cumulative sum of revenue for this cohort up to this month index
        SUM(r.month_revenue) OVER (
            PARTITION BY r.cohort_month 
            ORDER BY r.month_index 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) as cumulative_revenue
    FROM cohort_monthly_revenue r
    JOIN cohort_sizes s ON r.cohort_month = s.cohort_month
)

SELECT
    cohort_month,
    cohort_size,
    month_index,
    active_purchasers,
    month_revenue,
    cumulative_revenue,
    -- Calculate CLV per user in the cohort (cumulative revenue / initial cohort size)
    CAST(cumulative_revenue AS FLOAT64) / NULLIF(cohort_size, 0) as cumulative_clv
FROM cohort_cumulative
ORDER BY 1, 3
