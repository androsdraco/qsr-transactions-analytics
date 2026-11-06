{{ config(materialized='table') }}

with date_spine as (
    select dateadd(day, seq4(), '2023-01-01'::date)::date as date_day
    from table(generator(rowcount => 1461))  -- 4 years = 2023-01-01 to 2026-12-31
),

final as (
    select
        date_day,
        year(date_day)                              as year,
        quarter(date_day)                           as quarter,
        month(date_day)                             as month,
        monthname(date_day)                         as month_name,
        weekofyear(date_day)                        as week_of_year,
        dayofweek(date_day)                         as day_of_week_num,   -- 0=Sun .. 6=Sat
        dayname(date_day)                           as day_of_week_name,
        day(date_day)                               as day_of_month,
        dayofyear(date_day)                         as day_of_year,
        -- weekend flag
        case when dayofweek(date_day) in (0, 6) then true else false end as is_weekend,
        -- fiscal-style helpers
        date_trunc('month', date_day)::date         as first_day_of_month,
        last_day(date_day, 'month')                 as last_day_of_month,
        date_trunc('quarter', date_day)::date       as first_day_of_quarter,
        date_trunc('year', date_day)::date          as first_day_of_year
    from date_spine
)

select * from final