{% macro audit_helper__trim_lower(column_name) %}
  {{ return(adapter.dispatch('audit_helper__trim_lower', 'audit_helper_ext')(column_name)) }}
{% endmacro %}

{% macro default__audit_helper__trim_lower(column_name) %}
  lower(trim({{ column_name }}))
{% endmacro %}
