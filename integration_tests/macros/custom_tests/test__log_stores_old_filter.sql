{# Runs a filtered `count` validation for sample_1, persisting both old_filter and a #}
{# synthetic dbt_filter, then asserts both round-trip through validation_log. #}
{% macro test__log_stores_old_filter() %}

    {% if not execute %}{{ return(none) }}{% endif %}

    {% set old_relation = adapter.get_relation(
        database=var('audit_helper__source_database', target.database),
        schema=audit_helper_ext.get_versioned_name(name=var('audit_helper__source_schema', target.schema)),
        identifier='sample_1'
    ) %}
    {% set dbt_relation = ref('sample_1') %}
    {% set a_filter = audit_helper_ext.resolve_source_filter('source_upper_bound_expr') %}
    {% set b_filter = audit_helper_ext.resolve_source_filter('dbt_lower_bound_expr') %}

    {% set audit_query = audit_helper_ext.compare_row_counts(
        a_relation=old_relation, b_relation=dbt_relation, a_filter=a_filter, b_filter=b_filter
    ) %}
    {% set audit_results = audit_helper_ext.run_audit_query(query=audit_query) %}

    {{ audit_helper_ext.log_validation_result(
        'count', audit_results, 'sample_1', dbt_relation, old_relation,
        old_filter=a_filter, dbt_filter=b_filter
    ) }}

    {% set check %}
        select old_filter, dbt_filter
        from {{ ref('validation_log') }}
        where mart_table = 'sample_1' and validation_type = 'count'
        order by job_started_at desc
    {% endset %}
    {% set row = run_query(check).rows[0] %}

    {% if row[0] != a_filter %}
        {% do exceptions.raise_compiler_error(
            "❌ validation_log.old_filter: expected '" ~ a_filter ~ "' but got '" ~ row[0] ~ "'."
        ) %}
    {% endif %}
    {{ log("✅ validation_log persisted old_filter == '" ~ row[0] ~ "'", info=true) }}

    {% if row[1] != b_filter %}
        {% do exceptions.raise_compiler_error(
            "❌ validation_log.dbt_filter: expected '" ~ b_filter ~ "' but got '" ~ row[1] ~ "'."
        ) %}
    {% endif %}
    {{ log("✅ validation_log persisted dbt_filter == '" ~ row[1] ~ "'", info=true) }}

{% endmacro %}
