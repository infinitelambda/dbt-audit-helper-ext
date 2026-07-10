{{ config(tags=['source_filter']) }}
-- Asserts the source (A) filter wired onto the `orders` model actually bounds the source.
-- `raw_orders` holds rows on both sides of the cutoff; after applying the resolved filter,
-- no out-of-bound row (ordered_at >= cutoff) may survive. Any returned row = failure.

{% set source_relation = adapter.get_relation(
    database=var('audit_helper__source_database', target.database),
    schema=audit_helper_ext.get_versioned_name(name=var('audit_helper__source_schema', target.schema)),
    identifier=audit_helper_ext.get_old_identifier_name('orders')
) %}
{% set a_filter = audit_helper_ext.resolve_source_filter('orders_before_cutoff_expr') %}

select count(*) as out_of_bound_rows
from {{ source_relation }}
where {{ a_filter }}
  and ordered_at >= '{{ var('orders_cutoff_date', '2017-01-01') }}'
having count(*) > 0
