{{
  config(
    materialized = 'table',
    unique_key = ['id'],
    meta = {
      "audit_helper__exclude_columns": ["id"],
      "audit_helper__old_identifier": "sample_expressions_source",
      "audit_helper__unique_key": ["id"],
      "audit_helper__custom_column_expressions": {
        "float_value": "round_2dp_expr",
        "precision_value": "round_4dp_expr",
        "text_value": "trim_upper_expr",
        "integer_value": "cast_to_int_expr",
        "MixedCase": "trim_upper_expr",
        "Total Amount": "round_1dp_expr"
      }
    }
  )
}}

-- Target model with transformed data. `MixedCase` and `Total Amount` need quoting to survive
-- as identifiers, so they cover the adapter.quote() path in the expression resolver.
select
    1 as id,
    3.14159265 as float_value,
    2.71828182845 as precision_value,
    'hello world' as text_value,
    100 as integer_value,
    'alpha' as "MixedCase",
    1.14 as "Total Amount"
union all
select
    2 as id,
    2.99792458 as float_value,
    1.41421356237 as precision_value,
    'test data' as text_value,
    200 as integer_value,
    'beta' as "MixedCase",
    2.24 as "Total Amount"
