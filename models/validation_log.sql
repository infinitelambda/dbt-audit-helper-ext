{{
  config(
    materialized = 'incremental',
    unique_key = ['mart_table', 'dbt_cloud_job_run_url', 'date_of_process', 'validation_type'],
    full_refresh = false,
    on_schema_change = "append_new_columns"
  )
}}

with dummy as (select 1 as col)
select
  cast(null as {{ dbt.type_string() }}) as mart_table,                  -- (PK) Final table name
  cast(null as {{ dbt.type_string() }}) as dbt_cloud_job_run_url,       -- (PK) URL to the job run e.g. https://emea.dbt.com/deploy/<account_id>/projects/<project_id>/runs/<run_id>
  cast(null as {{ dbt.type_timestamp() }}) as date_of_process,          -- (PK) Snapshot start date of data gets proceeded
  cast(null as {{ dbt.type_string() }}) as validation_type,             -- (PK) Validation type
  cast(null as {{ dbt.type_string() }}) as dbt_cloud_job_url,           -- URL to the job e.g. https://emea.dbt.com/deploy/<account_id>/projects/<project_id>/jobs/<job_id>
  cast(null as {{ dbt.type_timestamp() }}) as dbt_cloud_job_start_at,   -- First run started at
  cast(null as {{ dbt.type_string() }}) as old_relation,                -- Full qualified name of the Old table
  cast(null as {{ dbt.type_string() }}) as dbt_relation,                -- Full qualified name of the New table which newly migrated in dbt
  cast(null as {{ dbt.type_string() }}) as mart_path,                   -- Folder path to mart model
  cast(null as {{ dbt.type_string() }}) as validation_result_json,      -- Validation result in json format

from dummy
where 1=0
