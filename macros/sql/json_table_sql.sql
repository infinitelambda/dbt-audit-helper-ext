{% macro json_table_sql(json_column) %}
  {{ return(adapter.dispatch('json_table_sql', 'audit_helper_ext')(json_column=json_column)) }}
{% endmacro %}


{% macro default__json_table_sql(json_column) %}

  {% set sql -%}
    unnest(json_query_array({{ json_column }}))
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro snowflake__json_table_sql(json_column) %}

  {% set sql -%}
    lateral flatten(input => parse_json({{ json_column }}))
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro sqlserver__json_table_sql(json_column) %}

  {% set sql -%}
    openjson({{ json_column }}) with (result nvarchar(max) '$' as json)
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}
