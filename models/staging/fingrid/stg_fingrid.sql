{{
  config(
    materialized = 'view',
    tags = ['fingrid']
    )
}}

select *
from {{ source('fingrid', 'consumption') }}