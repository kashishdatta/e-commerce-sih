WITH daily_revenue AS (
    SELECT
        DATE(event_time) AS purchase_date,
        SUM(purchase_revenue) AS daily_revenue,
        COUNT(DISTINCT transaction_id) AS daily_orders
    FROM {{ ref('stg_ga4__events') }}
    WHERE event_name = 'purchase'
    GROUP BY 1
),

rolling_metrics AS (
    SELECT
        purchase_date,
        daily_revenue,
        daily_orders,
        AVG(daily_revenue) OVER (
            ORDER BY purchase_date 
            ROWS BETWEEN 14 PRECEDING AND CURRENT ROW
        ) AS rolling_14d_avg_revenue,
        
        STDDEV(daily_revenue) OVER (
            ORDER BY purchase_date 
            ROWS BETWEEN 14 PRECEDING AND CURRENT ROW
        ) AS rolling_14d_stddev_revenue
    FROM daily_revenue
),

anomaly_flags AS (
    SELECT
        purchase_date,
        daily_revenue,
        daily_orders,
        rolling_14d_avg_revenue,
        rolling_14d_stddev_revenue,
        
        -- Bollinger Bands
        rolling_14d_avg_revenue + (2 * COALESCE(rolling_14d_stddev_revenue, 0)) AS upper_band,
        GREATEST(0.0, rolling_14d_avg_revenue - (2 * COALESCE(rolling_14d_stddev_revenue, 0))) AS lower_band,
        
        -- Determine Anomalies
        CASE 
            WHEN daily_revenue > (rolling_14d_avg_revenue + (2 * COALESCE(rolling_14d_stddev_revenue, 0))) 
                 AND COALESCE(rolling_14d_stddev_revenue, 0) > 0 THEN 'Spike'
            WHEN daily_revenue < GREATEST(0.0, (rolling_14d_avg_revenue - (2 * COALESCE(rolling_14d_stddev_revenue, 0)))) 
                 AND COALESCE(rolling_14d_stddev_revenue, 0) > 0 THEN 'Drop'
            ELSE 'Normal'
        END AS anomaly_flag
        
    FROM rolling_metrics
)

SELECT * FROM anomaly_flags
ORDER BY purchase_date DESC
