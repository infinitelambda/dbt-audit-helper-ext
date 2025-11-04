
{% macro join_json_table_sql(json_column) %}
  {{ return(adapter.dispatch('join_json_table_sql', 'audit_helper_ext')(json_column)) }}
{% endmacro %}


{% macro sqlserver__join_json_table_sql(json_column) %}

  {% set sql -%}
    cross apply {{ audit_helper_ext.json_table_sql(json_column) }}
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro postgres__join_json_table_sql(json_column) %}

  {% set sql -%}
    cross join lateral {{ audit_helper_ext.json_table_sql(json_column) }}
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro default__join_json_table_sql(json_column) %}

  {% set sql -%}
    , {{ audit_helper_ext.json_table_sql(json_column) }}
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}
