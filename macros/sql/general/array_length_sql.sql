
{% macro array_length_sql() %}
  {{ return(adapter.dispatch('array_length_sql', 'audit_helper_ext')()) }}
{% endmacro %}


{% macro default__array_length_sql() %}

  {% set sql -%}
    array_length
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro snowflake__array_length_sql() %}

  {% set sql -%}
    array_size
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro databricks__array_length_sql() %}

  {% set sql -%}
    size
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}
