{# Test fixtures: filter-expression macros, adapter-agnostic (no quoting) so they render #}
{# identically everywhere. Wired onto models via meta.audit_helper__source_filter (A side) #}
{# and meta.audit_helper__dbt_filter (B side). #}

{# On the `orders` model: cutoff bound + a single-quote literal (O''Brien, matching no row) #}
{# to exercise quote handling through the generated validation path. #}
{% macro orders_before_cutoff_expr() %}
  ordered_at < '{{ var('orders_cutoff_date', '2017-01-01') }}' and customer != 'O''Brien'
{% endmacro %}


{# dbt (B) side counterpart on `orders`: every order carries a positive total, so this bound #}
{# exercises the B-side filter path end-to-end without desyncing counts against the source. #}
{% macro orders_positive_total_expr() %}
  order_total > {{ var('orders_min_total', 0) }}
{% endmacro %}


{# Source (A) side on `customers`: every customer carries a name, so this bound exercises the #}
{# A-side filter path end-to-end without desyncing counts against the dbt side. #}
{% macro customers_named_expr() %}
  name is not null
{% endmacro %}


{# Dummy macro #}
{% macro dummy_true() %}
  1 = 1 /* dummy filter relation - testing purpose */
{% endmacro %}