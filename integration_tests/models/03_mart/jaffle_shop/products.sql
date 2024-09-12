{{
  config(
    materialized = 'table',
    unique_key = ['sku']
  )
}}

select *
from {{ ref('raw_products') }}
