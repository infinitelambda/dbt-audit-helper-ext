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
    dbt_filter=none,
    package_name=none
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
        dbt_filter=dbt_filter,
        package_name=package_name
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
    dbt_filter=none,
    package_name=none
) %}

    {% set old_relation = adapter.get_relation(
      database=old_database,
      schema=old_schema,
      identifier=old_identifier
    ) %}
    {% set dbt_relation = ref(dbt_identifier) %}

    {% set a_filter = audit_helper_ext.resolve_relation_filter(old_filter, side='a') %}
    {% set b_filter = audit_helper_ext.resolve_relation_filter(dbt_filter, side='b') %}

    {% set column_specs = audit_helper_ext.get_column_specs(
        a_relation=old_relation,
        b_relation=dbt_relation,
        package_name=package_name
    ) %}

    {% set audit_query = audit_helper_ext.show_columns_conflicts_sql(
        a_relation=old_relation,
        b_relation=dbt_relation,
        primary_keys=primary_keys,
        columns_to_compare=columns_to_compare,
        summarize=summarize,
        limit=limit,
        a_filter=a_filter,
        b_filter=b_filter,
        column_specs=column_specs
    ) %}

    {# Only report expressions that reach this comparison: specs cover the whole relation,
       while the drill-down looks at the columns the caller asked for. #}
    {% set primary_keys_csv, primary_keys_list = audit_helper_ext.convert_to_str_and_list(primary_keys) %}
    {% set columns_to_compare_csv, columns_to_compare_list = audit_helper_ext.convert_to_str_and_list(columns_to_compare) %}
    {% set applied_specs = audit_helper_ext.filter_column_specs(column_specs, primary_keys_list + columns_to_compare_list) %}
    {% set column_expressions = audit_helper_ext.format_column_expressions(applied_specs) %}

    {% if execute %}
      {{ log('ℹ️  Those columns are included in the comparison: ' ~ columns_to_compare, true) }}
      {% if a_filter %}{{ log('ℹ️  Filter on source (A): ' ~ audit_helper_ext.get_log_value(a_filter), true) }}{% endif %}
      {% if b_filter %}{{ log('ℹ️  Filter on dbt (B): ' ~ audit_helper_ext.get_log_value(b_filter), true) }}{% endif %}
      {% if column_expressions %}{{ log('ℹ️  Column expressions applied: ' ~ audit_helper_ext.get_log_value(column_expressions), true) }}{% endif %}

      {% set audit_results = audit_helper_ext.run_audit_query(audit_query, summarize) %}

    {% endif %}

{% endmacro %}
