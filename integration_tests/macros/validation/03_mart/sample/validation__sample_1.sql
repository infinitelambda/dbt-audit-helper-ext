{# Row count #}
{%- macro validation_count__sample_1() %}

    {% set dbt_identifier = 'sample_1' %}

    {% set old_database = var('audit_helper__source_database', target.database) %}
    {% set old_schema = audit_helper_ext.get_versioned_name(name=var('audit_helper__source_schema', target.schema)) %}
    {% set old_identifier = 'sample_1' %}

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
{%- macro validation_all_col__sample_1(summarize=true) -%}

    {% set dbt_identifier = 'sample_1' %}

    {% set old_database = var('audit_helper__source_database', target.database) %}
    {% set old_schema = audit_helper_ext.get_versioned_name(name=var('audit_helper__source_schema', target.schema)) %}
    {% set old_identifier = 'sample_1' %}

    {%- set primary_keys = ['name'] -%}
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
{%- macro validation_full__sample_1(summarize=true) -%}

    {% set dbt_identifier = 'sample_1' %}

    {% set old_database = var('audit_helper__source_database', target.database) %}
    {% set old_schema = audit_helper_ext.get_versioned_name(name=var('audit_helper__source_schema', target.schema)) %}
    {% set old_identifier = 'sample_1' %}

    {%- set primary_keys = ['name'] -%}
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
{%- macro validations__sample_1(summarize=true) -%}

    {% set dbt_identifier = 'sample_1' %}

    {% set old_database = var('audit_helper__source_database', target.database) %}
    {% set old_schema = audit_helper_ext.get_versioned_name(name=var('audit_helper__source_schema', target.schema)) %}
    {% set old_identifier = 'sample_1' %}

    {%- set primary_keys = ['name'] -%}
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
