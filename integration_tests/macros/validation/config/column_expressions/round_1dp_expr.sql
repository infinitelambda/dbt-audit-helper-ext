{% macro round_1dp_expr(column_name) %}
  {{ return('round(' ~ column_name ~ ', 1)') }}
{% endmacro %}
