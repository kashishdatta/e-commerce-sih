WITH sessions AS (
    SELECT * FROM {{ ref('int_sessions') }}
),

user_purchases AS (
    SELECT
        anonymous_id,
        custom_session_id,
        session_start_time,
        session_revenue,
        LAG(session_start_time) OVER (PARTITION BY anonymous_id ORDER BY session_start_time) as previous_purchase_time
    FROM sessions
    WHERE total_purchases > 0
),

purchase_intervals AS (
    SELECT
        anonymous_id,
        session_start_time,
        session_revenue,
        TIMESTAMP_DIFF(session_start_time, previous_purchase_time, DAY) as days_since_last_purchase
    FROM user_purchases
),

user_metrics AS (
    SELECT
        s.anonymous_id,
        MAX(s.session_start_time) as last_seen,
        COUNT(DISTINCT s.custom_session_id) as total_sessions,
        SUM(s.total_purchases) as lifetime_purchases,
        SUM(s.session_revenue) as lifetime_revenue,
        
        -- RFM Base Metrics
        TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(s.session_start_time), DAY) as recency_days,
        
        -- Churn Predictor Metrics (Inter-purchase time)
        AVG(pi.days_since_last_purchase) as avg_days_between_purchases,
        STDDEV(pi.days_since_last_purchase) as stddev_days_between_purchases
    FROM sessions s
    LEFT JOIN purchase_intervals pi ON s.anonymous_id = pi.anonymous_id
    GROUP BY 1
),

rfm_scoring AS (
    SELECT
        *,
        -- RFM Scoring (1 to 5, where 5 is best)
        NTILE(5) OVER (ORDER BY recency_days DESC) as r_score,
        NTILE(5) OVER (ORDER BY lifetime_purchases ASC) as f_score,
        NTILE(5) OVER (ORDER BY lifetime_revenue ASC) as m_score
    FROM user_metrics
    WHERE lifetime_purchases > 0
),

final_health AS (
    SELECT
        *,
        CONCAT(CAST(r_score AS STRING), CAST(f_score AS STRING), CAST(m_score AS STRING)) AS rfm_concat_score,
        CASE 
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score <= 2 AND (f_score >= 3 OR m_score >= 3) THEN 'At Risk'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'Recent Users'
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost Customers'
            ELSE 'Standard'
        END AS rfm_segment,
        
        -- High Probability Churn Flag: if their current gap is > 2 sigma from their mean
        CASE
            WHEN avg_days_between_purchases IS NOT NULL 
                 AND stddev_days_between_purchases IS NOT NULL 
                 AND stddev_days_between_purchases > 0
                 AND recency_days > (avg_days_between_purchases + (2 * stddev_days_between_purchases)) 
            THEN True
            ELSE False
        END AS is_high_churn_risk

    FROM rfm_scoring
)

SELECT * FROM final_health
