{# Row count #}
{%- macro validation_count__stores() %}

    {% set dbt_identifier = 'stores' %}

    {% set old_database = var('audit_helper__source_database', target.database) %}
    {% set old_schema = audit_helper_ext.get_versioned_name(name=var('audit_helper__source_schema', target.schema)) %}
    {% set old_identifier = 'stores' %}

    {% if execute %}

        {{ audit_helper_ext.get_validation_count(
            dbt_identifier=dbt_identifier,
            old_database=old_database,
            old_schema=old_schema,
            old_identifier=old_identifier
        ) }}

    {% endif %}

{% endmacro %}


{# Column comparison #}
{%- macro validation_all_col__stores(summarize=true) -%}

    {% set dbt_identifier = 'stores' %}

    {% set old_database = var('audit_helper__source_database', target.database) %}
    {% set old_schema = audit_helper_ext.get_versioned_name(name=var('audit_helper__source_schema', target.schema)) %}
    {% set old_identifier = 'stores' %}

    {%- set primary_keys = ['id'] -%}
    {%- set exclude_columns = [] -%}

    {% if execute %}

        {{ audit_helper_ext.get_validation_all_col(
            dbt_identifier=dbt_identifier,
            old_database=old_database,
            old_schema=old_schema,
            old_identifier=old_identifier,
            primary_keys=primary_keys,
            exclude_columns=exclude_columns,
            summarize=summarize
        ) }}

    {% endif %}

{% endmacro %}


{# Full validation #}
{%- macro validation_full__stores(summarize=true) -%}

    {% set dbt_identifier = 'stores' %}

    {% set old_database = var('audit_helper__source_database', target.database) %}
    {% set old_schema = audit_helper_ext.get_versioned_name(name=var('audit_helper__source_schema', target.schema)) %}
    {% set old_identifier = 'stores' %}

    {%- set primary_keys = ['id'] -%}
    {%- set exclude_columns = [] -%}

    {% if execute %}

        {{ audit_helper_ext.get_validation_full(
            dbt_identifier=dbt_identifier,
            old_database=old_database,
            old_schema=old_schema,
            old_identifier=old_identifier,
            primary_keys=primary_keys,
            exclude_columns=exclude_columns,
            summarize=summarize
        ) }}

    {% endif %}

{% endmacro %}


{# Validations for All #}
{%- macro validations__stores(summarize=true) -%}

    {% set dbt_identifier = 'stores' %}

    {% set old_database = var('audit_helper__source_database', target.database) %}
    {% set old_schema = audit_helper_ext.get_versioned_name(name=var('audit_helper__source_schema', target.schema)) %}
    {% set old_identifier = 'stores' %}

    {%- set primary_keys = ['id'] -%}
    {%- set exclude_columns = [] -%}

    {% if execute %}

        {{ audit_helper_ext.get_upstream_row_count(
            dbt_identifier=dbt_identifier
        ) }}

        {{ audit_helper_ext.get_validation_full(
            dbt_identifier=dbt_identifier,
            old_database=old_database,
            old_schema=old_schema,
            old_identifier=old_identifier,
            primary_keys=primary_keys,
            exclude_columns=exclude_columns,
            summarize=summarize
        ) }}

        {{ audit_helper_ext.get_validation_count(
            dbt_identifier=dbt_identifier,
            old_database=old_database,
            old_schema=old_schema,
            old_identifier=old_identifier
        ) }}

    {% endif %}

{% endmacro %}


{# Row count by group #}
{%- macro validation_count_by_group__stores(group_by) %}

    {% set dbt_identifier = 'stores' %}

    {% set old_database = var('audit_helper__source_database', target.database) %}
    {% set old_schema = audit_helper_ext.get_versioned_name(name=var('audit_helper__source_schema', target.schema)) %}
    {% set old_identifier = 'stores' %}

    {% if execute %}

        {{ audit_helper_ext.get_validation_count_by_group(
            dbt_identifier=dbt_identifier,
            old_database=old_database,
            old_schema=old_schema,
            old_identifier=old_identifier,
            group_by=group_by
        ) }}

    {% endif %}

{% endmacro %}


{# Show column conflicts #}
{%- macro validation_col__stores(columns_to_compare, summarize=true, limit=100) -%}

    {% set dbt_identifier = 'stores' %}

    {% set old_database = var('audit_helper__source_database', target.database) %}
    {% set old_schema = audit_helper_ext.get_versioned_name(name=var('audit_helper__source_schema', target.schema)) %}
    {% set old_identifier = 'stores' %}

    {%- set primary_keys = ['id'] -%}

    {% if execute %}

        {{ audit_helper_ext.show_validation_columns_conflicts(
            dbt_identifier=dbt_identifier,
            old_database=old_database,
            old_schema=old_schema,
            old_identifier=old_identifier,
            primary_keys=primary_keys,
            columns_to_compare=columns_to_compare,
            summarize=summarize,
            limit=limit
        ) }}

    {% endif %}

{% endmacro %}
