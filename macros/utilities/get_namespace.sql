{% macro get_namespace() %}
  {{ return(adapter.dispatch('get_namespace', 'audit_helper_ext')) }}
{% endmacro %}

{% macro default__get_namespace() %}

  {% set namespace -%}
    {{ generate_database_name(var("audit_helper__database", target.database)) }}.
    {{- generate_schema_name(var("audit_helper__schema", target.schema)) }}
  {%- endset %}

  {{ return(namespace) }}

{% endmacro %}
