{{
  config(
    materialized = 'table',
    unique_key = ['id2']
  )
}}

select 1 as col
