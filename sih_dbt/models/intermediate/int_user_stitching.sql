WITH events AS (
    SELECT * FROM {{ ref('stg_ga4__events') }}
),

-- Find the first time a user logged in, mapping anonymous_id to user_id
user_id_mapping AS (
    SELECT DISTINCT
        anonymous_id,
        user_id,
        MIN(event_time) OVER (PARTITION BY anonymous_id, user_id) as first_login_time
    FROM events
    WHERE user_id IS NOT NULL
),

-- In case an anonymous_id has multiple user_ids, get the earliest one
stitched_users AS (
    SELECT
        anonymous_id,
        user_id as stitched_user_id
    FROM user_id_mapping
    QUALIFY ROW_NUMBER() OVER (PARTITION BY anonymous_id ORDER BY first_login_time ASC) = 1
)

SELECT * FROM stitched_users
