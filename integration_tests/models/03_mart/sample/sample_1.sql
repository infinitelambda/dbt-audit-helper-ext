{# Resolve the source seed relation so the pre_hook can pin NOT NULL on it #}
{# (seeds can't carry NOT NULL — needed to demo nullable drift in the report). #}
{# clone_schema runs on-run-end with `create or replace`, so the constraint #}
{# propagates into the versioned `audit_helper_ext_seed__YYYYMMDD.sample_1`. #}
{%- set seed_database = var('audit_helper__source_database', target.database) -%}
{%- set seed_schema = var('audit_helper__source_schema', target.schema) -%}
{%- set seed_fqn = seed_database ~ '.' ~ seed_schema ~ '.sample_1' -%}

{{
  config(
    materialized = 'table',
    pre_hook = [
      "alter table " ~ seed_fqn ~ " alter column name set not null"
    ],
    meta = {
      "audit_helper__exclude_columns": ["sample_1_sk", "not_exist_in_dbt", "optional_metric"],
      "audit_helper__old_identifier": "sample_1",
      "audit_helper__unique_key": ["name"],
    }
  )
}}

with source_data as (
    --to compare vs {{ ref("sample_target_1") }}
    --to compare vs {{ ref("sample_target_2") }}
    select 'Alice'   AS name,  29 AS age,  'New York'      AS city, 99.0  as life_time_value union all
    select 'Bob',              35,        'San Francisco',          150.5 union all
    select 'Charlie',          23,        'Chicago',                200.0 union all
    select 'Diana',            28,        'Houston',                75.0  union all
    select 'Eve',              46,        'Phoenix',                120.0 union all
    select 'Frank',            37,        'Philadelphia',           180.0 union all
    select 'Grace',            32,        'San Antonio',            110.0 union all
    select 'Hannah',           31,        'San Diego',              130.0 union all
    select 'Ian',              25,        'Austin',                 160.0 union all
    select 'Jack',             40,        'Seattle',                140.0
    {# materialized='table' means is_incremental() is always false, so gate the #}
    {# Day-2 Jack2 row on the explicit FULL_REFRESH flag instead. #}
    {% if not flags.FULL_REFRESH %}
    union all
    select 'Jack2',            79,        'San Jose',                999.0
    {% endif %}
)

{# Deliberate schema drift vs the seed (renders into validation_log_report.schema_mismatches): #}
{#   - NAME:            length 50 → 100, nullable NO → YES   (varchar(100) cast + CTAS drops NOT NULL) #}
{#   - CITY:            position 3 → 5                       (moved to the end) #}
{#   - OPTIONAL_METRIC: precision 38 → 28, scale 4 → 24      (tighter precision, wider scale) #}
{#   - NOT_EXIST_IN_DBT: type VARCHAR → null                  (in_a_only — present in seed only) #}
select
    {{ dbt_utils.generate_surrogate_key(["name"]) }} as sample_1_sk,
    {% if target.type == "snowflake" -%}
      {# iff() forces nullable inference so the column is NULL on the dbt side, demonstrating nullable drift #}
      iff(true, cast(name as varchar(100)), null) as name,
    {%- else %}
      cast(name as {{ dbt.type_string() }}) as name,
    {%- endif %}
    {% if target.type == "databricks" -%}
      cast(age as bigint) as age,
    {%- else %}
      age,
    {%- endif %}
    {% if target.type in ["biquery", "snowflake", "databricks"] -%}
      cast(life_time_value as {{ dbt.type_string() }}) as life_time_value,
    {%- else %}
      cast(life_time_value as {{ dbt.type_float() }}) as life_time_value,
    {%- endif %}
    {% if target.type == "snowflake" -%}
      cast(1.000000000000000000000000 as numeric(28,24)) as optional_metric,
    {%- else %}
      cast(1.0 as {{ dbt.type_float() }}) as optional_metric,
    {%- endif %}
    city

from source_data
