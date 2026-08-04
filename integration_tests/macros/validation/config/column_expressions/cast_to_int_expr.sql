{# Adapter-specific spelling; plain macro so branch on target.type rather than dispatch #}
{% macro cast_to_int_expr(column_name) %}
  {% set int_type = 'int' if target.type == 'sqlserver' else 'integer' %}
  {{ return('cast(' ~ column_name ~ ' as ' ~ int_type ~ ')') }}
{% endmacro %}
