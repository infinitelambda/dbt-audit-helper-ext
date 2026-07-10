{# Test fixtures: filter-expression macros, adapter-agnostic (no quoting) so they render #}
{# identically everywhere. Usable on either the source (A) or dbt (B) side. #}
{% macro source_upper_bound_expr() %}
  age <= {{ var('source_upper_bound_age', 40) }}
{% endmacro %}


{# Counterpart used to exercise the dbt (B) side in the persistence test. #}
{% macro dbt_lower_bound_expr() %}
  age >= {{ var('dbt_lower_bound_age', 25) }}
{% endmacro %}


{# Date upper-bound fixture wired onto the `orders` model to exercise the generated #}
{# validation path (incremental-load use case: bound the source to the build cutoff). #}
{% macro orders_before_cutoff_expr() %}
  ordered_at < '{{ var('orders_cutoff_date', '2017-01-01') }}'
{% endmacro %}
