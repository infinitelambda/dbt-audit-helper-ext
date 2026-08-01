{# Built-in column expression — resolved by name and called directly, so no adapter.dispatch. #}
{# SQL Server spells the integer type `int`, so branch on target.type instead. #}

{% macro audit_helper__cast_to_int(column_name) %}
  {% set int_type = 'int' if target.type == 'sqlserver' else 'integer' %}
  {{ return('cast(' ~ column_name ~ ' as ' ~ int_type ~ ')') }}
{% endmacro %}
