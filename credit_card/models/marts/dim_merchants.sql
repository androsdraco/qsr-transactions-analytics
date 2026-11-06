{{ config(materialized='table') }}

with deduped as (
    select
        merchant_id,
        merchant_name,
        merchant_city,
        merchant_state,
        merchant_msa,
        merchant_postal_code,
        merchant_latitude,
        merchant_longitude,
        merchant_store_id,
        merchant_store_location,
        merchant_store_address,
        mcc_code,
        top_mcc_code,
        merchant_category_level_1,
        merchant_category_level_2,
        merchant_category_level_3,
        transaction_date,
        row_number() over (
            partition by merchant_id
            order by transaction_date desc
        ) as rn
    from {{ ref('int_qsr__merchants') }}
    where merchant_id is not null
)

select
    merchant_id,
    merchant_name,
    merchant_city,
    merchant_state,
    merchant_msa,
    merchant_postal_code,
    merchant_latitude,
    merchant_longitude,
    merchant_store_id,
    merchant_store_location,
    merchant_store_address,
    mcc_code,
    top_mcc_code,
    merchant_category_level_1,
    merchant_category_level_2,
    merchant_category_level_3,
    case
        when merchant_id = 0 then false
        when merchant_name = 'NO ENTITY' then false
        else true
    end                                         as is_known_merchant,
    current_timestamp()                         as _dim_built_at
from deduped
where rn = 1