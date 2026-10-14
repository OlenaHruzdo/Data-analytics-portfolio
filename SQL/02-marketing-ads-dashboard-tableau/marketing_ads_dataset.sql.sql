-- ============================================================
-- 1. TEMPORARY FUNCTION: URL DECODING (exists only for the current session)
-- ============================================================

CREATE OR REPLACE FUNCTION pg_temp.decode_url_part(p varchar)
RETURNS varchar AS
$$
SELECT convert_from(
    CAST(
        E'\\x' ||
        string_agg(
            CASE
                WHEN length(r.m[1]) = 1
                    THEN encode(convert_to(r.m[1], 'SQL_ASCII'), 'hex')
                ELSE substring(r.m[1] FROM 2 FOR 2)
            END,
            ''
        ) AS bytea
    ),
    'UTF8'
)
FROM regexp_matches(
    replace($1, '+', ' '),
    '%[0-9a-f][0-9a-f]|.',
    'gi'
) AS r(m);
$$ LANGUAGE SQL IMMUTABLE STRICT;


-- ============================================================
-- 2. SINGLE ANALYTICAL DATASET FOR TABLEAU PUBLIC
-- ============================================================

WITH all_ads_data AS (

    -- Facebook: the joins replace technical IDs with readable names
    SELECT
        fabd.ad_date,
        fabd.url_parameters,
        'Facebook'::text AS source,
        -- Missing names get a readable label instead of NULL
        COALESCE(fc.campaign_name, 'Unknown campaign') AS campaign_name,
        COALESCE(fa.adset_name, 'Unknown adset')       AS adset_name,
        fabd.spend,
        fabd.impressions,
        fabd.reach,
        fabd.clicks,
        fabd.leads,
        fabd.value
    FROM public.facebook_ads_basic_daily AS fabd
    LEFT JOIN public.facebook_campaign AS fc
        ON fabd.campaign_id = fc.campaign_id
    LEFT JOIN public.facebook_adset AS fa
        ON fabd.adset_id = fa.adset_id
    -- Exclude completely empty rows from the source table
    WHERE fabd.ad_date IS NOT NULL

    UNION ALL

    -- Google: campaign and ad set names are already stored as text
    SELECT
        gad.ad_date,
        gad.url_parameters,
        'Google'::text AS source,
        COALESCE(gad.campaign_name, 'Unknown campaign') AS campaign_name,
        COALESCE(gad.adset_name, 'Unknown adset')       AS adset_name,
        gad.spend,
        gad.impressions,
        gad.reach,
        gad.clicks,
        gad.leads,
        gad.value
    FROM public.google_ads_basic_daily AS gad
    -- Same safeguard for Google
    WHERE gad.ad_date IS NOT NULL
),

-- ============================================================
-- 3. PRELIMINARY AGGREGATION BY RAW utm_campaign
--    (the regex is evaluated once, and decoding later runs on fewer rows)
-- ============================================================

raw_aggregated AS (
    SELECT
        ad_date,
        source,
        campaign_name,
        adset_name,

        -- (?:^|[?&]) prevents a false match such as "xutm_campaign="
        SUBSTRING(url_parameters FROM '(?:^|[?&])utm_campaign=([^&]*)') AS utm_campaign_raw,

        -- NULL metrics are treated as 0 before summing
        SUM(COALESCE(spend, 0))       AS total_spend,
        SUM(COALESCE(impressions, 0)) AS total_impressions,
        SUM(COALESCE(reach, 0))       AS total_reach,
        SUM(COALESCE(clicks, 0))      AS total_clicks,
        SUM(COALESCE(leads, 0))       AS total_leads,
        SUM(COALESCE(value, 0))       AS total_value
    FROM all_ads_data
    GROUP BY
        ad_date,
        source,
        campaign_name,
        adset_name,
        SUBSTRING(url_parameters FROM '(?:^|[?&])utm_campaign=([^&]*)')
),

-- ============================================================
-- 4. DECODE utm_campaign AND HANDLE INVALID VALUES
-- ============================================================

prepared_data AS (
    SELECT
        ad_date,
        source,
        campaign_name,
        adset_name,

        -- Return NULL if the value is missing, empty or 'nan';
        -- otherwise decode it first and convert it to lower case afterwards
        CASE
            WHEN utm_campaign_raw IS NULL
              OR LOWER(utm_campaign_raw) IN ('nan', '')
                THEN NULL
            ELSE LOWER(pg_temp.decode_url_part(utm_campaign_raw))
        END AS utm_campaign,

        total_spend,
        total_impressions,
        total_reach,
        total_clicks,
        total_leads,
        total_value
    FROM raw_aggregated
)

-- ============================================================
-- 5. FINAL AGGREGATION
--    (required because different raw values can decode to the same text,
--     e.g. %D0 vs %d0, or + vs %20)
-- ============================================================

SELECT
    ad_date,
    source,
    campaign_name,
    adset_name,
    utm_campaign,
    SUM(total_spend)       AS total_spend,
    SUM(total_impressions) AS total_impressions,
    SUM(total_reach)       AS total_reach,
    SUM(total_clicks)      AS total_clicks,
    SUM(total_leads)       AS total_leads,
    SUM(total_value)       AS total_value
FROM prepared_data
GROUP BY
    ad_date,
    source,
    campaign_name,
    adset_name,
    utm_campaign
ORDER BY
    ad_date,
    source,
    campaign_name,
    adset_name,
    utm_campaign;