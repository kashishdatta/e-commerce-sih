WITH stitched_users AS (
    SELECT * FROM {{ ref('int_user_stitching') }}
),

sessions AS (
    SELECT * FROM {{ ref('int_sessions') }}
),

-- Determine the first cohort month for each user
user_cohorts AS (
    SELECT
        su.stitched_user_id,
        DATE_TRUNC(DATE(MIN(s.session_start_time)), MONTH) as cohort_month
    FROM stitched_users su
    JOIN sessions s ON su.anonymous_id = s.anonymous_id
    GROUP BY 1
),

-- Determine all active months for each user
user_activities AS (
    SELECT
        su.stitched_user_id,
        DATE_TRUNC(DATE(s.session_start_time), MONTH) as activity_month
    FROM stitched_users su
    JOIN sessions s ON su.anonymous_id = s.anonymous_id
    GROUP BY 1, 2
),

-- Count total users in each cohort
cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT stitched_user_id) as total_users
    FROM user_cohorts
    GROUP BY 1
),

-- Calculate active users per cohort per month
retention_data AS (
    SELECT
        uc.cohort_month,
        DATE_DIFF(ua.activity_month, uc.cohort_month, MONTH) as month_number,
        COUNT(DISTINCT ua.stitched_user_id) as active_users
    FROM user_cohorts uc
    LEFT JOIN user_activities ua ON uc.stitched_user_id = ua.stitched_user_id
    GROUP BY 1, 2
)

SELECT
    r.cohort_month,
    cs.total_users as cohort_size,
    r.month_number,
    r.active_users,
    CAST(r.active_users AS FLOAT64) / NULLIF(cs.total_users, 0) as retention_rate
FROM retention_data r
JOIN cohort_size cs ON r.cohort_month = cs.cohort_month
ORDER BY 1, 3
