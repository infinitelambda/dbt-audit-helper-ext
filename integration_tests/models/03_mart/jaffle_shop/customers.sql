{{
  config(
    materialized = 'table',
    unique_key = ['id'],
    meta = {
      'audit_helper__source_filter': 'customers_named_expr'
    }
  )
}}

select *
from {{ ref('raw_customers') }}
