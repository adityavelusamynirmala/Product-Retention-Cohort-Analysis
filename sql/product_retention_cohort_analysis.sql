/*
Project: Product Retention & Cohort Analysis
Database: SQLite
Source files: data/users_raw.csv and data/user_events_raw.csv

Import the two CSV files into SQLite as tables named:
  users_raw
  user_events_raw

This script creates deduplicated/standardized views and example analysis queries.
The cohort definition uses cohort_month supplied in users_raw. It does not infer
signup cohorts from signup_date because the supplied cohort_month is the
consistent cohort field used by the Power BI report.
*/

DROP VIEW IF EXISTS user_events_clean;
DROP VIEW IF EXISTS users_clean;

CREATE VIEW users_clean AS
WITH ranked_users AS (
    SELECT
        TRIM(user_id) AS user_id,
        NULLIF(TRIM(signup_date), '') AS signup_date,
        NULLIF(TRIM(cohort_month), '') AS cohort_month,
        CASE
            WHEN LOWER(TRIM(acquisition_channel)) IN ('organic','paid','referral','social')
                THEN CASE LOWER(TRIM(acquisition_channel))
                    WHEN 'organic' THEN 'Organic'
                    WHEN 'paid' THEN 'Paid'
                    WHEN 'referral' THEN 'Referral'
                    WHEN 'social' THEN 'Social'
                END
            ELSE 'Unknown'
        END AS acquisition_channel,
        CASE
            WHEN LOWER(TRIM(platform)) IN ('ios','iOS') THEN 'iOS'
            WHEN LOWER(TRIM(platform)) = 'android' THEN 'Android'
            WHEN LOWER(TRIM(platform)) = 'web' THEN 'Web'
            ELSE 'Unknown'
        END AS platform,
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(user_id)
            ORDER BY
                CASE WHEN NULLIF(TRIM(cohort_month), '') IS NULL THEN 1 ELSE 0 END,
                cohort_month,
                signup_date
        ) AS rn
    FROM users_raw
    WHERE NULLIF(TRIM(user_id), '') IS NOT NULL
)
SELECT user_id, signup_date, cohort_month, acquisition_channel, platform
FROM ranked_users
WHERE rn = 1;

CREATE VIEW user_events_clean AS
WITH ranked_events AS (
    SELECT
        TRIM(e.event_id) AS event_id,
        TRIM(e.user_id) AS user_id,
        TRIM(e.event_timestamp) AS event_timestamp,
        TRIM(e.event_name) AS event_name,
        u.acquisition_channel,
        u.platform,
        DATE(SUBSTR(TRIM(e.event_timestamp), 1, 10)) AS event_date,
        STRFTIME('%Y-%m', DATE(SUBSTR(TRIM(e.event_timestamp), 1, 10))) AS activity_month,
        u.signup_date,
        u.cohort_month,
        CASE
            WHEN u.cohort_month GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]'
             AND STRFTIME('%Y-%m', DATE(SUBSTR(TRIM(e.event_timestamp), 1, 10))) IS NOT NULL
            THEN
                (
                    CAST(SUBSTR(STRFTIME('%Y-%m', DATE(SUBSTR(TRIM(e.event_timestamp), 1, 10))), 1, 4) AS INTEGER)
                    - CAST(SUBSTR(u.cohort_month, 1, 4) AS INTEGER)
                ) * 12
                +
                (
                    CAST(SUBSTR(STRFTIME('%Y-%m', DATE(SUBSTR(TRIM(e.event_timestamp), 1, 10))), 6, 2) AS INTEGER)
                    - CAST(SUBSTR(u.cohort_month, 6, 2) AS INTEGER)
                )
            ELSE NULL
        END AS months_since_signup,
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(e.event_id)
            ORDER BY TRIM(e.event_timestamp)
        ) AS rn
    FROM user_events_raw e
    LEFT JOIN users_clean u
        ON TRIM(e.user_id) = u.user_id
    WHERE NULLIF(TRIM(e.event_id), '') IS NOT NULL
      AND NULLIF(TRIM(e.event_timestamp), '') IS NOT NULL
)
SELECT
    event_id, user_id, event_timestamp, event_name,
    acquisition_channel, platform, event_date, activity_month,
    signup_date, cohort_month, months_since_signup
FROM ranked_events
WHERE rn = 1;

-- 1. Executive KPIs
SELECT
    (SELECT COUNT(DISTINCT user_id) FROM users_clean) AS total_users,
    (SELECT COUNT(DISTINCT user_id) FROM user_events_clean) AS distinct_active_users,
    (SELECT COUNT(*) FROM user_events_clean) AS total_events;

-- 2. Monthly active users (distinct users with at least one event in the month)
SELECT
    activity_month,
    COUNT(DISTINCT user_id) AS monthly_active_users
FROM user_events_clean
WHERE activity_month IS NOT NULL
GROUP BY activity_month
ORDER BY activity_month;

-- 3. Repeat activity rate:
-- Users active in at least two distinct calendar months divided by users
-- who had at least one event in the observed period.
WITH user_month_counts AS (
    SELECT user_id, COUNT(DISTINCT activity_month) AS active_months
    FROM user_events_clean
    WHERE activity_month IS NOT NULL
    GROUP BY user_id
)
SELECT
    SUM(CASE WHEN active_months >= 2 THEN 1 ELSE 0 END) * 1.0
        / NULLIF(COUNT(*), 0) AS repeat_activity_rate
FROM user_month_counts;

-- 4. Cohort size
SELECT
    cohort_month,
    COUNT(DISTINCT user_id) AS cohort_size
FROM users_clean
WHERE cohort_month IS NOT NULL
GROUP BY cohort_month
ORDER BY cohort_month;

-- 5. Cohort retention by months since signup
-- Retained users are distinct cohort members with at least one event
-- in the relevant relative month.
WITH cohort_sizes AS (
    SELECT cohort_month, COUNT(DISTINCT user_id) AS cohort_size
    FROM users_clean
    WHERE cohort_month IS NOT NULL
    GROUP BY cohort_month
),
cohort_activity AS (
    SELECT
        cohort_month,
        months_since_signup,
        COUNT(DISTINCT user_id) AS active_users
    FROM user_events_clean
    WHERE months_since_signup BETWEEN 0 AND 11
    GROUP BY cohort_month, months_since_signup
)
SELECT
    a.cohort_month,
    a.months_since_signup,
    s.cohort_size,
    a.active_users,
    a.active_users * 1.0 / NULLIF(s.cohort_size, 0) AS retention_rate
FROM cohort_activity a
JOIN cohort_sizes s USING (cohort_month)
ORDER BY a.cohort_month, a.months_since_signup;

-- 6. Month 1 retention by acquisition channel
WITH cohort_sizes AS (
    SELECT
        acquisition_channel,
        cohort_month,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM users_clean
    GROUP BY acquisition_channel, cohort_month
),
month_one_activity AS (
    SELECT
        acquisition_channel,
        cohort_month,
        COUNT(DISTINCT user_id) AS active_users
    FROM user_events_clean
    WHERE months_since_signup = 1
    GROUP BY acquisition_channel, cohort_month
)
SELECT
    s.acquisition_channel,
    SUM(COALESCE(a.active_users, 0)) * 1.0
        / NULLIF(SUM(s.cohort_size), 0) AS month_1_retention_rate
FROM cohort_sizes s
LEFT JOIN month_one_activity a
    ON a.acquisition_channel = s.acquisition_channel
   AND a.cohort_month = s.cohort_month
GROUP BY s.acquisition_channel
ORDER BY month_1_retention_rate DESC;

-- 7. Month 1 retention by platform
WITH cohort_sizes AS (
    SELECT
        platform,
        cohort_month,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM users_clean
    GROUP BY platform, cohort_month
),
month_one_activity AS (
    SELECT
        platform,
        cohort_month,
        COUNT(DISTINCT user_id) AS active_users
    FROM user_events_clean
    WHERE months_since_signup = 1
    GROUP BY platform, cohort_month
)
SELECT
    s.platform,
    SUM(COALESCE(a.active_users, 0)) * 1.0
        / NULLIF(SUM(s.cohort_size), 0) AS month_1_retention_rate
FROM cohort_sizes s
LEFT JOIN month_one_activity a
    ON a.platform = s.platform
   AND a.cohort_month = s.cohort_month
GROUP BY s.platform
ORDER BY month_1_retention_rate DESC;
