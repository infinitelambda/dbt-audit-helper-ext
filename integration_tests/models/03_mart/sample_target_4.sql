{{
  config(
    materialized = 'table',
    unique_key = ['id4']
  )
}}

select 1 as col
