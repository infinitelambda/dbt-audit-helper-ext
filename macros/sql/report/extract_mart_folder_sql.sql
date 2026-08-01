
{% macro extract_mart_folder_sql(mart_path) %}
  {{ return(adapter.dispatch('extract_mart_folder_sql', 'audit_helper_ext')(mart_path)) }}
{% endmacro %}


{% macro sqlserver__extract_mart_folder_sql(mart_path) %}

  {% set sql -%}
    cast(
      case
        when len(mart_path) - len(replace(mart_path, '/', '')) >= 2
        then reverse(parsename(replace(reverse(mart_path), '/', '.'), 2))
        else null
      end as {{ dbt.type_string() }}
    )
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro postgres__extract_mart_folder_sql(mart_path) %}

  {% set mart_paths -%}
    string_to_array({{ mart_path }}, '/')
  {%- endset %}

  {% set sql -%}
    cast(({{ mart_paths }})[array_length({{ mart_paths }}, 1) - 1] as {{ dbt.type_string() }})
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


{% macro databricks__extract_mart_folder_sql(mart_path) %}

  {% set mart_paths -%}
    split({{ mart_path }}, '/')
  {%- endset %}

  {% set sql -%}
    cast(element_at({{ mart_paths }}, size({{ mart_paths }}) - 1) as {{ dbt.type_string() }})
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}
