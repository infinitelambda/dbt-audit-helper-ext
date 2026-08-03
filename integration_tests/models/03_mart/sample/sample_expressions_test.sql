{{
  config(
    materialized = 'table',
    unique_key = ['id'],
    meta = {
      "audit_helper__exclude_columns": ["ignored_col"],
      "audit_helper__old_identifier": "sample_expressions_source",
      "audit_helper__unique_key": ["id"],
      "audit_helper__custom_column_expressions": {
        "FLOAT_VALUE": "round_2dp_expr",
        "PRECISION_VALUE": "round_4dp_expr",
        "TEXT_VALUE": "trim_upper_expr",
        "INTEGER_VALUE": "cast_to_int_expr"
      }
    }
  )
}}

-- Target model with transformed data. Each column is deliberately "wrong" relative to the
-- seed, and the configured expression is what brings the two sides back into agreement.
--
-- Plain unquoted identifiers only: quoted columns are not fully supported (see
-- docs/custom-column-expressions.md#quoted-column-names), so this fixture stays on the
-- supported path. Config keys are uppercase to match how the warehouse stores them.
select
    1 as id,
    3.14159265 as float_value,
    2.71828182845 as precision_value,
    'hello world' as text_value,
    100 as integer_value,
    'differs-on-purpose' as ignored_col
union all
select
    2 as id,
    2.99792458 as float_value,
    1.41421356237 as precision_value,
    'test data' as text_value,
    200 as integer_value,
    'differs-on-purpose' as ignored_col
