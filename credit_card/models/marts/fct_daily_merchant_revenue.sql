{{ config(materialized='table') }}

with daily as (
    select
        date_day,
        merchant_id,
        count(*)                                                  as total_txn_count,
        count_if(not is_anonymous_card)                           as consumer_txn_count,
        count_if(is_anonymous_card)                               as anonymous_txn_count,
        sum(gross_transaction_amount)                             as total_spend,
        sum(case when is_anonymous_card then 0
                 else gross_transaction_amount end)               as consumer_spend,
        sum(case when is_anonymous_card then gross_transaction_amount
                 else 0 end)                                      as anonymous_spend,
        avg(gross_transaction_amount)                             as avg_ticket,
        count(distinct account_id)                                as distinct_consumers
    from {{ ref('fct_qsr_transactions') }}
    where merchant_id != 0   -- exclude unknown-merchant bucket from this mart
    group by 1, 2
)

select
    date_day,
    merchant_id,
    total_txn_count,
    consumer_txn_count,
    anonymous_txn_count,
    total_spend,
    consumer_spend,
    anonymous_spend,
    avg_ticket,
    distinct_consumers,
    current_timestamp()                 as _mart_built_at
from daily