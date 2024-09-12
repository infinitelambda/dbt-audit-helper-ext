{{
  config(
    materialized = 'table',
    unique_key = ['name']
  )
}}

--to compare vs {{ ref("sample_source_1") }}
select 'Alice' AS name, 29 AS age, 'New York' AS city
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
