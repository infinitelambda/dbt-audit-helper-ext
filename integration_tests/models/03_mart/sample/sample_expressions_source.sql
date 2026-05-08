{{
  config(
    materialized = 'table',
    unique_key = ['id']
  )
}}

-- Source model with slightly different precision/formatting
-- When compared using expressions, these should match
select
    1 as id,
    3.14 as float_value,
    2.7183 as precision_value,
    '  HELLO WORLD  ' as text_value,
    100 as integer_value
union all
select
    2 as id,
    3.00 as float_value,
    1.4142 as precision_value,
    '  TEST DATA  ' as text_value,
    200 as integer_value
