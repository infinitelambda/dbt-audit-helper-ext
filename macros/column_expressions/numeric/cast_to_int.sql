{% macro audit_helper__cast_to_int(column_name) %}
  {{ return(adapter.dispatch('audit_helper__cast_to_int', 'audit_helper_ext')(column_name)) }}
{% endmacro %}

{% macro default__audit_helper__cast_to_int(column_name) %}
  cast({{ column_name }} as integer)
{% endmacro %}

{% macro sqlserver__audit_helper__cast_to_int(column_name) %}
  cast({{ column_name }} as int)
{% endmacro %}
