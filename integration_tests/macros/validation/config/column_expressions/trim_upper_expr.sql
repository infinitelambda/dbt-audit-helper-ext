{% macro trim_upper_expr(column_name) %}
  {{ return('upper(trim(' ~ column_name ~ '))') }}
{% endmacro %}
