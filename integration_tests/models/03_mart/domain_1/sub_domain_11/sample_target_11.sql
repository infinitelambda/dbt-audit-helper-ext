{{
  config(
    materialized = 'table',
    unique_key = ['id11']
  )
}}

select 1 as col
