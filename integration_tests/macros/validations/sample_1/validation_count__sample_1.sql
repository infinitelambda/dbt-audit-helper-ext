{%- macro validation_count__sample_1() %}

    {% set dbt_identifier = '???' %}

    {% set old_database = '???' %}
    {% set old_schema = '???' %}
    {% set old_identifier = '???' %}

    {% if execute %}

        {{ audit_helper_ext.get_validation_count(
            dbt_identifier=dbt_identifier,
            old_database=old_database,
            old_schema=old_schema,
            old_identifier=old_identifier
        ) }}

    {% endif %}

{% endmacro %}
