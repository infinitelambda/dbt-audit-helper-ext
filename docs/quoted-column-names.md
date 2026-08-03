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

Put a view in front of the comparison, alias every awkward name to a quote-free one there, then
validate the view instead of the raw relation. Point `audit_helper__old_identifier` at the view and
every column name in your config becomes a plain unquoted identifier — your expression macros,
`primary_keys`, and `exclude_columns` all stay adapter-agnostic, which is a much better trade than
sprinkling escaped quotes through a config and hoping the next adapter agrees with them.

### Generate the View With `slugify_columns_select`

You don't have to write that alias list yourself. `slugify_columns_select` reads the relation's
actual columns and emits the whole `select`:

```sql
-- models/validation/legacy_orders_normalized.sql
{{ config(materialized = 'view') }}

{{ audit_helper_ext.slugify_columns_select(source('legacy', 'orders')) }}
```

which compiles to:

```sql
select
    "id" as id,
    "MixedCase" as mixed_case,
    "Total Amount ($USD)" as total_amount_usd,
    "order-id" as order_id,
    "CustomerID" as customer_id
from "db"."legacy"."orders"
```

Each original is quoted via `adapter.quote()` on the way in, so it resolves on any adapter, and the
alias is the slug. Nothing to update when the upstream relation gains a column — rebuild the view and
the new one is aliased too.

The relation must already exist when the view compiles, since the column list is read from the
warehouse rather than the manifest. During parsing the macro returns a `select *` placeholder.

### Slug Rules

Handled by [`slugify_column_name`](../macros/utility/column/slugify_column_name.yml), which you can
also call on its own for a single name:

| Original | Alias | Rule |
|----------|-------|------|
| `MixedCase` | `mixed_case` | `camelCase` / `PascalCase` boundaries become `_` |
| `CustomerID` | `customer_id` | acronym runs stay whole, not `customer_i_d` |
| `HTTPStatus` | `http_status` | same, at the front |
| `Total Amount ($USD)` | `total_amount_usd` | runs of non-alphanumerics collapse to a single `_` |
| `order-id` | `order_id` | ditto for punctuation |
| `2024_total` | `_2024_total` | leading digit gets an `_` prefix |

Slugs are ASCII-only. A name made entirely of non-ASCII characters raises a compile-time error rather
than returning an alias that would still need quoting — alias those by hand.

### Collisions

Two different names can slugify to the same string: `Total Amount` and `total_amount` both want
`total_amount`. The first column in relation order keeps the bare slug and later ones get `_2`, `_3`,
skipping any suffix already claimed by another column:

```sql
select
    "Total Amount" as total_amount,
    "total_amount_2" as total_amount_2,
    "total_amount" as total_amount_3   -- _2 was taken, so it lands on _3
from ...
```

Since the tie-break follows column order, a reordered upstream relation can change which column wins
the bare slug. Check which one did before wiring it up as a `primary_keys` entry, and if the ordering
is load-bearing, alias those columns by hand instead.

### Aliasing By Hand

Nothing stops you writing the view yourself — worth doing when you want names that aren't
mechanical slugs, or to pin a collision:

```sql
-- models/validation/legacy_orders_normalized.sql
{{ config(materialized = 'view') }}

select
    "id"           as id,
    "MixedCase"    as mixed_case,
    "Total Amount" as total_amount
from {{ source('legacy', 'orders') }}
```

## Related Gotcha: Case-Sensitive Config Keys

Expression config keys are matched **case-sensitively** against the column names as the warehouse
stores them. On Snowflake, an unquoted `float_value` is stored as `FLOAT_VALUE`, so the config key
must be `FLOAT_VALUE` to match. Normalizing through a view does not change this — pick the casing
your warehouse actually reports.

See [Custom Column Expressions](./custom-column-expressions.md) for how expressions are resolved and
applied.
