# Custom Column Expressions

<!-- markdownlint-disable no-inline-html -->
- [Custom Column Expressions](#custom-column-expressions)
  - [Overview](#overview)
  - [Why Use Custom Column Expressions?](#why-use-custom-column-expressions)
  - [Configuration](#configuration)
    - [Basic Usage](#basic-usage)
    - [Configuration Priority](#configuration-priority)
  - [Common Expression Macros](#common-expression-macros)
  - [Creating Custom Expression Macros](#creating-custom-expression-macros)
    - [Simple Custom Macro](#simple-custom-macro)
    - [Database-Specific Implementation](#database-specific-implementation)
  - [How It Works](#how-it-works)
  - [Examples](#examples)
    - [Example 1: Floating-Point Precision](#example-1-floating-point-precision)
    - [Example 2: String Normalization](#example-2-string-normalization)
    - [Example 3: Multiple Transformations](#example-3-multiple-transformations)
  - [Limitations](#limitations)
    - [Quoted Column Names](#quoted-column-names)
  - [Troubleshooting](#troubleshooting)

## Overview

Sometimes columns can't be compared directly in their raw form. Think of floating-point values that differ
slightly due to precision differences between systems, or string values that need normalization before
comparison. Custom column expressions let you apply SQL transformations to specific columns during validation,
ensuring apples-to-apples comparisons.

## Why Use Custom Column Expressions?

This feature is particularly useful when:

- **Migration Projects**: Floating-point precision differs between source and target systems (e.g., moving from Informatica to dbt, or Oracle to Snowflake)
- **Statistical Functions**: Different platforms calculate statistical functions with slight variations
- **String Normalization**: Case sensitivity or whitespace handling differs between systems
- **Type Conversions**: Columns need casting for accurate comparison
- **Data Quality**: Standardizing formats before comparison (dates, phone numbers, etc.)

## Configuration

### Basic Usage

Configure custom expressions in your model's `meta` block:

```sql
{{
  config(
    meta = {
      "audit_helper__custom_column_expressions": {
        "float_column": "round_2dp_expr",
        "precise_column": "round_4dp_expr",
        "text_column": "trim_upper_expr"
      }
    }
  )
}}

select
  id,
  3.14159 as float_column,
  2.71828182 as precise_column,
  'hello world' as text_column
from source_table
```

### Configuration Priority

The package checks for custom expressions in the following order:

1. **Meta config** (preferred): `config.meta.audit_helper__custom_column_expressions`
2. **Direct config** (legacy): `config.audit_helper__custom_column_expressions`

This allows backward compatibility while encouraging the use of meta blocks for better organization.

## Common Expression Macros

The package ships no expression macros — you define them in your own project, which keeps the
transformations under your control rather than at the mercy of a package upgrade. These are the
ones worth copying first:

```sql
{% macro round_2dp_expr(column_name) %}
  {{ return('round(' ~ column_name ~ ', 2)') }}
{% endmacro %}

{% macro trim_upper_expr(column_name) %}
  {{ return('upper(trim(' ~ column_name ~ '))') }}
{% endmacro %}

{% macro cast_to_int_expr(column_name) %}
  {% set int_type = 'int' if target.type == 'sqlserver' else 'integer' %}
  {{ return('cast(' ~ column_name ~ ' as ' ~ int_type ~ ')') }}
{% endmacro %}
```

| Macro | Description | Example Input | Example Output |
|-------|-------------|---------------|----------------|
| `round_2dp_expr` | Round to 2 decimal places | `3.14159` | `3.14` |
| `round_4dp_expr` | Round to 4 decimal places | `2.718281828` | `2.7183` |
| `cast_to_int_expr` | Cast to integer type | `3.14` | `3` |
| `trim_upper_expr` | Trim whitespace and uppercase | `'  hello  '` | `'HELLO'` |
| `trim_lower_expr` | Trim whitespace and lowercase | `'  WORLD  '` | `'world'` |

A working set lives in `integration_tests/macros/validation/config/column_expressions/`.

## Creating Custom Expression Macros

Need something more specific? Creating your own expression macros is straightforward!

### Simple Custom Macro

Create a macro in your own project that takes a column name and returns a SQL expression:

```sql
{% macro my_custom_transform(column_name) %}
  {{ return('my_custom_function(' ~ column_name ~ ')') }}
{% endmacro %}
```

The column name arrives already quoted for your adapter, so use it verbatim — no need to quote
it again.

### Database-Specific Implementation

Branch on `target.type` for database-specific SQL:

```sql
{% macro normalize_phone(column_name) %}
  {% if target.type == 'postgres' %}
    {{ return("regexp_replace(" ~ column_name ~ ", '[^0-9]', '', 'g')") }}
  {% else %}
    {{ return("regexp_replace(" ~ column_name ~ ", '[^0-9]', '')") }}
  {% endif %}
{% endmacro %}
```

Then use it in your model config:

```sql
{{
  config(
    meta = {
      "audit_helper__custom_column_expressions": {
        "phone_number": "normalize_phone"
      }
    }
  )
}}
```

## How It Works

When you run validations with custom column expressions:

1. **Configuration Detection**: The validation macro reads the `audit_helper__custom_column_expressions` config from your model's meta block
2. **Expression Resolution**: For each configured column, the specified macro is dynamically resolved and executed
3. **SQL Generation**: The transformed expression is applied to both sides of the comparison, aliased back to the original column name (e.g., `round("column", 2) as "column"`)
4. **Logging**: Debug messages indicate when custom expressions are applied
5. **Fail Fast**: A macro name that doesn't resolve raises a compile-time error rather than
   silently comparing the untransformed column — a quiet fallback would report a clean match
   on data you never actually normalized

The work happens in `get_column_specs`, called by this package's `compare_all_columns` and `compare_relations`
overrides. Columns without a configured expression are selected as plain quoted identifiers.

## Examples

### Example 1: Floating-Point Precision

**Problem**: Your source system stores pi as `3.14159265`, but the target rounds to `3.14`. Direct comparison fails.

**Solution**:

```sql
{{
  config(
    meta = {
      "audit_helper__custom_column_expressions": {
        "pi_value": "round_2dp_expr"
      }
    }
  )
}}

select
  calculation_id,
  3.14 as pi_value  -- Will match source 3.14159265 after rounding
from calculations
```

### Example 2: String Normalization

**Problem**: Source has `'  JOHN DOE  '` but target has `'john doe'`. Case and whitespace differ.

**Solution**:

```sql
{{
  config(
    meta = {
      "audit_helper__custom_column_expressions": {
        "customer_name": "trim_lower_expr"
      }
    }
  )
}}

select
  customer_id,
  lower(trim(full_name)) as customer_name
from customers
```

### Example 3: Multiple Transformations

**Problem**: Multiple columns need different transformations in a single model.

**Solution**:

```sql
{{
  config(
    meta = {
      "audit_helper__exclude_columns": ["surrogate_key"],
      "audit_helper__custom_column_expressions": {
        "revenue": "round_2dp_expr",
        "tax_rate": "round_4dp_expr",
        "product_name": "trim_upper_expr",
        "quantity": "cast_to_int_expr"
      }
    }
  )
}}

select
  surrogate_key,
  round(revenue, 2) as revenue,
  round(tax_rate, 4) as tax_rate,
  upper(trim(product_name)) as product_name,
  cast(quantity as integer) as quantity
from sales
```

## Limitations

### Quoted Column Names

Columns that require quoting to survive as identifiers — mixed case (`MixedCase`), embedded spaces
(`Total Amount`), reserved words, or anything created under `quote_columns: true` — are **not fully
supported** and are best avoided in validated models.

The reason is that several validation paths interpolate configured column names straight into the
generated SQL rather than routing them through `adapter.quote()`. `primary_keys` is the notable one:
`["id"]` reaches Snowflake as bare `id`, which folds to `ID` and never matches a column stored as
lowercase `"id"`. Hand-quoting the config to `["\"id\""]` fixes that particular case, but it hardcodes
Snowflake/Postgres syntax that BigQuery rejects, and it does not help the column-conflict report,
where the alias is built by concatenation and yields the invalid `"col"__a`.

**Workaround** — put a view in front of the comparison and normalize the names there, then validate
the view instead of the raw relation:

```sql
-- models/validation/legacy_orders_normalized.sql
{{ config(materialized = 'view') }}

select
    "id"           as id,
    "MixedCase"    as mixed_case,
    "Total Amount" as total_amount
from {{ source('legacy', 'orders') }}
```

Point `audit_helper__old_identifier` at that view and every column name in your config becomes a
plain unquoted identifier. Your expression macros, `primary_keys`, and `exclude_columns` all stay
adapter-agnostic — which is a much better trade than sprinkling escaped quotes through a config and
hoping the next adapter agrees with them.

A related gotcha worth knowing: expression config keys are matched **case-sensitively** against the
column names as the warehouse stores them. On Snowflake, an unquoted `float_value` is stored as
`FLOAT_VALUE`, so the config key must be `FLOAT_VALUE` to match. Normalizing through a view does not
change this — pick the casing your warehouse actually reports.

## Troubleshooting

**Q: My custom expression isn't being applied. What's wrong?**

Check the run output for
`ℹ️  DEBUG: 🎯 Applying custom expression 'macro_name' to column 'column_name'`, which is logged for
every column an expression is applied to. If that line is missing, the column name in your config
likely doesn't match the column in the relation (matching is case-sensitive), or the column is
listed in `audit_helper__exclude_columns`.

Case is the usual culprit: Snowflake stores an unquoted `float_value` as `FLOAT_VALUE`, so a
lowercase config key silently matches nothing and the raw values flow through untransformed. See
[Quoted Column Names](#quoted-column-names) for the full story.

If the macro name itself doesn't resolve, the run fails with dbt's
`No macro named 'macro_name' found within namespace` — check for a typo, and make sure your macro
is a plain macro rather than an `adapter.dispatch` wrapper.

**Q: Can I use raw SQL expressions instead of macros?**

No. The package intentionally uses macro references (not raw SQL) for:
- Reusability across models
- Easier testing and maintenance
- Keeping model config free of embedded SQL

**Q: Do I need to apply the same transformation in my model SQL?**

It depends on your validation strategy:
- **For migrations**: Apply transformations in your dbt model to match the target format
- **For data quality checks**: You may want to keep the raw data and only transform during validation

**Q: Can I combine custom expressions with exclude columns?**

Absolutely! Both work together:

```sql
{{
  config(
    meta = {
      "audit_helper__exclude_columns": ["created_at", "updated_at"],
      "audit_helper__custom_column_expressions": {
        "price": "round_2dp_expr"
      }
    }
  )
}}
```

**Q: What happens if I reference a column in expressions that's also excluded?**

The exclusion takes precedence. Excluded columns are filtered out before expression resolution, so the custom expression won't be applied.

**Q: Are there performance implications?**

Minimal. The expressions are applied at query time during validation, similar to any other SQL transformation. The overhead is negligible compared to the comparison logic itself.
