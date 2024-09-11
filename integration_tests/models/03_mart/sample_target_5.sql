{{
  config(
    materialized = 'table',
    unique_key = ['id5']
  )
}}

select 1 as col
