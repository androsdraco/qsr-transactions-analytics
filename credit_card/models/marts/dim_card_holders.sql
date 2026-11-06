{{ config(materialized='table') }}

with deduped as (
    select
        account_id,
        card_holder_city,
        card_holder_state,
        card_holder_msa,
        card_holder_postal_code,
        card_holder_postal_code_present,
        card_holder_latitude,
        card_holder_longitude,
        card_holder_generation,
        card_holder_personas,
        card_holder_vintage_years,
        lifetime_txn_count,
        lifetime_spend,
        avg_ltm_spend,
        avg_ltm_txn_count,
        transaction_date,
        row_number() over (
            partition by account_id
            order by transaction_date desc
        ) as rn
    from {{ ref('int_qsr__card_holders') }}
    where account_id is not null
)

select
    account_id,
    card_holder_city,
    card_holder_state,
    card_holder_msa,
    card_holder_postal_code,
    card_holder_postal_code_present,
    card_holder_latitude,
    card_holder_longitude,
    card_holder_generation,
    card_holder_personas,
    card_holder_vintage_years,
    lifetime_txn_count,
    lifetime_spend,
    avg_ltm_spend,
    avg_ltm_txn_count,
    current_timestamp()                         as _dim_built_at
from deduped
where rn = 1