with customers as (
        select * from {{ ref('stg_customers') }}
),

int_customers_orders as (
    select * from {{ ref('int_customers_orders') }}
),

final as (
    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customers_orders.first_order_date,
        customers_orders.most_recent_order_date,
        coalesce(customers_orders.number_of_orders, 0) as number_of_orders
    from customers
    left join int_customers_orders as customers_orders
        on customers.customer_id = customers_orders.customer_id
)

select * from final

-- demonstrate test error
--union all
--select null, 'Muhammad', 'A.', null, null, 0