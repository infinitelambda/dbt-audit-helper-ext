{{
  config(
    materialized = 'table',
    unique_key = ['id'],
    meta = {
      "audit_helper__exclude_columns": ["ignored_col"],
      "audit_helper__old_identifier": "sample_expressions_source",
      "audit_helper__unique_key": ["\"id\""],
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
-- Every column is quoted to match the seed's `quote_columns: true`, keeping casing identical
-- on both sides -- unquoted here would fold to `ID` and never match the seed's `"id"`.
select
    1 as "id",
    3.14159265 as "float_value",
    2.71828182845 as "precision_value",
    'hello world' as "text_value",
    100 as "integer_value",
    'alpha' as "MixedCase",
    'differs-on-purpose' as "ignored_col",
    1.14 as "Total Amount"
union all
select
    2 as "id",
    2.99792458 as "float_value",
    1.41421356237 as "precision_value",
    'test data' as "text_value",
    200 as "integer_value",
    'beta' as "MixedCase",
    'differs-on-purpose' as "ignored_col",
    2.24 as "Total Amount"
