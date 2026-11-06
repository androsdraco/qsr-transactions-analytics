{{ config(materialized='table') }}

with source as (
    select * from {{ ref('stg_marketplace__qsr_transactions') }}
),

cleaned as (
    select
        -- keys
        transaction_id,
        account_id,
        card_id,
        merchant_id,
        payment_id,

        -- card classification
        card_class,
        card_class_description,
        is_anonymous_card,

        -- amounts
        cast(gross_transaction_amount as number(18,2))  as gross_transaction_amount,
        currency_code,

        -- timestamps
        transaction_date,
        local_transaction_date,

        -- transaction attributes
        transaction_type,
        transaction_state,
        card_type,
        transaction_description,

        -- flags
        consistent_shopper,
        card_present_indicator,

        -- audit
        _loaded_at

    from source
    where transaction_id  is not null
      and transaction_date is not null
)

select * from cleaned