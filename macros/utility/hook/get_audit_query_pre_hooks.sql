{% macro get_audit_query_pre_hooks() %}
  {{ return(adapter.dispatch('get_audit_query_pre_hooks', 'audit_helper_ext')()) }}
{% endmacro %}


{% macro default__get_audit_query_pre_hooks() %}
  {% set query_pre_hooks = var('audit_helper__audit_query_pre_hooks', []) %}
  {{ return(query_pre_hooks) }}
{% endmacro %}
