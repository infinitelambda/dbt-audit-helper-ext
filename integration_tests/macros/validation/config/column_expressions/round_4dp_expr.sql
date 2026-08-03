{% macro round_4dp_expr(column_name) %}
  {{ return('round(' ~ column_name ~ ', 4)') }}
{% endmacro %}
