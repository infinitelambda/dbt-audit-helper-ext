# Custom Column Expressions

<!-- markdownlint-disable no-inline-html -->
- [Custom Column Expressions](#custom-column-expressions)
  - [Overview](#overview)
  - [Why Use Custom Column Expressions?](#why-use-custom-column-expressions)
  - [Configuration](#configuration)
    - [Basic Usage](#basic-usage)
    - [Configuration Priority](#configuration-priority)
  - [Built-in Expression Macros](#built-in-expression-macros)
    - [Numeric Transformations](#numeric-transformations)
    - [String Transformations](#string-transformations)
  - [Creating Custom Expression Macros](#creating-custom-expression-macros)
    - [Simple Custom Macro](#simple-custom-macro)
    - [Database-Specific Implementation](#database-specific-implementation)
  - [How It Works](#how-it-works)
  - [Examples](#examples)
    - [Example 1: Floating-Point Precision](#example-1-floating-point-precision)
    - [Example 2: String Normalization](#example-2-string-normalization)
    - [Example 3: Multiple Transformations](#example-3-multiple-transformations)
  - [Troubleshooting](#troubleshooting)

## Overview

Sometimes columns can't be compared directly in their raw form. Think of floating-point values that differ slightly due to precision differences between systems, or string values that need normalization before comparison. Custom column expressions let you apply SQL transformations to specific columns during validation, ensuring apples-to-apples comparisons.

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
        "float_column": "audit_helper__round_2dp",
        "precise_column": "audit_helper__round_4dp",
        "text_column": "audit_helper__trim_upper"
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

## Built-in Expression Macros

The package provides several ready-to-use transformation macros out of the box:

### Numeric Transformations

| Macro | Description | Example Input | Example Output |
|-------|-------------|---------------|----------------|
| `audit_helper__round_2dp` | Round to 2 decimal places | `3.14159` | `3.14` |
| `audit_helper__round_4dp` | Round to 4 decimal places | `2.718281828` | `2.7183` |
| `audit_helper__cast_to_int` | Cast to integer type | `3.14` | `3` |

### String Transformations

| Macro | Description | Example Input | Example Output |
|-------|-------------|---------------|----------------|
| `audit_helper__trim_upper` | Trim whitespace and uppercase | `'  hello  '` | `'HELLO'` |
| `audit_helper__trim_lower` | Trim whitespace and lowercase | `'  WORLD  '` | `'world'` |

## Creating Custom Expression Macros

Need something more specific? Creating your own expression macros is straightforward!

### Simple Custom Macro

Create a macro following this pattern:

```sql
{% macro audit_helper__my_custom_transform(column_name) %}
  {{ return(adapter.dispatch('audit_helper__my_custom_transform', 'audit_helper_ext')(column_name)) }}
{% endmacro %}

{% macro default__audit_helper__my_custom_transform(column_name) %}
  my_custom_function({{ column_name }})
{% endmacro %}
```

### Database-Specific Implementation

For database-specific transformations, use adapter-specific macros:

```sql
{% macro audit_helper__normalize_phone(column_name) %}
  {{ return(adapter.dispatch('audit_helper__normalize_phone', 'audit_helper_ext')(column_name)) }}
{% endmacro %}

{% macro default__audit_helper__normalize_phone(column_name) %}
  regexp_replace({{ column_name }}, '[^0-9]', '')
{% endmacro %}

{% macro snowflake__audit_helper__normalize_phone(column_name) %}
  regexp_replace({{ column_name }}, '[^0-9]', '')
{% endmacro %}

{% macro postgres__audit_helper__normalize_phone(column_name) %}
  regexp_replace({{ column_name }}, '[^0-9]', '', 'g')
{% endmacro %}
```

Then use it in your model config:

```sql
{{
  config(
    meta = {
      "audit_helper__custom_column_expressions": {
        "phone_number": "audit_helper__normalize_phone"
      }
    }
  )
}}
```

## How It Works

When you run validations with custom column expressions:

1. **Configuration Detection**: The validation macro reads the `audit_helper__custom_column_expressions` config from your model's meta block
2. **Expression Resolution**: For each configured column, the specified macro is dynamically resolved and executed
3. **SQL Generation**: The transformed expression is applied in the comparison queries (e.g., `round(column, 2) as column`)
4. **Logging**: Debug messages indicate when custom expressions are applied or if macros are not found
5. **Graceful Fallback**: If a macro doesn't exist, the column is compared as-is with a warning logged

The magic happens in the `compare_all_columns` macro from the upstream audit_helper package, which checks for the presence of `get_columns_with_expressions` in the audit_helper_ext context and uses it when available.

## Examples

### Example 1: Floating-Point Precision

**Problem**: Your source system stores pi as `3.14159265`, but the target rounds to `3.14`. Direct comparison fails.

**Solution**:

```sql
{{
  config(
    meta = {
      "audit_helper__custom_column_expressions": {
        "pi_value": "audit_helper__round_2dp"
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
        "customer_name": "audit_helper__trim_lower"
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
        "revenue": "audit_helper__round_2dp",
        "tax_rate": "audit_helper__round_4dp",
        "product_name": "audit_helper__trim_upper",
        "quantity": "audit_helper__cast_to_int"
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

## Troubleshooting

**Q: My custom expression isn't being applied. What's wrong?**

Check the logs for debug messages. You should see:
- `🎯 Applying custom expression 'macro_name' to column 'column_name'` - Success!
- `⚠️  Expression macro 'macro_name' not found for column 'column_name'` - Macro doesn't exist

**Q: Can I use raw SQL expressions instead of macros?**

No. The package intentionally uses macro references (not raw SQL) for:
- Database portability via adapter dispatch
- Reusability across models
- Easier testing and maintenance
- Better error handling and logging

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
        "price": "audit_helper__round_2dp"
      }
    }
  )
}}
```

**Q: What happens if I reference a column in expressions that's also excluded?**

The exclusion takes precedence. Excluded columns are filtered out before expression resolution, so the custom expression won't be applied.

**Q: Are there performance implications?**

Minimal. The expressions are applied at query time during validation, similar to any other SQL transformation. The overhead is negligible compared to the comparison logic itself.
