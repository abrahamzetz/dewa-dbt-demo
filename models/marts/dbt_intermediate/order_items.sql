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
        unit_price_cents,
        {{ cents_to_dollars('unit_price_cents', 0) }} as unit_price_usd,
        quantity * {{ cents_to_dollars('unit_price_cents', 0) }} as line_total
    from stg_order_items

    --union all
    --select 100000, 1000000, 'x', 1, 1,1

    --union all
    --select 100000, 10000, 'x', 1, 1,1
)

select * from final