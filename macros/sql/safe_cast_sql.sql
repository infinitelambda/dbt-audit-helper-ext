{% macro safe_cast_sql() %}
  {{ return(adapter.dispatch('safe_cast_sql', 'audit_helper_ext')()) }}
{% endmacro %}


{% macro default__safe_cast_sql() %}

  {% set sql -%}
    safe_cast
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro snowflake__safe_cast_sql() %}

  {% set sql -%}
    try_cast
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro sqlserver__safe_cast_sql() %}

  {% set sql -%}
    try_cast
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}
