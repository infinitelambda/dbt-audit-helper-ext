{% macro get_validation_all_col(
    dbt_identifier,
    old_database,
    old_schema,
    old_identifier,
    primary_keys,
    exclude_columns=[],
    summarize=true,
    old_filter=none,
    dbt_filter=none
) %}
  {{ return(adapter.dispatch('get_validation_all_col', 'audit_helper_ext')
      (
        dbt_identifier=dbt_identifier,
        old_database=old_database,
        old_schema=old_schema,
        old_identifier=old_identifier,
        primary_keys=primary_keys,
        exclude_columns=exclude_columns,
        summarize=summarize,
        old_filter=old_filter,
        dbt_filter=dbt_filter
      )
  ) }}
{% endmacro %}


{% macro default__get_validation_all_col(
    dbt_identifier,
    old_database,
    old_schema,
    old_identifier,
    primary_keys,
    exclude_columns,
    summarize,
    old_filter=none,
    dbt_filter=none
) %}

    {% set old_relation = adapter.get_relation(
      database=old_database,
      schema=old_schema,
      identifier=old_identifier
    ) %}
    {% set dbt_relation = ref(dbt_identifier) %}

    {% set a_filter = audit_helper_ext.resolve_relation_filter(old_filter, side='a') %}
    {% set b_filter = audit_helper_ext.resolve_relation_filter(dbt_filter, side='b') %}

    {% set audit_query = audit_helper_ext.compare_all_columns(
        a_relation=old_relation,
        b_relation=dbt_relation,
        exclude_columns=exclude_columns,
        primary_key=dbt_utils.generate_surrogate_key(primary_keys),
        summarize=summarize,
        a_filter=a_filter,
        b_filter=b_filter
    ) %}

    {% if execute %}
      {{ log('ℹ️  Those columns are excluded from the comparison: ' ~ exclude_columns, true) }}
      {% if a_filter %}{{ log('ℹ️  Filter on source (A): ' ~ audit_helper_ext.get_log_value(a_filter), true) }}{% endif %}
      {% if b_filter %}{{ log('ℹ️  Filter on dbt (B): ' ~ audit_helper_ext.get_log_value(b_filter), true) }}{% endif %}

      {% set audit_results = audit_helper_ext.run_audit_query(audit_query, summarize) %}
      {% if summarize %}
        {{ audit_helper_ext.log_validation_result('all_col', audit_results, dbt_identifier, dbt_relation, old_relation, old_filter=a_filter, dbt_filter=b_filter) }}
      {% endif %}
    {% endif %}

{% endmacro %}
