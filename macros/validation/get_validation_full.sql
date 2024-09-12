{% macro get_validation_full(
    dbt_identifier,
    old_database,
    old_schema,
    old_identifier,
    primary_keys,
    exclude_columns=[],
    summarize=true
) %}
  {{ return(adapter.dispatch('get_validation_full', 'audit_helper_ext')
      (
        dbt_identifier=dbt_identifier,
        old_database=old_database,
        old_schema=old_schema,
        old_identifier=old_identifier,
        primary_keys=primary_keys,
        exclude_columns=exclude_columns,
        summarize=summarize
      )
  ) }}
{% endmacro %}


{% macro default__get_validation_full(
    dbt_identifier,
    old_database,
    old_schema,
    old_identifier,
    primary_keys,
    exclude_columns=[],
    summarize=true
) %}

    {% set old_relation = adapter.get_relation(
        database = old_database,
        schema = old_schema,
        identifier = old_identifier
    ) %}
    {% set dbt_relation = ref(dbt_identifier) %}

    {% set audit_query = audit_helper.compare_relations(
        a_relation = old_relation,
        b_relation = dbt_relation,
        exclude_columns = exclude_columns,
        primary_key = dbt_utils.generate_surrogate_key(primary_keys),
        summarize = summarize,
        limit = 100
    ) %}

    {% if execute %}
      {{ log('ℹ️  Those columns are excluded from the comparison: ' ~ exclude_columns, true) }}

      {% set audit_results = audit_helper_ext.run_audit_query(audit_query, summarize) %}
      {% if summarize %}
        {{ audit_helper_ext.log_validation_result('full', audit_results, dbt_identifier, dbt_relation, old_relation) }}
      {% endif %}
    {% endif %}

{% endmacro %}
