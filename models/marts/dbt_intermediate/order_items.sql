{{
  config(
    materialized = 'table',
    )
}}

with raw_order_items as (
    select * from {{ ref('stg_order_items') }}
),

final as (
    select
        order_id,
        product_id,
        product_name,
        quantity,
        unit_price,
        quantity * unit_price as line_total
    from raw_order_items
)

select * from final