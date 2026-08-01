{# Built-in column expression — resolved by name and called directly, so no adapter.dispatch. #}

{% macro audit_helper__round_4dp(column_name) %}
  {{ return('round(' ~ column_name ~ ', 4)') }}
{% endmacro %}
