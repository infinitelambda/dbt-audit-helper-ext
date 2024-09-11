{{
  config(
    materialized = 'table',
    unique_key = ['name'],
    audit_helper__source_schema = 'audit_helper_ext__20240909'
  )
}}

--to compare vs {{ ref("sample_source_1") }}
select 'Alice' AS Name, 29 AS Age, 'New York' AS City
union all
select 'Bob', 35, 'San Francisco'
union all
select 'Charlie', 23, 'Chicago'
union all
select 'Diana', 28, 'Houston'
union all
select 'Eve', 46, 'Phoenix'
union all
select 'Frank', 37, 'Philadelphia'
union all
select 'Grace', 32, 'San Antonio'
union all
select 'Hannah', 31, 'San Diego'
union all
select 'Ian', 25, 'Austin'
union all
select 'Jack', 40, 'Seattle'
