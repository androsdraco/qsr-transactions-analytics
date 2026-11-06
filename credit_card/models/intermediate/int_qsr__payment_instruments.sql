{{ config(materialized='table') }}

with source as (
    select * from {{ ref('stg_marketplace__qsr_transactions') }}
),

cleaned as (
    select
        transaction_id,
        transaction_date,
        payment_id,
        upper(trim(payment_name))       as payment_name,
        upper(trim(card_type))          as card_type,
        case
            when upper(trim(card_present_indicator)) in ('Y','YES','TRUE','1') then true
            when upper(trim(card_present_indicator)) in ('N','NO','FALSE','0')  then false
        end                             as is_card_present,
        case
            when consistent_shopper = 1 then true
            when consistent_shopper = 0 then false
        end                             as is_consistent_shopper
    from source
    where transaction_id is not null
)

select * from cleaned