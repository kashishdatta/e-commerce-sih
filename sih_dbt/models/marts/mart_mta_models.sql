WITH touchpoints AS (
    SELECT * FROM {{ ref('int_mta_touchpoints') }}
),

-- 1. Calculate the Fractional Credits
fractional_credits AS (
    SELECT
        transaction_id,
        channel,
        purchase_revenue,
        
        -- First Touch (100% to first)
        CASE WHEN touchpoint_rank = 1 THEN 1.0 ELSE 0.0 END AS first_touch_credit,
        
        -- Last Touch (100% to last)
        CASE WHEN touchpoint_rank = total_touchpoints THEN 1.0 ELSE 0.0 END AS last_touch_credit,
        
        -- Linear (Equal distribution)
        1.0 / NULLIF(total_touchpoints, 0) AS linear_credit,
        
        -- U-Shaped (40% first, 40% last, 20% middle)
        CASE 
            WHEN total_touchpoints = 1 THEN 1.0
            WHEN total_touchpoints = 2 THEN 0.5
            WHEN touchpoint_rank = 1 THEN 0.4
            WHEN touchpoint_rank = total_touchpoints THEN 0.4
            ELSE 0.2 / NULLIF((total_touchpoints - 2), 0)
        END AS ushaped_credit,
        
        -- Time Decay (Exponential factor: 2^(rank - total))
        CAST(POW(2.0, CAST(touchpoint_rank AS FLOAT64) - CAST(total_touchpoints AS FLOAT64)) AS FLOAT64) as raw_decay_weight

    FROM touchpoints
    WHERE total_touchpoints > 0
),

-- 2. Normalize Time Decay weights so they sum to 1.0 per transaction
normalized_decay AS (
    SELECT
        transaction_id,
        SUM(raw_decay_weight) as sum_decay_weight
    FROM fractional_credits
    GROUP BY 1
),

-- 3. Apply the Weights to Revenue
mta_allocated AS (
    SELECT 
        fc.channel,
        fc.transaction_id,
        fc.purchase_revenue * fc.first_touch_credit AS revenue_first_touch,
        fc.purchase_revenue * fc.last_touch_credit AS revenue_last_touch,
        fc.purchase_revenue * fc.linear_credit AS revenue_linear,
        fc.purchase_revenue * fc.ushaped_credit AS revenue_ushaped,
        fc.purchase_revenue * (fc.raw_decay_weight / NULLIF(nd.sum_decay_weight, 0)) AS revenue_time_decay
    FROM fractional_credits fc
    JOIN normalized_decay nd ON fc.transaction_id = nd.transaction_id
),

-- 4. Aggregate by Channel
mta_summary AS (
    SELECT
        channel,
        SUM(revenue_first_touch) as first_touch_revenue,
        SUM(revenue_last_touch) as last_touch_revenue,
        SUM(revenue_linear) as linear_revenue,
        SUM(revenue_ushaped) as ushaped_revenue,
        SUM(revenue_time_decay) as time_decay_revenue
    FROM mta_allocated
    GROUP BY 1
)

SELECT * FROM mta_summary
ORDER BY linear_revenue DESC
