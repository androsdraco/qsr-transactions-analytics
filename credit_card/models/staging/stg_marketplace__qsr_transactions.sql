{{ config(materialized='view') }}

with source as (
    select * from {{ source('marketplace', 'QSR_TRANSACTIONS_SAMPLE') }}
),

cleaned as (
    select
        -- ── identity ────────────────────────────────────────────────
        account_id,                                                          -- null for b01: cards (structural)
        card_id,
        coalesce(split_part(card_id, ':', 1), 'UNKNOWN')            as card_class,
        case split_part(card_id, ':', 1)
            when 'a01' then 'Legacy consumer card (older schema)'
            when 'a03' then 'Payroll-issued consumer card'
            when 'a04' then 'Consumer debit card (current schema)'
            when 'a09' then 'Consumer debit card (variant schema)'
            when 'a13' then 'General-purpose consumer card'
            when 'a14' then 'General-purpose consumer card (variant)'
            when 'b01' then 'Anonymous / payroll / vending token (no cardholder identity)'
            when 'c03' then 'Consumer credit / debit card'
            when 'i01' then 'Legacy vending-optimized card'
            when 'o91' then 'Merchant-platform-integrated card (Square / Toast)'
            when 'o92' then 'Merchant-platform-integrated card (Square / Toast variant)'
            when 'o93' then 'Merchant-platform-integrated card (PayPal / online)'
            when 't01' then 'Merchant-direct integrated card (rare)'
            when 'v01' then 'Vending / legacy merchant-scoped card'
            when 'x01' then 'Aggregated / placeholder card (low-confidence data)'
            else 'Unclassified'
        end                                                         as card_class_description,
        transaction_id,
        merchant_id,
        payment_id,

        -- ── amounts ─────────────────────────────────────────────────
        gross_transaction_amount,
        coalesce(nullif(trim(currency_code), ''), 'UNKNOWN')        as currency_code,
        coalesce(card_holder_total_spend,                    0)     as card_holder_total_spend,
        coalesce(card_holder_average_ltm_spend,              0)     as card_holder_average_ltm_spend,
        coalesce(card_holder_total_transaction_count,        0)     as card_holder_total_transaction_count,
        coalesce(card_holder_average_ltm_transaction_count,  0)     as card_holder_average_ltm_transaction_count,

        -- ── timestamps ──────────────────────────────────────────────
        transaction_date,
        coalesce(local_transaction_date, transaction_date)          as local_transaction_date,

        -- ── transaction attributes ──────────────────────────────────
        coalesce(nullif(trim(transaction_type), ''),        'UNKNOWN') as transaction_type,
        coalesce(nullif(trim(transaction_state), ''),       'UNKNOWN') as transaction_state,
        coalesce(nullif(trim(card_type), ''),               'UNKNOWN') as card_type,
        coalesce(nullif(trim(card_present_indicator), ''),  'UNKNOWN') as card_present_indicator,
        coalesce(consistent_shopper, 0)                                as consistent_shopper,
        coalesce(nullif(trim(transaction_description), ''), 'UNKNOWN') as transaction_description,

        -- ── transaction location ────────────────────────────────────
        coalesce(nullif(trim(transaction_city), ''),        'UNKNOWN') as transaction_city,
        coalesce(nullif(trim(transaction_msa), ''),         'UNKNOWN') as transaction_msa,
        coalesce(nullif(trim(transaction_postal_code), ''), 'UNKNOWN') as transaction_postal_code,
        try_to_number(transaction_latitude,  10, 6)                    as transaction_latitude,
        try_to_number(transaction_longitude, 10, 6)                    as transaction_longitude,

        -- ── merchant ────────────────────────────────────────────────
        coalesce(nullif(trim(merchant_name), ''),           'NO ENTITY') as merchant_name,
        coalesce(nullif(trim(merchant_city), ''),           'UNKNOWN')   as merchant_city,
        coalesce(nullif(trim(merchant_state), ''),          'UNKNOWN')   as merchant_state,
        coalesce(nullif(trim(merchant_msa), ''),            'UNKNOWN')   as merchant_msa,
        coalesce(nullif(trim(merchant_postal_code), ''),    'UNKNOWN')   as merchant_postal_code,
        try_to_number(merchant_latitude,  10, 6)                          as merchant_latitude,
        try_to_number(merchant_longitude, 10, 6)                          as merchant_longitude,
        coalesce(nullif(trim(merchant_store_id), ''),       'UNKNOWN')   as merchant_store_id,
        coalesce(nullif(trim(merchant_store_location), ''), 'UNKNOWN')   as merchant_store_location,
        coalesce(nullif(trim(merchant_store_address), ''),  'UNKNOWN')   as merchant_store_address,
        coalesce(nullif(trim(merchant_category_code), ''),  'UNKNOWN')   as merchant_category_code,  -- ← ADD THIS
        coalesce(nullif(trim(merchant_category_level_1), ''), 'UNKNOWN') as merchant_category_level_1,
        coalesce(nullif(trim(merchant_category_level_2), ''), 'UNKNOWN') as merchant_category_level_2,
        coalesce(nullif(trim(merchant_category_level_3), ''), 'UNKNOWN') as merchant_category_level_3,
        coalesce(nullif(trim(top_merchant_category_code), ''), 'UNKNOWN') as top_merchant_category_code,

        -- ── card holder ─────────────────────────────────────────────
        coalesce(nullif(trim(card_holder_city), ''),               'UNKNOWN') as card_holder_city,
        coalesce(nullif(trim(card_holder_state), ''),              'UNKNOWN') as card_holder_state,
        coalesce(nullif(trim(card_holder_msa), ''),                'UNKNOWN') as card_holder_msa,
        coalesce(nullif(trim(card_holder_postal_code), ''),        'UNKNOWN') as card_holder_postal_code,
        coalesce(nullif(trim(card_holder_postal_code_present), ''),'UNKNOWN') as card_holder_postal_code_present,
        try_to_number(card_holder_latitude,  10, 6)                           as card_holder_latitude,
        try_to_number(card_holder_longitude, 10, 6)                           as card_holder_longitude,
        coalesce(nullif(trim(card_holder_generation), ''),         'UNKNOWN') as card_holder_generation,
        coalesce(card_holder_vintage, 0)                                       as card_holder_vintage,
        coalesce(nullif(trim(card_holder_personas), ''),           'UNKNOWN') as card_holder_personas,

        -- ── payment ─────────────────────────────────────────────────
        coalesce(nullif(trim(payment_name), ''), 'UNKNOWN') as payment_name,

        -- ── derived flags ───────────────────────────────────────────
        case when card_id like 'b01:%' then true else false end as is_anonymous_card,

        -- ── audit ───────────────────────────────────────────────────
        current_timestamp() as _loaded_at

    from source
)

select * from cleaned