/* Task 1 — Cohort table preparation (PostgreSQL / DBeaver)
   Schema: project

   Goal:
   Prepare a cohort summary table showing the number of unique active
   users grouped by signup cohort (month), month_offset (user tenure),
   and promo status. The analysis is based on six months of raw signup
   and event data.

   As both source tables store dates as free-text strings in inconsistent
   formats, an essential part of the task is to clean, parse and
   standardise signup_datetime and event_datetime before performing the
   cohort analysis.

   The resulting table will be exported to Google Sheets to create a
   triangular cohort table and calculate the retention rate.

   Query structure (three CTEs plus one final SELECT block):
   - users_parsed  : cleans signup_datetime and converts it to signup_ts;
   - events_parsed : cleans event_datetime and converts it to event_ts;
   - user_activity : joins both datasets, derives cohort_month,
                     activity_month and month_offset, and applies the
                     required filters;
   - final SELECT  : aggregates the number of unique users by promo
                     status, cohort month and month_offset.
 */
 
/* Step 1. users — clean signup_datetime and convert it to a timestamp.
 
   Logic (implemented using nested subqueries within a single CTE)::
   a) Trim the string and keep only the date part (remove the time part);
   b) Standardise all data delimiters (. / -) into a single delimiter (-) with regexp_replace();
   c) Split the date into day, month and year using split_part();
   d) Normalise digit counts: pad day/month to 2 digits, expand a
      2-digit year to 4 digits (assuming the 2000s);
   e) Validate the normalised parts with a regex/range check, then
      convert with to_timestamp(); anything invalid becomes null.
*/
WITH users_parsed AS (
    SELECT
        u.user_id,
        u.promo_signup_flag,
        CASE
            -- four-digit year, e.g. 05-02-2025
            WHEN date_clean ~ '^\d{1,2}-\d{1,2}-\d{4}$'
             AND split_part(date_clean, '-', 1)::int BETWEEN 1 AND 31
             AND split_part(date_clean, '-', 2)::int BETWEEN 1 AND 12
                THEN to_timestamp(date_clean, 'dd-mm-yyyy')
            -- two-digit year, e.g. 5-2-25
            WHEN date_clean ~ '^\d{1,2}-\d{1,2}-\d{2}$'
             AND split_part(date_clean, '-', 1)::int BETWEEN 1 AND 31
             AND split_part(date_clean, '-', 2)::int BETWEEN 1 AND 12
                THEN to_timestamp(date_clean, 'dd-mm-yy')
            ELSE NULL
        END AS signup_ts
    FROM (
        -- strip whitespace, drop the time part, unify delimiters — computed once
        SELECT
            u.user_id,
            u.promo_signup_flag,
            regexp_replace(
                split_part(trim(u.signup_datetime), ' ', 1),
                '[./]', '-', 'g'
            ) AS date_clean
        FROM project.cohort_users_raw u
    ) u
),
 
/* Step 2. Events — clean event_datetime and convert it to a timestamp.
 
   Apply the same logic as in Step 1 to cohort_events_raw.
   A NULL or empty event_datetime naturally fails the validation check
   below and becomes NULL, so it is correctly excluded by the filter
   in Step 3.
 */
events_parsed AS (
    SELECT
        e.user_id,
        e.event_type,
        CASE
            -- four-digit year, e.g. 15-03-2025
            WHEN date_clean ~ '^\d{1,2}-\d{1,2}-\d{4}$'
             AND split_part(date_clean, '-', 1)::int BETWEEN 1 AND 31
             AND split_part(date_clean, '-', 2)::int BETWEEN 1 AND 12
                THEN to_timestamp(date_clean, 'dd-mm-yyyy')
            -- two-digit year, e.g. 15-3-25
            WHEN date_clean ~ '^\d{1,2}-\d{1,2}-\d{2}$'
             AND split_part(date_clean, '-', 1)::int BETWEEN 1 AND 31
             AND split_part(date_clean, '-', 2)::int BETWEEN 1 AND 12
                THEN to_timestamp(date_clean, 'dd-mm-yy')
            ELSE NULL
        END AS event_ts
    FROM (
        -- strip whitespace, drop the time part, unify delimiters — computed once
        SELECT
            e.user_id,
            e.event_type,
            regexp_replace(
                split_part(trim(e.event_datetime), ' ', 1),
                '[./]', '-', 'g'
            ) AS date_clean
        FROM project.cohort_events_raw e
    ) e
),
 

/* Step 3. Join users and events, then derive cohort_month,
   activity_month and month_offset (the user's tenure in months).
 
   - cohort_month   : registration month, truncated to the first day
   - activity_month : event month, truncated to the first day
   - month_offset   : total number of full calendar months between the
                   registration and event months, calculated as
                   (years × 12 + months) from age(). This approach
                   correctly handles periods longer than one year.
                   Registration itself corresponds to month_offset = 0.
                   
   The filter removes records that should not be included in the
   cohort analysis:
   - users with a missing or unparsable signup date
   - events with a missing or unparsable event date
   - events with a missing event_type
   - test events (event_type = 'test_event')
 
   The 'registration' event type is intentionally retained, since it
   represents the month_offset = 0 activity for each user.
 */
user_activity AS (
    SELECT
        u.user_id,
        u.promo_signup_flag,
        date_trunc('month', u.signup_ts)::date AS cohort_month,
        date_trunc('month', e.event_ts)::date  AS activity_month,
        (
            extract(year FROM age(
                date_trunc('month', e.event_ts),
                date_trunc('month', u.signup_ts)
            )) * 12
            + extract(month FROM age(
                date_trunc('month', e.event_ts),
                date_trunc('month', u.signup_ts)
            ))
        )::int AS month_offset
    FROM users_parsed  u
    JOIN events_parsed e
        ON u.user_id = e.user_id
    WHERE
        u.signup_ts   IS NOT NULL
        AND e.event_ts   IS NOT NULL
        AND e.event_type IS NOT NULL
        AND e.event_type <> 'test_event'
)
 

/* Step 4. Build the final cohort summary table.
 
   month_offset between 0 and 5 is intentionally not filtered here,
   since it is an expected outcome of the observation window below,
   rather than a condition to enforce directly. The result is sorted by promo status, then by cohort month, and
   finally by month_offset, as required.
 */
SELECT
    promo_signup_flag,
    cohort_month,
    month_offset,
    count(DISTINCT user_id) AS users_total
FROM user_activity
-- Observation window: January-June 2025.
WHERE activity_month BETWEEN date '2025-01-01' AND date '2025-06-01'
GROUP BY
    promo_signup_flag,
    cohort_month,
    month_offset
ORDER BY
    promo_signup_flag,
    cohort_month,
    month_offset;