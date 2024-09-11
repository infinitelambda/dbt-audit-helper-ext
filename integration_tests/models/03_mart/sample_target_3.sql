{{
  config(
    materialized = 'table',
    unique_key = ['id3']
  )
}}

select 1 as col
