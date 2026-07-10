{% macro show_validation_columns_conflicts(
    dbt_identifier,
    old_database,
    old_schema,
    old_identifier,
    primary_keys,
    columns_to_compare=[],
    summarize=true,
    limit=none,
    old_filter=none,
    dbt_filter=none
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
        limit=limit,
        old_filter=old_filter,
        dbt_filter=dbt_filter
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
    limit,
    old_filter=none,
    dbt_filter=none
) %}

    {% set old_relation = adapter.get_relation(
      database=old_database,
      schema=old_schema,
      identifier=old_identifier
    ) %}
    {% set dbt_relation = ref(dbt_identifier) %}

    {% set a_filter = audit_helper_ext.resolve_source_filter(old_filter) %}
    {% set b_filter = audit_helper_ext.resolve_source_filter(dbt_filter) %}

    {% set audit_query = audit_helper_ext.show_columns_conflicts_sql(
        a_relation=old_relation,
        b_relation=dbt_relation,
        primary_keys=primary_keys,
        columns_to_compare=columns_to_compare,
        summarize=summarize,
        limit=limit,
        a_filter=a_filter,
        b_filter=b_filter
    ) %}

    {% if execute %}
      {{ log('ℹ️  Those columns are included in the comparison: ' ~ columns_to_compare, true) }}
      {% if a_filter %}{{ log('ℹ️  Filter on source (A): ' ~ a_filter, true) }}{% endif %}
      {% if b_filter %}{{ log('ℹ️  Filter on dbt (B): ' ~ b_filter, true) }}{% endif %}

      {% set audit_results = audit_helper_ext.run_audit_query(audit_query, summarize) %}

    {% endif %}

{% endmacro %}
