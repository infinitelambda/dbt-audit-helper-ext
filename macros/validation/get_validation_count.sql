{% macro get_validation_count(
    dbt_identifier,
    old_database,
    old_schema,
    old_identifier
) %}
  {{ return(adapter.dispatch('get_validation_count', 'audit_helper_ext')
      (
        dbt_identifier=dbt_identifier,
        old_database=old_database,
        old_schema=old_schema,
        old_identifier=old_identifier
      )
  ) }}
{% endmacro %}


{% macro default__get_validation_count(
    dbt_identifier,
    old_database,
    old_schema,
    old_identifier
) %}
    {% set old_relation = adapter.get_relation(
        database = old_database,
        schema = old_schema,
        identifier = old_identifier
    ) %}
    {% set dbt_relation = ref(dbt_identifier) %}

    {% set audit_query = audit_helper.compare_row_counts(
        a_relation = old_relation,
        b_relation = dbt_relation
    ) %}

    {% if execute %}
      {% set audit_results = audit_helper_ext.run_audit_query(query=audit_query) %}
      {{ audit_helper_ext.log_validation_result('count', audit_results, dbt_identifier, dbt_relation, old_relation) }}
    {% endif %}

{% endmacro %}
