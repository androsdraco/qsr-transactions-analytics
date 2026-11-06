{{ config(materialized='table') }}

with base                as (select * from {{ ref('int_qsr__transactions_base') }}),
     location            as (select * from {{ ref('int_qsr__transactions_location') }}),
     merchants           as (select * from {{ ref('int_qsr__merchants') }}),
     card_holders        as (select * from {{ ref('int_qsr__card_holders') }}),
     payment_instruments as (select * from {{ ref('int_qsr__payment_instruments') }})

select
    -- ── keys ────────────────────────────────────────────────────
    b.transaction_id,
    b.account_id,
    b.card_id,
    b.merchant_id,
    b.payment_id,

    -- ── card classification ─────────────────────────────────────
    b.card_class,
    b.card_class_description,
    b.is_anonymous_card,

    -- ── amounts ─────────────────────────────────────────────────
    b.gross_transaction_amount,
    b.currency_code,

    -- ── time ────────────────────────────────────────────────────
    b.transaction_date,
    b.local_transaction_date,
    date_trunc('day',   b.transaction_date)::date as transaction_date_day,
    date_trunc('month', b.transaction_date)::date as transaction_date_month,
    year(b.transaction_date)                      as transaction_year,
    month(b.transaction_date)                     as transaction_month,
    dayofweek(b.transaction_date)                 as transaction_dow,
    hour(b.transaction_date)                      as transaction_hour,

    -- ── transaction ─────────────────────────────────────────────
    b.transaction_type,
    b.transaction_state,
    b.transaction_description,

    -- ── transaction location ────────────────────────────────────
    l.transaction_city,
    l.transaction_msa,
    l.transaction_postal_code,
    l.transaction_latitude,
    l.transaction_longitude,

    -- ── merchant ────────────────────────────────────────────────
    m.merchant_name,
    m.merchant_city,
    m.merchant_state,
    m.merchant_msa,
    m.merchant_postal_code,
    m.merchant_latitude,
    m.merchant_longitude,
    m.merchant_store_id,
    m.merchant_store_location,
    m.merchant_store_address,
    m.mcc_code,
    m.top_mcc_code,
    m.merchant_category_level_1,
    m.merchant_category_level_2,
    m.merchant_category_level_3,

    -- ── cardholder ──────────────────────────────────────────────
    c.card_holder_city,
    c.card_holder_state,
    c.card_holder_msa,
    c.card_holder_postal_code,
    c.card_holder_postal_code_present,
    c.card_holder_latitude,
    c.card_holder_longitude,
    c.card_holder_generation,
    c.card_holder_personas,
    c.card_holder_vintage_years,
    c.lifetime_txn_count,
    c.lifetime_spend,
    c.avg_ltm_spend,
    c.avg_ltm_txn_count,

    -- ── payment ─────────────────────────────────────────────────
    p.payment_name,
    p.card_type,
    p.is_card_present,
    p.is_consistent_shopper,

    -- ── audit ───────────────────────────────────────────────────
    b._loaded_at,
    current_timestamp() as _fact_built_at

from base                b
left join location            l on b.transaction_id = l.transaction_id
left join merchants           m on b.transaction_id = m.transaction_id
left join card_holders        c on b.transaction_id = c.transaction_id
left join payment_instruments p on b.transaction_id = p.transaction_id