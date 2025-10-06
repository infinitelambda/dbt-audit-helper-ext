{# Validation config #}
{%- macro get_validation_config__sample_1() -%}

    {% set dbt_identifier = 'sample_1' %}

    {% set old_database = var('audit_helper__source_database', target.database) %}
    {% set old_schema = audit_helper_ext.get_versioned_name(name=var('audit_helper__source_schema', target.schema)) %}
    {% set old_identifier = audit_helper_ext.get_old_identifier_name('sample_1') %}

    {%- set primary_keys = ['name'] -%}
    {%- set exclude_columns = ["sample_1_sk", "not_exist_in_dbt"] -%}

    {{ log('👀  ' ~ old_database ~ '.' ~ old_schema ~ '.' ~ old_identifier ~ ' vs. ' ~ ref(dbt_identifier), true) if execute }}
    {{ return(namespace(
            dbt_identifier=dbt_identifier,
            old_database=old_database,
            old_schema=old_schema,
            old_identifier=old_identifier,
            primary_keys=primary_keys,
            exclude_columns=exclude_columns,
    )) }}

{% endmacro %}


{# Row count #}
{%- macro validation_count__sample_1() %}

    {% set validation_config = get_validation_config__sample_1() %}
    {% if execute %}

        {{ audit_helper_ext.get_validation_count(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier
        ) }}

    {% endif %}

{% endmacro %}


{# Schema diff validation #}
{%- macro validation_schema__sample_1() -%}

    {% set validation_config = get_validation_config__sample_1() %}
    {% if execute %}

        {{ audit_helper_ext.get_validation_schema(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier
        ) }}

    {% endif %}

{% endmacro %}


{# Column comparison #}
{%- macro validation_all_col__sample_1(summarize=true) -%}

    {% set validation_config = get_validation_config__sample_1() %}
    {% if execute %}

        {{ audit_helper_ext.get_validation_all_col(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier,
            primary_keys=validation_config.primary_keys,
            exclude_columns=validation_config.exclude_columns,
            summarize=summarize
        ) }}

    {% endif %}

{% endmacro %}


{# Row-by-row validation #}
{%- macro validation_full__sample_1(summarize=true) -%}

    {% set validation_config = get_validation_config__sample_1() %}
    {% if execute %}

        {{ audit_helper_ext.get_validation_full(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier,
            primary_keys=validation_config.primary_keys,
            exclude_columns=validation_config.exclude_columns,
            summarize=summarize
        ) }}

    {% endif %}

{% endmacro %}


{# Validations for All #}
{%- macro validations__sample_1(summarize=true) -%}

    {% set validation_config = get_validation_config__sample_1() %}
    {% if execute %}

        {{ audit_helper_ext.get_upstream_row_count(
            dbt_identifier=validation_config.dbt_identifier
        ) }}

        {{ audit_helper_ext.get_validation_schema(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier
        ) }}

        {{ audit_helper_ext.get_validation_full(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier,
            primary_keys=validation_config.primary_keys,
            exclude_columns=validation_config.exclude_columns,
            summarize=summarize
        ) }}

        {{ audit_helper_ext.get_validation_count(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier
        ) }}

    {% endif %}

{% endmacro %}


{# Row count by group #}
{%- macro validation_count_by_group__sample_1(group_by) %}

    {% set validation_config = get_validation_config__sample_1() %}
    {% if execute %}

        {{ audit_helper_ext.get_validation_count_by_group(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier,
            group_by=group_by
        ) }}

    {% endif %}

{% endmacro %}


{# Show column conflicts #}
{%- macro validation_col__sample_1(columns_to_compare, summarize=true, limit=100) -%}

    {% set validation_config = get_validation_config__sample_1() %}
    {% if execute %}

        {{ audit_helper_ext.show_validation_columns_conflicts(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier,
            primary_keys=validation_config.primary_keys,
            columns_to_compare=columns_to_compare,
            summarize=summarize,
            limit=limit
        ) }}

    {% endif %}

{% endmacro %}
