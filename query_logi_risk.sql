with base as (
    SELECT
        sum(ems_std_fee - round(fee::numeric,0)) as total_savings,
        count(*) as total_cnt
    from pj_logistics_2023.logi_raw_23
    where kpi_status like '%정상%'
),
provider_contrib as (
    SELECT
        provider,
        count(*) as cnt,
        sum(ems_std_fee - round(fee::numeric,0)) as savings,
        ROUND(AVG(ems_std_fee - ROUND(fee::numeric, 0)) / nullif(avg(apply_wgt),0)::numeric,0) as eff_per_kg
    from pj_logistics_2023.logi_raw_23
    where kpi_status like '%정상%'   
    group by 1
),
risk_calc as (
    SELECT
        p.provider,
        p.cnt as shipment_cnt,
        p.savings as provider_savings,
        b.total_savings as total_savings,
        round(p.savings *100.0 / nullif(b.total_savings,0),2) as savings_share_pct,
        (b.total_savings - p.savings) as remaining_savings,
        round(p.savings*100.0/nullif(b.total_savings,0),2) as impact_index_pct,
        round(p.cnt*100.0/nullif(b.total_cnt,0),2) as shipment_gap_pct,
        p.eff_per_kg as eff_per_kg
    from provider_contrib p
    cross join base b              
)
SELECT
    case
        WHEN impact_index_pct >= 30 THEN 'Critical'
        WHEN impact_index_pct >= 15 THEN 'High'
        WHEN impact_index_pct >= 5  THEN 'Medium'
        ELSE                             'Low'
    END as risk_grade,
    provider,
    shipment_cnt,
    provider_savings,
    savings_share_pct,
    remaining_savings,
    impact_index_pct,
    shipment_gap_pct,
    eff_per_kg
from risk_calc
order by impact_index_pct desc;
