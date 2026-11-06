{{ config(materialized='table') }}

with wide as (
    select * from {{ ref('int_qsr__transactions_wide') }}
)

select
    -- ── primary key ─────────────────────────────────────────────
    transaction_id,

    -- ── date + time dim keys ────────────────────────────────────
    transaction_date,
    transaction_date::date          as date_day,

    -- ── foreign keys ────────────────────────────────────────────
    merchant_id,                    -- → dim_merchants
    account_id,                     -- → dim_card_holders (null for b01:)
    payment_id,                     -- → dim_payment_instruments
    card_class,                     -- → dim_card_classes

    -- ── denormalized convenience flags ──────────────────────────
    is_anonymous_card,              -- also lives in dim_card_classes

    -- ── attributes (small cardinality, kept in fact) ────────────
    transaction_type,
    currency_code,

    -- ── measures ────────────────────────────────────────────────
    gross_transaction_amount,

    -- ── audit ───────────────────────────────────────────────────
    _loaded_at,
    current_timestamp()             as _fact_built_at

from wide