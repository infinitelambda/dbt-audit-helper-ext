{{
  config(
    materialized = 'incremental',
    unique_key = ['name'],
    audit_helper__exclude_columns=["sample_1_sk"],
    audit_helper__old_identifier="sample_1"
  )
}}

with source_data as (
    --to compare vs {{ ref("sample_target_1") }}
    --to compare vs {{ ref("sample_target_2") }}
    select 'Alice'   AS name,  29 AS age,  'New York'      AS city, '99.0'  as life_time_value union all
    select 'Bob',              35,        'San Francisco',          '150.5' union all
    select 'Charlie',          23,        'Chicago',                '200.0' union all
    select 'Diana',            28,        'Houston',                '75.0'  union all
    select 'Eve',              46,        'Phoenix',                '120.0' union all
    select 'Frank',            37,        'Philadelphia',           '180.0' union all
    select 'Grace',            32,        'San Antonio',            '110.0' union all
    select 'Hannah',           31,        'San Diego',              '130.0' union all
    select 'Ian',              25,        'Austin',                 '160.0' union all
    select 'Jack',             40,        'Seattle',                '140.0'
    {% if is_incremental() %}
    union all
    select 'Jack2',            79,        'San Jose',                '999.0'
    {% endif %}
)

select
    {{ dbt_utils.generate_surrogate_key(["name"]) }} as sample_1_sk,
    *
from source_data