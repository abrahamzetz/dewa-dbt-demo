{% snapshot dq_customers_snapshot %}
    {{
        config(
            target_schema='snapshots',
            unique_key='customer_id',
            strategy='timestamp',
            updated_at='updated_at',
            invalidate_hard_deletes=true
        )
    }}
    SELECT * FROM {{ source('dq_snapshots', 'dq_customers') }}
{% endsnapshot %}
