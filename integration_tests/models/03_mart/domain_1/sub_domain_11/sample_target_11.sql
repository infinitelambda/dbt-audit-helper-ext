{{
  config(
    materialized = 'table',
    unique_key = ['id11'],
    audit_helper__source_database = 'DB',
    audit_helper__source_schema = 'SC'
  )
}}

select 1 as col