{{ config(tags=['source_filter']) }}
-- Asserts the resolved source (A) filter round-trips into validation_log.old_filter for the
-- `orders` model — including the embedded single quote (O''Brien), which is stored as a string
-- literal (quotes doubled) yet must read back equal to the resolved expression. dbt_filter is
-- unset on `orders`, so it must be null. Any returned row = failure.

{% set expected_old_filter = audit_helper_ext.resolve_relation_filter('orders_before_cutoff_expr') %}

select old_filter, dbt_filter
from {{ ref('validation_log') }}
where mart_table = 'orders'
  and validation_type = 'count'
  and (old_filter != '{{ expected_old_filter | replace("'", "''") }}' or dbt_filter is not null)
