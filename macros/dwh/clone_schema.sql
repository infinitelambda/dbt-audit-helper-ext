{% macro clone_schema(source_schema, target_database=none, target_schema=none) %}
    {{ return(adapter.dispatch('clone_schema', 'audit_helper_ext')(
        source_schema=source_schema,
        target_database=target_database,
        target_schema=target_schema
    )) }}
{% endmacro %}


{% macro default__clone_schema(source_schema, target_database, target_schema) %}

    {# get target location #}
    {% set target_database = target_database or target.database  %}
    {% set target_schema = target_schema or audit_helper_ext.get_versioned_name(name=source_schema or target.schema) %}

    {% set target_schema_ns -%}
      {{ target_database }}.{{ target_schema }}
    {%- endset %}

    {# clone #}
    {% if target.type != "bigquery" %}

        {% do audit_helper_ext.clone_object(object_name=target_schema_ns, source_object_name=source_schema, object_type="schema", replace=true) %}

    {% else %}

        {# create target schema if not exists #}
        {% set sql -%}
            create schema if not exists {{ target_schema_ns }}
        {%- endset %}
        {% do run_query(sql) %}

        {# create all tables #}
        {% set sql -%}
            select table_catalog, table_schema, table_name, table_type
            from {{ source_schema }}.INFORMATION_SCHEMA.TABLES
        {%- endset %}

        {% set tables_list = dbt_utils.get_query_results_as_dict(sql) %}

        {% for i in range(tables_list['table_name'] | length) %}

            {% set table = tables_list['table_name'][i] %}
            {% set schema = tables_list['table_schema'][i] %}
            {% set database = tables_list['table_catalog'][i] %}
            {% set table_type = tables_list['table_type'][i] %}

            {% set _, source_relation = dbt.get_or_create_relation(
                database=database,
                schema=schema,
                identifier=table,
                type=table_type
            ) %}

            {% set _, target_relation = dbt.get_or_create_relation(
                database=target_database,
                schema=target_schema,
                identifier=table,
                type='table'
            ) %}

            {% do audit_helper_ext.clone_object(object_name=target_relation, source_object_name=source_relation, replace=true) %}

        {% endfor %}

    {% endif %}

{% endmacro %}
