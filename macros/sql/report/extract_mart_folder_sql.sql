
{% macro extract_mart_folder_sql(mart_path) %}
  {{ return(adapter.dispatch('extract_mart_folder_sql', 'audit_helper_ext')(mart_path)) }}
{% endmacro %}


{% macro sqlserver__extract_mart_folder_sql(mart_path) %}

  {% set sql -%}
    cast(
      reverse(
        substring(
          reverse({{ mart_path }}),
          charindex('/', reverse({{ mart_path }}), charindex('/', reverse({{ mart_path }})) + 1) + 1,
          charindex('/', reverse({{ mart_path }})) - charindex('/', reverse({{ mart_path }}), charindex('/', reverse({{ mart_path }})) + 1) - 1
        )
      ) as {{ dbt.type_string() }}
    )
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro default__extract_mart_folder_sql(mart_path) %}

  {% set mart_paths -%}
    split({{ mart_path }}, '/')
  {%- endset %}

  {% set sql -%}
    cast({{ mart_paths }}[{{ array_length_sql() }}({{ mart_paths }}) - 2] as {{ dbt.type_string() }})
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}
