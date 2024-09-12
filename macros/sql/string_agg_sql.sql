
{% macro string_agg_sql() %}
  {{ return(adapter.dispatch('string_agg_sql', 'audit_helper_ext')()) }}
{% endmacro %}


{% macro default__string_agg_sql() %}

  {% set sql -%}
    string_agg
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro snowflake__string_agg_sql() %}

  {% set sql -%}
    listagg
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}
