{{ config(materialized='table') }}

with source as (
    select * from {{ ref('stg_marketplace__qsr_transactions') }}
),

cleaned as (
    select
        transaction_id,
        upper(trim(transaction_city))         as transaction_city,
        upper(trim(transaction_msa))          as transaction_msa,
        upper(trim(transaction_postal_code))  as transaction_postal_code,
        try_to_number(transaction_latitude,  10, 6) as transaction_latitude,
        try_to_number(transaction_longitude, 10, 6) as transaction_longitude
    from source
    where transaction_id is not null
)

select * from cleaned