{{
  config(
    materialized = 'table',
    unique_key = ['id']
  )
}}

select *
from {{ ref('raw_customers') }}
