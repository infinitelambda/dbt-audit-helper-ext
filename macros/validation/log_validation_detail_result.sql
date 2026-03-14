{% macro log_validation_detail_result(
    dbt_identifier,
    old_relation,
    dbt_relation,
    primary_keys,
    exclude_columns,
    store_matched_rows
) %}
  {{ return(adapter.dispatch('log_validation_detail_result', 'audit_helper_ext')(
    dbt_identifier=dbt_identifier,
    old_relation=old_relation,
    dbt_relation=dbt_relation,
    primary_keys=primary_keys,
    exclude_columns=exclude_columns,
    store_matched_rows=store_matched_rows
  )) }}
{% endmacro %}


{% macro default__log_validation_detail_result(
    dbt_identifier,
    old_relation,
    dbt_relation,
    primary_keys,
    exclude_columns,
    store_matched_rows
) %}

  {# Build target relation in the same database/schema as validation_log #}
  {% set log_relation = ref('validation_log') %}
  {% set detail_relation = api.Relation.create(
      database=log_relation.database,
      schema=log_relation.schema,
      identifier='validation_log_detail__' ~ dbt_identifier,
      type='table'
  ) %}

  {% set columns = audit_helper_ext.get_intersecting_columns(old_relation, dbt_relation, exclude_columns) %}

  {# Build the comparison query via upstream macro #}
  {% set sample_limit = var('audit_helper__store_comparison_data_limit', none) %}
  {% set comparison_query = audit_helper.compare_and_classify_relation_rows(
      a_relation=old_relation,
      b_relation=dbt_relation,
      primary_key_columns=primary_keys,
      columns=columns,
      sample_limit=sample_limit
  ) %}

  {# Wrap with metadata columns and row filtering #}
  {% set detail_query %}
    select
      '{{ dbt_identifier }}' as mart_table,
      'https://{{ env_var("DBT_CLOUD_HOST_URL", var("audit_helper__dbt_cloud_host_url", "emea.dbt.com")) }}/deploy/{{ env_var("DBT_CLOUD_ACCOUNT_ID", "core") }}/projects/{{ env_var("DBT_CLOUD_PROJECT_ID", "core") }}/runs/{{ env_var("DBT_CLOUD_RUN_ID", "core") }}' as dbt_cloud_job_run_url,
      '{{ audit_helper_ext.date_of_process() }}' as date_of_process,
      cast('{{ run_started_at }}' as {{ dbt.type_timestamp() }}) as dbt_cloud_job_start_at,
      __comparison.*
    from (
      {{ comparison_query }}
    ) __comparison
    {% if not store_matched_rows %}
    where dbt_audit_row_status != 'identical'
    {% endif %}
  {% endset %}

  {# Execute CREATE OR REPLACE TABLE #}
  {% if execute %}
    {% do audit_helper_ext.create_or_replace_table_as(
        relation=detail_relation,
        sql=detail_query,
        config={}
    ) %}
    {{ log("ℹ️  Validation detail of " ~ dbt_identifier ~ " was persisted at " ~ detail_relation, info=True) }}
  {% endif %}

{% endmacro %}
