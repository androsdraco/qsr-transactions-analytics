-- Structural invariant: b01: cards must never have an account_id.
-- This test PASSES when zero rows are returned.
-- Fails only if the dataset changes unexpectedly (provider schema drift).

select *
from {{ ref('stg_marketplace__qsr_transactions') }}
where card_id like 'b01:%'
  and account_id is not null