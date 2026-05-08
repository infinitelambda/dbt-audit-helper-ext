{{
  config(
    materialized = 'table',
    unique_key = ['id'],
    meta = {
      "audit_helper__exclude_columns": ["id"],
      "audit_helper__old_identifier": "sample_expressions_source",
      "audit_helper__unique_key": ["id"],
      "audit_helper__custom_column_expressions": {
        "float_value": "audit_helper__round_2dp",
        "precision_value": "audit_helper__round_4dp",
        "text_value": "audit_helper__trim_upper"
      }
    }
  )
}}

-- Target model with transformed data
select
    1 as id,
    3.14159265 as float_value,
    2.71828182845 as precision_value,
    'hello world' as text_value,
    100 as integer_value
union all
select
    2 as id,
    2.99792458 as float_value,
    1.41421356237 as precision_value,
    'test data' as text_value,
    200 as integer_value
