{{ config(materialized='table') }}

with daily as (
    select
        date_day,
        card_class,
        is_anonymous_card,
        count(*)                          as txn_count,
        count(distinct account_id)        as distinct_consumers,
        sum(gross_transaction_amount)     as total_spend,
        avg(gross_transaction_amount)     as avg_ticket
    from {{ ref('fct_qsr_transactions') }}
    group by 1, 2, 3
)

select
    date_day,
    card_class,
    is_anonymous_card,
    txn_count,
    distinct_consumers,
    total_spend,
    avg_ticket,
    current_timestamp() as _mart_built_at
from daily