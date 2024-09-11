{{
  config(
    materialized = 'view',
  )
}}

with latest_log as (

  select *
  from {{ ref('validation_log') }}
  where 1=1
  qualify row_number() over (
    partition by mart_table, dbt_cloud_job_url, date_of_process, validation_type
    order by dbt_cloud_job_start_at desc
  ) = 1

),

extract_data as (

  select
    mart_table,
    array_reverse(split(mart_path, '/'))[1] as mart_folder,
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
          then safe_cast({{ json_field_sql('result', 'total_records') }} as integer)
      end
    ) as old_relation_row_count,
    max(
      case
        when validation_type = 'count'
          and {{ json_field_sql('result', 'relation_name') }} = dbt_relation
          then safe_cast({{ json_field_sql('result', 'total_records') }} as integer)
      end
    ) as dbt_relation_row_count,
    max(
      case
        when validation_type = 'full'
          and {{ json_field_sql('result', 'in_a') }} = 'true'
          and {{ json_field_sql('result', 'in_b') }} = 'true'
          then safe_cast({{ json_field_sql('result', 'count') }} as integer)
      end
    ) as match_count,
    coalesce(
      max(
        case
          when validation_type = 'full'
            and {{ json_field_sql('result', 'in_a') }} = 'true'
            and {{ json_field_sql('result', 'in_b') }} = 'false'
            then safe_cast({{ json_field_sql('result', 'count') }} as integer)
        end
      ), 0) as found_only_in_old_row_count,
    coalesce(
      max(
        case
          when validation_type = 'full'
            and {{ json_field_sql('result', 'in_a') }} = 'false'
            and {{ json_field_sql('result', 'in_b') }} = 'true'
            then safe_cast({{ json_field_sql('result', 'count') }} as integer)
        end
      ), 0) as found_only_in_dbt_row_count,
    string_agg(
      case
      when validation_type = 'upstream_row_count'
        then concat(
            case
              when {{ json_field_sql('result', 'count') }} <> '0' then '✅ '
              when {{ json_field_sql('result', 'count') }} = '0' then '🟡 '
            end,
            {{ json_field_sql('result', 'model_name') }}, ': ',
            {{ json_field_sql('result', 'row_count') }}, ' row(s)'
          )
      end, '\n'
      order by safe_cast({{ json_field_sql('result', 'row_count') }} as integer)
    ) as int_models_row_count,
  from
    latest_log,
    {{ audit_helper_ext.json_table_sql('validation_result_json') }} as result
  group by all

),

calculate_exp as (

  select
    *,
    {% set match_rate_percentage -%}
      cast(match_count as numeric) / (match_count + found_only_in_old_row_count + found_only_in_dbt_row_count) * 100
    {%- endset %}
    {{ match_rate_percentage }} as match_rate_percentage,
    case when old_relation_row_count = dbt_relation_row_count then 'Yes ✅' else 'No 🟡' end as is_count_match,
    case
      when {{ match_rate_percentage }} = 100 then '✅'
      when {{ match_rate_percentage }} >= 99 and {{ match_rate_percentage }} < 100 then '🟡'
      else '❌'
    end as match_rate_status,

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
  int_models_row_count,

from calculate_exp
