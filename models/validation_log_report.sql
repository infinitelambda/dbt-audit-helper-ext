{{
  config(
    materialized = 'view',
    database = var('audit_helper__database', target.database),
    schema = var('audit_helper__schema', target.schema)
  )
}}

with latest_log as (

  {{ audit_helper_ext.deduplicate_with_row_number_sql(
      source_relation=ref('validation_log').
      partition_by_fields=['mart_table', 'dbt_cloud_job_url', 'date_of_process', 'validation_type'],
      order_by_fields=['dbt_cloud_job_start_at desc']
  ) }}

),

extract_data as (

  select
    mart_table,
    {{ audit_helper_ext.extract_mart_folder_sql("mart_path") }} as mart_folder,
    dbt_cloud_job_url,
    dbt_cloud_job_run_url,
    date_of_process,
    dbt_relation,
    max(old_relation) as old_relation,
    min(dbt_cloud_job_start_at) as dbt_cloud_job_start_at,
    max(
      case
        when validation_type = 'count'
          and {{ json_field_sql('result', 'relation_name') }} = old_relation
          then {{ safe_cast_sql() }}({{ json_field_sql('result', 'total_records') }} as integer)
      end
    ) as old_relation_row_count,
    max(
      case
        when validation_type = 'count'
          and {{ json_field_sql('result', 'relation_name') }} = dbt_relation
          then {{ safe_cast_sql() }}({{ json_field_sql('result', 'total_records') }} as integer)
      end
    ) as dbt_relation_row_count,
    max(
      case
        when validation_type = 'full'
          and lower({{ json_field_sql('result', 'in_a') }}) in ('true', '1')
          and lower({{ json_field_sql('result', 'in_b') }}) in ('true', '1')
          then {{ safe_cast_sql() }}({{ json_field_sql('result', 'count') }} as integer)
      end
    ) as match_count,
    coalesce(
      max(
        case
          when validation_type = 'full'
            and lower({{ json_field_sql('result', 'in_a') }}) in ('true', '1')
            and lower({{ json_field_sql('result', 'in_b') }}) in ('false', '0')
            then {{ safe_cast_sql() }}({{ json_field_sql('result', 'count') }} as integer)
        end
      ), 0) as found_only_in_old_row_count,
    coalesce(
      max(
        case
          when validation_type = 'full'
            and lower({{ json_field_sql('result', 'in_a') }}) in ('false', '0')
            and lower({{ json_field_sql('result', 'in_b') }}) in ('true', '1')
            then {{ safe_cast_sql() }}({{ json_field_sql('result', 'count') }} as integer)
        end
      ), 0) as found_only_in_dbt_row_count,
    {{ audit_helper_ext.aggregate_upstream_row_count_sql() }} as upstream_row_count,

  from
    latest_log 
    {{ audit_helper_ext.join_json_table_sql("validation_result_json") }} as result
  group by
    mart_table,
    mart_path,
    dbt_cloud_job_url,
    dbt_cloud_job_run_url,
    date_of_process,
    dbt_relation

),

calculate_exp as (

  select
    *,
    {% set match_rate_percentage -%}
      cast(match_count as numeric) / (match_count + found_only_in_old_row_count + found_only_in_dbt_row_count) * 100
    {%- endset %}
    {{ match_rate_percentage }} as match_rate_percentage,
    case
      when old_relation_row_count = dbt_relation_row_count then {{ audit_helper_ext.unicode_prefix() }}'Yes ✅'
      else {{ audit_helper_ext.unicode_prefix() }}'No 🟡'
    end as is_count_match,
    case
      when {{ match_rate_percentage }} = 100 then {{ audit_helper_ext.unicode_prefix() }}'✅'
      when {{ match_rate_percentage }} >= 99 and {{ match_rate_percentage }} < 100 then {{ audit_helper_ext.unicode_prefix() }}'🟡'
      else {{ audit_helper_ext.unicode_prefix() }}'❌'
    end as match_rate_status

  from extract_data

)

select
  mart_table,
  mart_folder,
  dbt_cloud_job_url,
  dbt_cloud_job_run_url,
  date_of_process,
  dbt_cloud_job_start_at,
  old_relation,
  dbt_relation,
  old_relation_row_count,
  dbt_relation_row_count,
  is_count_match,
  match_rate_percentage,
  match_rate_status,
  match_count,
  found_only_in_old_row_count,
  found_only_in_dbt_row_count,
  upstream_row_count

from calculate_exp
