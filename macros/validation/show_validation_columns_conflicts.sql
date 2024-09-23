{% macro show_validation_columns_conflicts(
    dbt_identifier,
    old_database,
    old_schema,
    old_identifier,
    primary_keys,
    columns_to_compare=[],
    summarize=true,
    limit=none
) %}
  {{ return(adapter.dispatch('show_validation_columns_conflicts', 'audit_helper_ext')
      (
        dbt_identifier=dbt_identifier,
        old_database=old_database,
        old_schema=old_schema,
        old_identifier=old_identifier,
        primary_keys=primary_keys,
        columns_to_compare=columns_to_compare,
        summarize=summarize,
        limit=limit
      )
  ) }}
{% endmacro %}


{% macro default__show_validation_columns_conflicts(
    dbt_identifier,
    old_database,
    old_schema,
    old_identifier,
    primary_keys,
    columns_to_compare,
    summarize,
    limit
) %}

    {% set old_relation = adapter.get_relation(
      database=old_database,
      schema=old_schema,
      identifier=old_identifier
    ) %}
    {% set dbt_relation = ref(dbt_identifier) %}

    {% set audit_query = audit_helper_ext.show_columns_conflicts_sql(
        a_relation=old_relation,
        b_relation=dbt_relation,
        primary_keys=primary_keys,
        columns_to_compare=columns_to_compare,
        summarize=summarize,
        limit=limit
    ) %}

    {% if execute %}
      {{ log('ℹ️  Those columns are included in the comparison: ' ~ columns_to_compare, true) }}

      {% set audit_results = audit_helper_ext.run_audit_query(audit_query, summarize) %}

    {% endif %}

{% endmacro %}
