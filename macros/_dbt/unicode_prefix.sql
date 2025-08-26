{% macro unicode_prefix() %}
  {{ return(adapter.dispatch('unicode_prefix', 'audit_helper_ext')()) }}
{% endmacro %}

{% macro default__unicode_prefix() %}
    {{ return("") }}
{% endmacro %}

{% macro sqlserver__unicode_prefix() %}
    {{ return("N") }}
{% endmacro %}