{{ config(materialized='table') }}

with source as (
    select * from {{ ref('stg_marketplace__qsr_transactions') }}
),

cleaned as (
    select
        transaction_id,
        transaction_date,
        merchant_id,
        upper(trim(merchant_name))                as merchant_name,
        upper(trim(merchant_city))                as merchant_city,
        upper(trim(merchant_state))               as merchant_state,
        upper(trim(merchant_msa))                 as merchant_msa,
        upper(trim(merchant_postal_code))         as merchant_postal_code,
        try_to_number(merchant_latitude,  10, 6)  as merchant_latitude,
        try_to_number(merchant_longitude, 10, 6)  as merchant_longitude,
        merchant_store_id,
        upper(trim(merchant_store_location))      as merchant_store_location,
        upper(trim(merchant_store_address))       as merchant_store_address,
        merchant_category_code                    as mcc_code,
        top_merchant_category_code                as top_mcc_code,
        upper(trim(merchant_category_level_1))    as merchant_category_level_1,
        upper(trim(merchant_category_level_2))    as merchant_category_level_2,
        upper(trim(merchant_category_level_3))    as merchant_category_level_3
    from source
    where transaction_id is not null
)

select * from cleaned