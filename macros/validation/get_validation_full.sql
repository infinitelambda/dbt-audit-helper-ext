{% macro get_validation_full(
    dbt_identifier,
    old_database,
    old_schema,
    old_identifier,
    primary_keys,
    exclude_columns=[],
    summarize=true,
    package_name=none,
    old_filter=none,
    dbt_filter=none
) %}
  {{ return(adapter.dispatch('get_validation_full', 'audit_helper_ext')
      (
        dbt_identifier=dbt_identifier,
        old_database=old_database,
        old_schema=old_schema,
        old_identifier=old_identifier,
        primary_keys=primary_keys,
        exclude_columns=exclude_columns,
        summarize=summarize,
        package_name=package_name,
        old_filter=old_filter,
        dbt_filter=dbt_filter
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
    summarize=true,
    package_name=none,
    old_filter=none,
    dbt_filter=none
) %}

    {% set old_relation = adapter.get_relation(
        database = old_database,
        schema = old_schema,
        identifier = old_identifier
    ) %}
    {% set dbt_relation = ref(dbt_identifier) %}

    {% set a_filter = audit_helper_ext.resolve_relation_filter(old_filter, side='a') %}
    {% set b_filter = audit_helper_ext.resolve_relation_filter(dbt_filter, side='b') %}

    {% set column_specs = audit_helper_ext.get_column_specs(
        a_relation=old_relation,
        b_relation=dbt_relation,
        exclude_columns=exclude_columns,
        package_name=package_name
    ) %}
    {% set a_query = audit_helper_ext.build_filtered_query(relation=old_relation, column_specs=column_specs, filter=a_filter) %}
    {% set b_query = audit_helper_ext.build_filtered_query(relation=dbt_relation, column_specs=column_specs, filter=b_filter) %}

    {% set audit_query = audit_helper.compare_queries(
        a_query=a_query,
        b_query=b_query,
        primary_key=dbt_utils.generate_surrogate_key(primary_keys),
        summarize=summarize,
        limit=100
    ) %}

    {% set column_expressions = audit_helper_ext.format_column_expressions(column_specs) %}

    {% if execute %}
      {{ log('ℹ️  Those columns are excluded from the comparison: ' ~ exclude_columns, true) }}
      {% if a_filter %}{{ log('ℹ️  Filter on source (A): ' ~ audit_helper_ext.get_log_value(a_filter), true) }}{% endif %}
      {% if b_filter %}{{ log('ℹ️  Filter on dbt (B): ' ~ audit_helper_ext.get_log_value(b_filter), true) }}{% endif %}
      {% if column_expressions %}{{ log('ℹ️  Column expressions applied: ' ~ audit_helper_ext.get_log_value(column_expressions), true) }}{% endif %}

      {% set audit_results = audit_helper_ext.run_audit_query(audit_query, summarize) %}
      {% if summarize %}
        {{ audit_helper_ext.log_validation_result(
            type='full',
            result=audit_results,
            dbt_identifier=dbt_identifier,
            dbt_relation=dbt_relation,
            old_relation=old_relation,
            old_filter=a_filter,
            dbt_filter=b_filter,
            column_expressions=column_expressions
        ) }}
      {% else %}
        {% if audit_results and audit_results | length > 0 %}
          {# Print sample query #}
          {% set sample_query = audit_helper_ext.generate_sample_query(
              old_relation=old_relation,
              dbt_relation=dbt_relation,
              primary_keys=primary_keys,
              exclude_columns=exclude_columns,
              audit_results=audit_results,
              a_filter=a_filter,
              b_filter=b_filter,
              column_specs=column_specs
          ) %}
          {% if sample_query %}
            {{ log('💡 Investigation query suggestion (first discrepancy row):', true) }}
            {{ audit_helper_ext.log_debug(sample_query) }}
          {% endif %}

          {# Print lineage information #}
          {% set lineage_paths = audit_helper_ext.get_upstream_lineage(dbt_identifier, package_name=package_name) %}
          {% set lineage_output = audit_helper_ext.format_lineage(lineage_paths) %}
            {{ log('💡 Upstream Lineage:', true) }}
          {{ audit_helper_ext.log_debug(lineage_output) }}
        {% endif %}

        {# Persist row-level detail (only when feature is enabled) #}
        {% if var('audit_helper__store_comparison_data', false) %}
          {{ audit_helper_ext.log_validation_detail_result(
              dbt_identifier=dbt_identifier,
              old_relation=old_relation,
              dbt_relation=dbt_relation,
              primary_keys=primary_keys,
              exclude_columns=exclude_columns,
              store_matched_rows=var('audit_helper__store_matched_rows', false),
              a_filter=a_filter,
              b_filter=b_filter
          ) }}
        {% endif %}
      {% endif %}
    {% endif %}

{% endmacro %}
