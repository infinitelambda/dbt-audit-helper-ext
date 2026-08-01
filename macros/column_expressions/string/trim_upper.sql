{# Built-in column expression — resolved by name and called directly, so no adapter.dispatch. #}

{% macro audit_helper__trim_upper(column_name) %}
  {{ return('upper(trim(' ~ column_name ~ '))') }}
{% endmacro %}
