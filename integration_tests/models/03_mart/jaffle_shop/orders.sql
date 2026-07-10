{{
  config(
    materialized = 'table',
    unique_key = ['id'],
    meta = {
      'audit_helper__source_filter': 'orders_before_cutoff_expr'
    }
  )
}}

select
    id,
    customer,
    ordered_at,
    store_id,
    subtotal,
    tax_paid,
    cast(order_total + 1 as {{ dbt.type_numeric() }}) as order_total
from {{ ref('raw_orders') }}
where tax_paid = 42

union all

select
    id,
    customer,
    ordered_at,
    store_id,
    subtotal,
    tax_paid,
    cast(order_total + 1 as {{ dbt.type_numeric() }}) as order_total
from {{ ref('raw_orders') }}
where tax_paid != 42
