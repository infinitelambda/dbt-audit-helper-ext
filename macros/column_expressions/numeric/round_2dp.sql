{% macro audit_helper__round_2dp(column_name) %}
  {{ return(adapter.dispatch('audit_helper__round_2dp', 'audit_helper_ext')(column_name)) }}
{% endmacro %}

{% macro default__audit_helper__round_2dp(column_name) %}
  round({{ column_name }}, 2)
{% endmacro %}
