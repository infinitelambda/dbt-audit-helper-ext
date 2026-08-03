{# Column-expression fixture. The column name arrives already quoted for the adapter. #}
{% macro round_2dp_expr(column_name) %}
  {{ return('round(' ~ roundable_numeric(column_name) ~ ', 2)') }}
{% endmacro %}
