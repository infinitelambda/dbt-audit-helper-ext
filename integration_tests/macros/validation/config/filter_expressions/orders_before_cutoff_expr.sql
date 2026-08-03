{# Filter-expression fixture, adapter-agnostic (no quoting) so it renders identically #}
{# everywhere. Wired onto models via meta.audit_helper__source_filter (A side). #}
{# Cutoff bound + a single-quote literal (O''Brien, matching no row) to exercise quote #}
{# handling through the generated validation path. #}
{% macro orders_before_cutoff_expr() %}
  ordered_at < '{{ var('orders_cutoff_date', '2017-01-01') }}' and customer != 'O''Brien'
{% endmacro %}
