{{
  config(
    materialized = 'view',
    )
}}

with seed_customers_extended as (
    select * from {{ ref('raw_customers_extended') }}
),

final as(
    select
       customer_id,
       email,
       signup_date,
       country_code,
       marketing_opt_in
    from seed_customers_extended
)

select * from final