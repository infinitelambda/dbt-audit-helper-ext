{% macro json_field_sql(json_table_alias, json_field) %}
  {{ return(adapter.dispatch('json_field_sql', 'audit_helper_ext')(
    json_table_alias=json_table_alias,
    json_field=json_field
  )) }}
{% endmacro %}


{% macro default__json_field_sql(json_table_alias, json_field) %}

  {% set sql -%}
    json_value({{ json_table_alias }}, '$.{{ json_field }}')
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro snowflake__json_field_sql(json_table_alias, json_field) %}

  {% set sql -%}
    json_extract_path_text({{ json_table_alias }}.value, '{{ json_field }}')
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}
