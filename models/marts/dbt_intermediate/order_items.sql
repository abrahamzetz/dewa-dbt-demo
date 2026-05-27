{{
  config(
    materialized = 'table',
    tags = ['dbt_intermediate'],
    )
}}

with stg_order_items as (
    select * from {{ ref('stg_order_items') }}
),

final as (
    select
        order_id,
        product_id,
        product_name,
        quantity,
        {{ cents_to_dollars('unit_price_cents', 2) }} as unit_price_usd,
        quantity * {{ cents_to_dollars('unit_price_cents', 2) }} as line_total
    from stg_order_items
)

select * from final