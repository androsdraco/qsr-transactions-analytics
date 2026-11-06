{{ config(materialized='table') }}

with distinct_classes as (
    select
        card_class,
        card_class_description,
        is_anonymous_card
    from {{ ref('stg_marketplace__qsr_transactions') }}
    group by 1, 2, 3
)

select
    card_class,
    card_class_description,
    is_anonymous_card,
    case
        when is_anonymous_card then 'Anonymous / non-consumer'
        else 'Consumer card'
    end                                         as card_segment,
    current_timestamp()                         as _dim_built_at
from distinct_classes