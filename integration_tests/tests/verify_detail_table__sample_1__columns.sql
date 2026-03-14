-- Verify the detail table has the correct columns:
-- - Required metadata + audit columns are present
-- - Expected data columns (derived dynamically) are present
-- - Excluded columns are absent
-- Returns failing rows if any column expectation is violated.

{% set log_relation = ref('validation_log') %}

{% set metadata_columns = [
    'DBT_AUDIT_EXT_MART_TABLE', 'DBT_AUDIT_EXT_DATE_OF_PROCESS',
    'DBT_AUDIT_EXT_JOB_RUN_URL'
] %}

{% set audit_columns = [
    'DBT_AUDIT_IN_A', 'DBT_AUDIT_IN_B', 'DBT_AUDIT_ROW_STATUS',
    'DBT_AUDIT_SURROGATE_KEY', 'DBT_AUDIT_PK_ROW_NUM',
    'DBT_AUDIT_ROW_HASH', 'DBT_AUDIT_NUM_ROWS_IN_STATUS',
    'DBT_AUDIT_SAMPLE_NUMBER'
] %}

{% set validation_config = get_validation_config__sample_1() %}
{% set dbt_relation = ref(validation_config.dbt_identifier) %}
{% set forbidden_columns = validation_config.exclude_columns | map('upper') | list %}

{% if execute %}
  {% set old_relation = adapter.get_relation(
      database=validation_config.old_database,
      schema=validation_config.old_schema,
      identifier=validation_config.old_identifier
  ) %}
  {% set data_columns = audit_helper_ext.get_intersecting_columns(
      old_relation, dbt_relation, validation_config.exclude_columns
  ) | map('upper') | list %}
  {% set required_columns = metadata_columns + data_columns + audit_columns %}
{% else %}
  {% set required_columns = metadata_columns + audit_columns %}
{% endif %}

with actual_columns as (
    select upper(column_name) as column_name
    from {{ log_relation.database }}.information_schema.columns
    where table_catalog = upper('{{ log_relation.database }}')
      and table_schema = upper('{{ log_relation.schema }}')
      and table_name = 'VALIDATION_LOG_DETAIL__SAMPLE_1'
),

missing_required as (
    {% for col in required_columns %}
    select '{{ col }}' as column_name, 'missing_required' as violation
    where not exists (select 1 from actual_columns where column_name = '{{ col }}')
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
),

present_forbidden as (
    {% for col in forbidden_columns %}
    select '{{ col }}' as column_name, 'present_forbidden' as violation
    where exists (select 1 from actual_columns where column_name = '{{ col }}')
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
)

select * from missing_required
union all
select * from present_forbidden
