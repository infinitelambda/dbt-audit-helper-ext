{# dbt (B) side counterpart on `orders`: every order carries a positive total, so this bound #}
{# exercises the B-side filter path end-to-end without desyncing counts against the source. #}
{% macro orders_positive_total_expr() %}
  order_total > {{ var('orders_min_total', 0) }}
{% endmacro %}
