{{
  config(
    materialized = 'incremental',
    unique_key = 'event_id',
    tags = ['dbt_intermediate'],
    )
}}

with seed_marketing_events as (
    select * from {{ ref('raw_marketing_events') }}
    where true
        and event_timestamp <= '2026-05-16'  -- only load up to this date for demo purposes
    {% if is_incremental() %}
        and event_timestamp >= (select max(event_timestamp) from {{ this }})
    {% endif %}
),

final as (
    select
       event_id,
       event_timestamp,
       event_type,
       customer_id,
       campaign_name,
       page_url
    from seed_marketing_events
)

select * from final