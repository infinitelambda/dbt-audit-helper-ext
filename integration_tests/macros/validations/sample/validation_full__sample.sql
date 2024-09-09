{%- macro validation__transaction_cont_devis(summarize=true) -%}

    {% set dbt_identifier = '???' %}

    {% set old_database = '???' %}
    {% set old_schema = '???' %}
    {% set old_identifier = '???' %}

    {%- set primary_keys = ['???'] -%}
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
