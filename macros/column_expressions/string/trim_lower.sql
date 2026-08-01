{# Built-in column expression — resolved by name and called directly, so no adapter.dispatch. #}

{% macro audit_helper__trim_lower(column_name) %}
  {{ return('lower(trim(' ~ column_name ~ '))') }}
{% endmacro %}
