{{
  config(
    materialized = 'table',
    unique_key = ['id']
  )
}}

select * replace(
    order_total + 1 as order_total
  )
from {{ ref('raw_orders') }}
where tax_paid = 700

union all

select *
from {{ ref('raw_orders') }}
where tax_paid != 700
