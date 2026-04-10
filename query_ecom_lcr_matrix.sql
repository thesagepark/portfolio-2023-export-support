with sales_agg as (
    SELECT
        provider,
        to_ctry,
        sum(price_kr) as total_sales,
        count(DISTINCT biz_no) as brand_cnt
    from pj_logistics_2023.ecom_sales_23
    where provider not in ('이커머스사E')
    GROUP by 1,2
),
logi_agg AS (
    SELECT
        provider,
        to_ctry,
        SUM(CASE WHEN fee > 0 and fee <= ems_fee then fee else 0 end) AS total_fee,
        COUNT(*) AS ship_cnt
    FROM pj_logistics_2023.ecom_raw_23
    WHERE provider <> '이커머스사E'
    GROUP BY 1, 2
    HAVING COUNT(case when fee >0 and fee <= ems_fee then 1 end) >= 10
),
combined_raw AS (
    SELECT
        s.provider, s.to_ctry, s.brand_cnt, s.total_sales,
        l.total_fee, l.ship_cnt,
        ROUND(l.total_fee * 100.0 / NULLIF(s.total_sales, 0), 2) AS lcr
    FROM sales_agg s
    INNER JOIN logi_agg l ON s.provider = l.provider AND s.to_ctry = l.to_ctry
    WHERE s.total_sales > 0
),
combined AS (
    SELECT *,
        ROUND(SUM(total_fee) OVER() * 100.0 
              / NULLIF(SUM(total_sales) OVER(), 0), 2) AS avg_lcr,
        ROUND(AVG(total_sales) OVER(), 0) AS avg_sales
    FROM combined_raw
)
SELECT
    CASE
        WHEN lcr <= avg_lcr AND total_sales >= avg_sales THEN '핵심집중'
        WHEN lcr <= avg_lcr AND total_sales <  avg_sales THEN '육성후보'
        WHEN lcr >  avg_lcr AND total_sales >= avg_sales THEN '효율개선'
        ELSE '재검토'
    END AS segment,
    provider, to_ctry, brand_cnt, total_sales, total_fee, lcr, avg_lcr
from combined
order by segment, total_sales desc;
