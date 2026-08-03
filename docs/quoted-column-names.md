# Quoted Column Names

- [Quoted Column Names](#quoted-column-names)
  - [Overview](#overview)
  - [Why It Breaks](#why-it-breaks)
  - [Workaround: Normalize Through a View](#workaround-normalize-through-a-view)
    - [Generate the View With `slugify_columns_select`](#generate-the-view-with-slugify_columns_select)
    - [Slug Rules](#slug-rules)
    - [Collisions](#collisions)
    - [Aliasing By Hand](#aliasing-by-hand)
  - [Related Gotcha: Case-Sensitive Config Keys](#related-gotcha-case-sensitive-config-keys)

## Overview

Columns that require quoting to survive as identifiers — mixed case (`MixedCase`), embedded spaces
(`Total Amount`), reserved words, or anything created under `quote_columns: true` — are **not fully
supported** and are best avoided in validated models.

This applies across the validation macros: `audit_helper__unique_key` / `primary_keys`,
`audit_helper__exclude_columns`, `audit_helper__custom_column_expressions`, and the column-conflict
report.

## Why It Breaks

Several validation paths interpolate configured column names straight into the generated SQL rather
than routing them through `adapter.quote()`. `primary_keys` is the notable one: `["id"]` reaches
Snowflake as bare `id`, which folds to `ID` and never matches a column stored as lowercase `"id"`.

Hand-quoting the config to `["\"id\""]` fixes that particular case, but it hardcodes
Snowflake/Postgres syntax that BigQuery rejects, and it does not help the column-conflict report,
where the alias is built by concatenation and yields the invalid `"col"__a`.

## Workaround: Normalize Through a View

Put a view in front of the comparison and normalize the names there, then validate the view instead
of the raw relation:

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

### Doing It Automatically

Writing that alias list by hand gets tedious past a handful of columns, and stale the moment the
upstream relation gains one. The `slugify_columns_select` macro generates it from the relation's
actual columns:

```sql
-- models/validation/legacy_orders_normalized.sql
{{ config(materialized = 'view') }}

{{ audit_helper_ext.slugify_columns_select(source('legacy', 'orders')) }}
```

which compiles to exactly the shape above:

```sql
select
    "id" as id,
    "MixedCase" as mixed_case,
    "Total Amount ($USD)" as total_amount_usd,
    "CustomerID" as customer_id
from "db"."legacy"."orders"
```

Names are lowercased, `camelCase` boundaries become underscores (`CustomerID` → `customer_id`), and
runs of anything else collapse to a single `_`. Two columns that slugify to the same name are
deduplicated with `_2`, `_3` suffixes in column order — so if `Total Amount` and `total_amount` both
live in the relation, check which one won the bare slug before wiring up `primary_keys`. When the
tie-break matters, alias those particular columns by hand.

The relation must already exist when the view compiles, since the column list is read from the
warehouse rather than the manifest.

## Related Gotcha: Case-Sensitive Config Keys

Expression config keys are matched **case-sensitively** against the column names as the warehouse
stores them. On Snowflake, an unquoted `float_value` is stored as `FLOAT_VALUE`, so the config key
must be `FLOAT_VALUE` to match. Normalizing through a view does not change this — pick the casing
your warehouse actually reports.

See [Custom Column Expressions](./custom-column-expressions.md) for how expressions are resolved and
applied.
