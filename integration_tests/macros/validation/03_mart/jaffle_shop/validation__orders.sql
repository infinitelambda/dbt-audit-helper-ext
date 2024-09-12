{# Row count #}
{%- macro validation_count__orders() %}

    {% set dbt_identifier = 'orders' %}

    {% set old_database = target.database %}
    {% set old_schema = target.schema ~ '__' ~ audit_helper_ext.date_of_process(true) %}
    {% set old_identifier = 'orders' %}

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
{%- macro validation_all_col__orders(summarize=true) -%}

    {% set dbt_identifier = 'orders' %}

    {% set old_database = target.database %}
    {% set old_schema = target.schema ~ '__' ~ audit_helper_ext.date_of_process(true) %}
    {% set old_identifier = 'orders' %}

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
{%- macro validation_full__orders(summarize=true) -%}

    {% set dbt_identifier = 'orders' %}

    {% set old_database = target.database %}
    {% set old_schema = target.schema ~ '__' ~ audit_helper_ext.date_of_process(true) %}
    {% set old_identifier = 'orders' %}

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
{%- macro validations__orders(summarize=true) -%}

    {% set dbt_identifier = 'orders' %}

    {% set old_database = target.database %}
    {% set old_schema = target.schema ~ '__' ~ audit_helper_ext.date_of_process(true) %}
    {% set old_identifier = 'orders' %}

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
