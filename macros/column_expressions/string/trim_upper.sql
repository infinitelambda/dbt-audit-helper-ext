{% macro audit_helper__trim_upper(column_name) %}
  {{ return(adapter.dispatch('audit_helper__trim_upper', 'audit_helper_ext')(column_name)) }}
{% endmacro %}

{% macro default__audit_helper__trim_upper(column_name) %}
  upper(trim({{ column_name }}))
{% endmacro %}
