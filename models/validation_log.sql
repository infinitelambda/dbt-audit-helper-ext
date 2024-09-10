{{
  config(
    materialized = 'incremental',
    unique_key = [
      'mart_table',
      'dbt_cloud_job_run_url',
      'date_of_process',
      'validation_type'
    ],
    on_schema_change = "append_new_columns"
    full_refresh = false,
  )
}}

with dummy as (select 1 as col)
select
  cast(null as {{ dbt.type_string() }}) as mart_table,
  cast(null as {{ dbt.type_string() }}) as dbt_cloud_job_run_url,
  cast(null as {{ dbt.type_timestamp() }}) as date_of_process,
  cast(null as {{ dbt.type_string() }}) as validation_type,
  cast(null as {{ dbt.type_string() }}) as dbt_cloud_job_url,
  cast(null as {{ dbt.type_timestamp() }}) as dbt_cloud_job_start_at,
  cast(null as {{ dbt.type_string() }}) as old_relation,
  cast(null as {{ dbt.type_string() }}) as dbt_relation,
  cast(null as {{ dbt.type_string() }}) as mart_path,
  cast(null as {{ dbt.type_string() }}) as validation_result_json,

from dummy
where 1=0
