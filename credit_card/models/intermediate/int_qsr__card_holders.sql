{{ config(materialized='table') }}

with source as (
    select * from {{ ref('stg_marketplace__qsr_transactions') }}
),

cleaned as (
    select
        transaction_id,
        transaction_date,
        account_id,
        upper(trim(card_holder_city))          as card_holder_city,
        upper(trim(card_holder_state))         as card_holder_state,
        upper(trim(card_holder_msa))           as card_holder_msa,
        upper(trim(card_holder_postal_code))   as card_holder_postal_code,
        upper(trim(card_holder_postal_code_present)) as card_holder_postal_code_present,
        try_to_number(card_holder_latitude,  10, 6)  as card_holder_latitude,
        try_to_number(card_holder_longitude, 10, 6)  as card_holder_longitude,
        upper(trim(card_holder_generation))    as card_holder_generation,
        upper(trim(card_holder_personas))      as card_holder_personas,
        cast(card_holder_vintage as number(10,0)) as card_holder_vintage_years,
        cast(card_holder_total_transaction_count          as number(18,0)) as lifetime_txn_count,
        cast(card_holder_total_spend                      as number(18,2)) as lifetime_spend,
        cast(card_holder_average_ltm_spend                as number(18,2)) as avg_ltm_spend,
        cast(card_holder_average_ltm_transaction_count    as number(18,2)) as avg_ltm_txn_count
    from source
    where transaction_id is not null
)

select * from cleaned