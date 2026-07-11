{# Test fixtures: filter-expression macros, adapter-agnostic (no quoting) so they render #}
{# identically everywhere. Usable on either the source (A) or dbt (B) side. #}
{% macro source_upper_bound_expr() %}
  age <= {{ var('source_upper_bound_age', 40) }}
{% endmacro %}


{# Counterpart used to exercise the dbt (B) side in the persistence test. #}
{% macro dbt_lower_bound_expr() %}
  age >= {{ var('dbt_lower_bound_age', 25) }}
{% endmacro %}


{# On the `orders` model: cutoff bound + a single-quote literal (O''Brien, matching no row) #}
{# to exercise quote handling through the generated validation path. #}
{% macro orders_before_cutoff_expr() %}
  ordered_at < '{{ var('orders_cutoff_date', '2017-01-01') }}' and customer != 'O''Brien'
{% endmacro %}
