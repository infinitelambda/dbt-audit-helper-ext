{% macro round_4dp_expr(column_name) %}
  {{ return('round(' ~ roundable_numeric(column_name) ~ ', 4)') }}
{% endmacro %}
