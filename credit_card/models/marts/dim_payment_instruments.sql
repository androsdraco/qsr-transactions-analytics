{{ config(materialized='table') }}

with deduped as (
    select
        payment_id,
        payment_name,
        card_type,
        is_card_present,
        is_consistent_shopper,
        transaction_date,
        row_number() over (
            partition by payment_id
            order by transaction_date desc
        ) as rn
    from {{ ref('int_qsr__payment_instruments') }}
)

select
    payment_id,
    payment_name,
    card_type,
    is_card_present,
    is_consistent_shopper,
    case
        when payment_id = 0 then 'Not Integrated'
        else 'Integrated'
    end                                         as integration_status,
    current_timestamp()                         as _dim_built_at
from deduped
where rn = 1