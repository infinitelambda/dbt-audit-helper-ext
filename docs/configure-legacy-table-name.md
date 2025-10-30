# Configure Legacy Table Name

<!-- markdownlint-disable no-inline-html -->

- [Configure Legacy Table Name](#configure-legacy-table-name)
  - [Overview](#overview)
  - [The Default Assumption](#the-default-assumption)
  - [When You Need Custom Configuration](#when-you-need-custom-configuration)
  - [Configuration Methods](#configuration-methods)
    - [Method 1: Model-Level Config (Explicit Override)](#method-1-model-level-config-explicit-override)
    - [Method 2: Global Naming Convention (Systematic)](#method-2-global-naming-convention-systematic)
  - [Common Naming Convention Patterns](#common-naming-convention-patterns)
    - [Add Prefix](#add-prefix)
    - [Add Suffix](#add-suffix)
    - [Replace Prefix](#replace-prefix)
    - [Remove Prefix](#remove-prefix)
    - [Complex Pattern Matching](#complex-pattern-matching)
  - [Resolution Priority](#resolution-priority)

## Overview

When validating your dbt models against legacy tables, `audit-helper-ext` needs to know which legacy table corresponds to which dbt model. In a perfect world (spoiler: we don't live there), your dbt model names would match your legacy table names exactly. But reality is messier, and that's where this configuration comes in handy.

## The Default Assumption

By default, we assume you're doing a straightforward lift-and-shift migration where:

```
dbt model name = legacy table name
```

For example:
- `customers.sql` → validates against Legacy `customers` table
- `orders.sql` → validates against Legacy `orders` table
- `dim_products.sql` → validates against Legacy `dim_products` table

If this assumption holds true for your project, you're golden! No additional configuration needed. Skip the rest of this guide and go grab a coffee ☕

## When You Need Custom Configuration

Real-world scenarios rarely follow perfect patterns. You might need custom configuration when:

- **Legacy tables have prefixes/suffixes**: Your legacy system uses `dim_customers`, but your dbt model is simply `customers`
- **Naming convention changes**: You're modernizing from `CUSTOMER_DIM` to `dim_customers`
- **One-off exceptions**: Most tables match, but a few rebels have completely different names (looking at you, `legacy_cust_master` vs `customers`)
- **Systematic patterns**: All legacy tables follow a pattern like `tbl_*` or `*_legacy`

The good news? We've got you covered with two flexible configuration methods.

## Configuration Methods

### Method 1: Model-Level Config (Explicit Override)

Perfect for one-off exceptions or when only a handful of models need special treatment.

Add the `audit_helper__old_identifier` config to your model's `meta` block (preferred):

```sql
-- models/03_mart/customers.sql
{{
  config(
    materialized='table',
    meta={
      'audit_helper__old_identifier': 'dim_customers',
      'audit_helper__unique_key': ['customer_id'],
      'audit_helper__exclude_columns': ['created_at', 'updated_at']
    }
  )
}}

select * from {{ ref('raw_customers') }}
```

**Alternative (legacy format - still supported):**
```sql
-- models/03_mart/customers.sql
{{
  config(
    materialized='table',
    audit_helper__old_identifier='dim_customers'
  )
}}

select * from {{ ref('raw_customers') }}
```

**Result**: Your dbt model `customers` will be validated against the legacy table `dim_customers`.

**Why use `meta` block?**
- Better organization: All audit helper configs in one place
- Future-proof: Aligns with dbt best practices for metadata
- Prevents collision: Avoids potential conflicts with other dbt config keys
- Still flexible: Both formats work, choose what fits your style

**When to use this:**
- Specific models with unique legacy names
- Exceptions to a broader naming pattern
- Quick overrides without touching global configuration

### Method 2: Global Naming Convention (Systematic)

The DRY approach for when your legacy tables follow a systematic naming pattern. Define once, apply everywhere.

Add to your `dbt_project.yml`:

```yaml
vars:
  audit_helper__old_identifier_naming_convention:
    pattern: '^(.*)$'          # Regex pattern to match model name
    replacement: 'dim_\\1'     # Replacement pattern for legacy table name
```

**Result**: All models automatically map with the prefix:
- `customers` → `dim_customers`
- `products` → `dim_products`
- `orders` → `dim_orders`

**When to use this:**
- Legacy tables follow a consistent pattern
- Migrating an entire warehouse with systematic naming
- You value DRY principles and your sanity

## Common Naming Convention Patterns

Here are battle-tested patterns for common scenarios:

### Add Prefix

Transform `customers` → `dim_customers`:

```yaml
audit_helper__old_identifier_naming_convention:
  pattern: '^(.*)$'
  replacement: 'dim_\\1'
```

### Add Suffix

Transform `customers` → `customers_legacy`:

```yaml
audit_helper__old_identifier_naming_convention:
  pattern: '^(.*)$'
  replacement: '\\1_legacy'
```

### Replace Prefix

Transform `dim_customers` → `legacy_customers`:

```yaml
audit_helper__old_identifier_naming_convention:
  pattern: '^(dim|fact)_(.*)$'
  replacement: 'legacy_\\2'
```

This pattern only affects models starting with `dim_` or `fact_`.

### Remove Prefix

Transform `stg_customers` → `customers`:

```yaml
audit_helper__old_identifier_naming_convention:
  pattern: '^(stg|int)_(.*)$'
  replacement: '\\2'
```

Perfect for when you've added dbt-style prefixes but legacy tables have none.

### Complex Pattern Matching

Transform `CUSTOMER_DIM` → `dim_customers` (uppercase to lowercase with structure change):

```yaml
audit_helper__old_identifier_naming_convention:
  pattern: '^([A-Z]+)_DIM$'
  replacement: 'dim_\\L\\1'
```

**Note**: The `\\L` modifier converts the captured group to lowercase (Python regex flavor).

## Resolution Priority

When determining the legacy table name, the system follows this priority order:

1. **Model Meta Config** (Highest Priority)
   - Checks for `config.meta.audit_helper__old_identifier` first
   - **NEW preferred format** for better organization
   - Example: `meta={'audit_helper__old_identifier': 'legacy_customers'}`

2. **Model Direct Config** (High Priority)
   - Checks for `config.audit_helper__old_identifier`
   - Legacy format, still fully supported
   - Example: `audit_helper__old_identifier='legacy_customers'`

3. **Naming Convention** (Medium Priority)
   - Applies the `audit_helper__old_identifier_naming_convention` pattern
   - Use for systematic transformations across all models
   - Example: Pattern to add `dim_` prefix to all model names

4. **Fallback** (Lowest Priority)
   - Returns the model name as-is (the lift-and-shift assumption)
   - This is the default behavior when nothing else is configured

**Example**: If you define both a global naming convention AND a model-level config, the model-level config wins. This lets you set a pattern for 95% of your models and override the troublesome 5% individually.

**Note on Unique Keys and Exclude Columns**: The same priority system applies to:
- `audit_helper__unique_key` (fallback: `config.unique_key`)
- `audit_helper__exclude_columns`
- `audit_helper__source_database`
- `audit_helper__source_schema`

All these configs benefit from being organized in the `meta` block for cleaner, more maintainable code.

_🐞 Enjoy the Bug, finally!_
