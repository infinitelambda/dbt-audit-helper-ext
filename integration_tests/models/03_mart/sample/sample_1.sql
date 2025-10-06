{{
  config(
    materialized = 'table',
    unique_key = ['name']
  )
}}

--to compare vs {{ ref("sample_source_1") }}
select 'Alice'   AS name,  29 AS age,  'New York'      AS city, '99.0'  as life_time_value union all
select 'Bob',              35,        'San Francisco',          '150.5' as life_time_value union all
select 'Charlie',          23,        'Chicago',                '200.0' as life_time_value union all
select 'Diana',            28,        'Houston',                '75.0'  as life_time_value union all
select 'Eve',              46,        'Phoenix',                '120.0' as life_time_value union all 
select 'Frank',            37,        'Philadelphia',           '180.0' as life_time_value union all
select 'Grace',            32,        'San Antonio',            '110.0' as life_time_value union all
select 'Hannah',           31,        'San Diego',              '130.0' as life_time_value union all
select 'Ian',              25,        'Austin',                 '160.0' as life_time_value union all
select 'Jack',             40,        'Seattle',                '140.0' as life_time_value
