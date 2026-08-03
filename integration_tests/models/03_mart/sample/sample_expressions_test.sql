{{
  config(
    materialized = 'table',
    unique_key = ['id'],
    meta = {
      "audit_helper__exclude_columns": ["ignored_col"],
      "audit_helper__old_identifier": "sample_expressions_source",
      "audit_helper__unique_key": ["id"],
      "audit_helper__custom_column_expressions": {
        "float_value": "round_2dp_expr",
        "precision_value": "round_4dp_expr",
        "text_value": "trim_upper_expr",
        "integer_value": "cast_to_int_expr",
        "not_exist_column": "cast_to_int_expr"
      }
    }
  )
}}

-- Target model with transformed data. Each column is deliberately "wrong" relative to the
-- seed, and the configured expression is what brings the two sides back into agreement.
--
-- Plain unquoted identifiers only: quoted columns are not fully supported (see
-- docs/quoted-column-names.md), so this fixture stays on the supported path.
-- Config keys are uppercase to match how the warehouse stores them.
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
union all
-- Row 3 is the deliberate mismatch. float_value, text_value and integer_value all still
-- reconcile through their expressions; precision_value does not. The seed holds 1.6180,
-- this rounds to 1.6181, and round(_, 4) has no way to bridge a 4th-decimal disagreement.
-- Keeps a real "different" row in the comparison output instead of an all-identical run.
select
    3 as id,
    1.61803398875 as float_value,
    1.61805000000 as precision_value,
    'mismatch row' as text_value,
    300 as integer_value,
    'differs-on-purpose' as ignored_col
