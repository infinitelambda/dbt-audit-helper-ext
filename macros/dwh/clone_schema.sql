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
    {% do audit_helper_ext.clone_object(object_name=target_schema_ns, source_object_name=source_schema, object_type="schema", replace=true) %}

{% endmacro %}


{% macro postgres__clone_schema(source_schema, target_database, target_schema) %}

    {# get target location #}
    {% set target_database = target_database or target.database  %}
    {% set target_schema = target_schema or audit_helper_ext.get_versioned_name(name=source_schema or target.schema) %}

    {# create target schema if not exists #}
    {% set sql -%}
        create schema if not exists {{ target_schema }}
    {%- endset %}
    {% do run_query(sql) %}

    {# create all tables by copying data #}
    {% set sql -%}
        select table_catalog, table_schema, table_name, table_type
        from information_schema.tables
        where table_schema = '{{ source_schema }}'
        and table_type in ('BASE TABLE', 'VIEW')
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
            type='table'
        ) %}

        {% set _, target_relation = dbt.get_or_create_relation(
            database=target_database,
            schema=target_schema,
            identifier=table,
            type='table'
        ) %}

        {% do audit_helper_ext.clone_object(object_name=target_relation, source_object_name=source_relation, replace=true) %}

    {% endfor %}

{% endmacro %}


{% macro bigquery__clone_schema(source_schema, target_database, target_schema) %}

    {# get target location #}
    {% set target_database = target_database or target.database  %}
    {% set target_schema = target_schema or audit_helper_ext.get_versioned_name(name=source_schema or target.schema) %}

    {% set target_schema_ns -%}
      {{ target_database }}.{{ target_schema }}
    {%- endset %}

    {# clone #}
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

{% endmacro %}


{% macro sqlserver__clone_schema(source_schema, target_database, target_schema) %}

    {# get target location #}
    {% set target_database = target_database or target.database  %}
    {% set target_schema = target_schema or audit_helper_ext.get_versioned_name(name=source_schema or target.schema) %}

    {# create target schema if not exists #}
    {% set sql -%}
        if not exists (select * from sys.schemas where name = '{{ target_schema }}')
        begin
            exec('create schema {{ target_schema }}')
        end
    {%- endset %}
    {% do run_query(sql) %}

    {# create all tables by copying data #}
    {% set sql -%}
        select table_catalog, table_schema, table_name, table_type
        from information_schema.tables
        where table_schema = '{{ source_schema }}'
        and table_type in ('BASE TABLE', 'VIEW')
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
            type='table'
        ) %}

        {% set _, target_relation = dbt.get_or_create_relation(
            database=target_database,
            schema=target_schema,
            identifier=table,
            type='table'
        ) %}

        {% do audit_helper_ext.clone_object(object_name=target_relation, source_object_name=source_relation, replace=true) %}

    {% endfor %}

{% endmacro %}


{% macro databricks__clone_schema(source_schema, target_database, target_schema) %}

    {# get target location #}
    {% set target_database = target_database or target.database  %}
    {% set target_schema = target_schema or audit_helper_ext.get_versioned_name(name=source_schema or target.schema) %}

    {% set target_schema_ns -%}
      {{ target_database }}.{{ target_schema }}
    {%- endset %}

    {# create target schema if not exists #}
    {% set sql -%}
        create schema if not exists {{ target_schema_ns }}
    {%- endset %}
    {% do run_query(sql) %}

    {# create all tables by copying data #}
    {% set sql -%}
        select table_catalog, table_schema, table_name, table_type
        from {{ target_database }}.information_schema.tables
        where table_schema = '{{ source_schema }}'
        and table_type in ('MANAGED', 'EXTERNAL', 'VIEW')
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
            type='table'
        ) %}

        {% set _, target_relation = dbt.get_or_create_relation(
            database=target_database,
            schema=target_schema,
            identifier=table,
            type='table'
        ) %}

        {% do audit_helper_ext.clone_object(object_name=target_relation, source_object_name=source_relation, replace=true) %}

    {% endfor %}

{% endmacro %}
