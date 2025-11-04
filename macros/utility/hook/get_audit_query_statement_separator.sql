{% macro get_audit_query_statement_separator() %}
  {{ return(adapter.dispatch('get_audit_query_statement_separator', 'audit_helper_ext')()) }}
{% endmacro %}


{% macro default__get_audit_query_statement_separator() %}
  {% set separator = var('audit_helper__audit_query_statement_separator', ';') %}
  {{ return(separator) }}
{% endmacro %}

{% macro sqlserver__get_audit_query_statement_separator() %}
  {% set separator = var('audit_helper__audit_query_statement_separator', 'GO') %}
  {{ return(separator) }}
{% endmacro %}