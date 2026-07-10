{% macro get_validation_count_by_group(
    dbt_identifier,
    old_database,
    old_schema,
    old_identifier,
    group_by,
    old_filter=none,
    dbt_filter=none
) %}
  {{ return(adapter.dispatch('get_validation_count_by_group', 'audit_helper_ext')
      (
        dbt_identifier=dbt_identifier,
        old_database=old_database,
        old_schema=old_schema,
        old_identifier=old_identifier,
        group_by=group_by,
        old_filter=old_filter,
        dbt_filter=dbt_filter
      )
  ) }}
{% endmacro %}


{% macro default__get_validation_count_by_group(
    dbt_identifier,
    old_database,
    old_schema,
    old_identifier,
    group_by,
    old_filter=none,
    dbt_filter=none
) %}
    {% set old_relation = adapter.get_relation(
        database = old_database,
        schema = old_schema,
        identifier = old_identifier
    ) %}
    {% set dbt_relation = ref(dbt_identifier) %}

    {% set a_filter = audit_helper_ext.resolve_source_filter(old_filter) %}
    {% set b_filter = audit_helper_ext.resolve_source_filter(dbt_filter) %}

    {% set audit_query = audit_helper_ext.compare_row_counts_by_group_sql(
        a_relation = old_relation,
        b_relation = dbt_relation,
        group_by = group_by,
        a_filter = a_filter,
        b_filter = b_filter
    ) %}

    {% if execute %}
      {% if a_filter %}{{ log('ℹ️  Filter on source (A): ' ~ a_filter, true) }}{% endif %}
      {% if b_filter %}{{ log('ℹ️  Filter on dbt (B): ' ~ b_filter, true) }}{% endif %}
      {% set audit_results = audit_helper_ext.run_audit_query(query=audit_query) %}
      {{ audit_helper_ext.log_validation_result('count_by_group', audit_results, dbt_identifier, dbt_relation, old_relation, old_filter=a_filter, dbt_filter=b_filter) }}
    {% endif %}

{% endmacro %}
