{{
  config(
    materialized = 'view',
    tags = ['dbt_intermediate'],
    )
}}

with seed_order_items as (
    select * from {{ ref('raw_order_items') }}
),

final as(
    select
        order_id,
        product_id,
        product_name,
        quantity,
        unit_price_cents
    from seed_order_items
)

select * from final