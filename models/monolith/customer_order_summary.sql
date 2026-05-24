-- ============================================================================
-- MONOLITH MODEL: customer_order_summary.sql
--
-- This single model does everything: pulls from raw sources, cleans up,
-- joins, and aggregates into a final reporting table.
--
-- YOUR TASK:
--   Refactor this into the staging / intermediate / marts pattern.
--   Aim for:
--     - models/staging/jaffle_shop/
--         stg_jaffle_shop__customers.sql
--         stg_jaffle_shop__orders.sql
--         stg_jaffle_shop__order_items.sql
--     - models/staging/stripe/
--         stg_stripe__payments.sql
--     - models/intermediate/
--         int_order_totals.sql           (one row per order, with payment total)
--         int_customer_order_metrics.sql (one row per customer, with aggregates)
--     - models/marts/marketing/
--         dim_customers.sql              (the final shape you see at the bottom)
--
--   Rules:
--     - Staging models are 1:1 with sources, do only renaming, casting, light cleanup. No joins.
--     - Intermediate models do the joins and aggregations.
--     - Marts models are the final tables stakeholders query.
--     - Every model should use {{ ref() }} or {{ source() }}, never raw table names.
--
--   When done, run `dbt run` and confirm the DAG shows the layered structure.
-- ============================================================================

with

raw_customers as (
    select
        id as customer_id,
        first_name,
        last_name
    from raw.jaffle_shop.customers
),

raw_orders as (
    select
        id as order_id,
        user_id as customer_id,
        order_date,
        status
    from raw.jaffle_shop.orders
),

raw_order_items as (
    select
        order_id,
        product_id,
        product_name,
        quantity,
        unit_price,
        quantity * unit_price as line_total
    from raw.jaffle_shop.order_items
),

raw_payments as (
    select
        id as payment_id,
        orderid as order_id,
        paymentmethod as payment_method,
        status as payment_status,
        amount / 100.0 as amount  -- raw is in cents
    from raw.stripe.payment
),

-- one row per order with payment info
orders_with_payments as (
    select
        o.order_id,
        o.customer_id,
        o.order_date,
        o.status as order_status,
        sum(case when p.payment_status = 'success' then p.amount else 0 end) as amount_paid,
        count(distinct p.payment_id) as payment_count
    from raw_orders o
    left join raw_payments p on o.order_id = p.order_id
    group by 1, 2, 3, 4
),

-- one row per order with item totals
orders_with_items as (
    select
        order_id,
        sum(line_total) as items_subtotal,
        sum(quantity) as items_count,
        count(distinct product_id) as distinct_products
    from raw_order_items
    group by 1
),

-- combine the two
orders_final as (
    select
        op.order_id,
        op.customer_id,
        op.order_date,
        op.order_status,
        op.amount_paid,
        op.payment_count,
        oi.items_subtotal,
        oi.items_count,
        oi.distinct_products
    from orders_with_payments op
    left join orders_with_items oi on op.order_id = oi.order_id
),

-- aggregate up to the customer level
customer_metrics as (
    select
        customer_id,
        count(distinct order_id) as number_of_orders,
        min(order_date) as first_order_date,
        max(order_date) as most_recent_order_date,
        sum(amount_paid) as customer_lifetime_value,
        sum(items_count) as total_items_purchased,
        avg(amount_paid) as average_order_value
    from orders_final
    group by 1
),

final as (
    select
        c.customer_id,
        c.first_name,
        c.last_name,
        c.first_name || ' ' || c.last_name as full_name,
        coalesce(cm.number_of_orders, 0) as number_of_orders,
        cm.first_order_date,
        cm.most_recent_order_date,
        coalesce(cm.customer_lifetime_value, 0) as customer_lifetime_value,
        coalesce(cm.total_items_purchased, 0) as total_items_purchased,
        coalesce(cm.average_order_value, 0) as average_order_value,
        case
            when cm.number_of_orders >= 3 then 'loyal'
            when cm.number_of_orders >= 1 then 'active'
            else 'prospect'
        end as customer_segment
    from raw_customers c
    left join customer_metrics cm on c.customer_id = cm.customer_id
)

select * from final
