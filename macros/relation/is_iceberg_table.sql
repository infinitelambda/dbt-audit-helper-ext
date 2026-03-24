{% macro is_iceberg_table(relation) %}
  {{ return(adapter.dispatch('is_iceberg_table', 'audit_helper_ext')(
      relation=relation
  )) }}
{% endmacro %}


{% macro default__is_iceberg_table(relation) %}

    {% set sql -%}
        select case when is_iceberg = 'YES' then true else false end as is_iceberg
        from {{ relation.database }}.information_schema.tables
        where UPPER(table_schema) = '{{ relation.schema | upper }}'
        and UPPER(table_name) = '{{ relation.identifier | upper }}'
    {%- endset %}

    {% set result = run_query(sql) %}
    {% if result and result.rows | length > 0 %}
        {{ return(result.rows[0][0]) }}
    {% endif %}

    {{ return(false) }}

{% endmacro %}


{% macro postgres__is_iceberg_table(relation) %}
    {{ return(false) }}
{% endmacro %}


{% macro sqlserver__is_iceberg_table(relation) %}
    {{ return(false) }}
{% endmacro %}


{% macro bigquery__is_iceberg_table(relation) %}
    {{ return(false) }}
{% endmacro %}


{% macro databricks__is_iceberg_table(relation) %}
    {{ return(false) }}
{% endmacro %}
