{% macro get_validation_count_by_group(
    dbt_identifier,
    old_database,
    old_schema,
    old_identifier,
    group_by
) %}
  {{ return(adapter.dispatch('get_validation_count_by_group', 'audit_helper_ext')
      (
        dbt_identifier=dbt_identifier,
        old_database=old_database,
        old_schema=old_schema,
        old_identifier=old_identifier,
        group_by=group_by
      )
  ) }}
{% endmacro %}


{% macro default__get_validation_count_by_group(
    dbt_identifier,
    old_database,
    old_schema,
    old_identifier,
    group_by
) %}
    {% set old_relation = adapter.get_relation(
        database = old_database,
        schema = old_schema,
        identifier = old_identifier
    ) %}
    {% set dbt_relation = ref(dbt_identifier) %}

    {% set audit_query = audit_helper_ext.compare_row_counts_by_group_sql(
        a_relation = old_relation,
        b_relation = dbt_relation,
        group_by = group_by
    ) %}

    {% if execute %}
      {% set audit_results = audit_helper_ext.run_audit_query(query=audit_query) %}
      {{ audit_helper_ext.log_validation_result('count_by_group', audit_results, dbt_identifier, dbt_relation, old_relation) }}
    {% endif %}

{% endmacro %}
