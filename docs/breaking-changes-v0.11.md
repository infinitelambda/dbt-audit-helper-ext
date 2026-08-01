# Breaking Changes since v0.11

<!-- markdownlint-disable no-inline-html -->

- [Breaking Changes since v0.11](#breaking-changes-since-v011)
  - [Renamed Columns in `validation_log_report`](#renamed-columns-in-validation_log_report)
  - [Renamed Macros](#renamed-macros)
  - [New Feature: Configurable Schema Validation Checks](#new-feature-configurable-schema-validation-checks)
  - [Schema Mismatch Payload Format](#schema-mismatch-payload-format)

> Upgrading from v0.10.x or earlier? Schema validation went from "data-type-only" to a configurable, multi-attribute drift detector. The renames are mechanical — your downstream queries will need a quick search-and-replace, but nothing too dramatic.

## Renamed Columns in `validation_log_report`

Schema validation now covers more than just data types (column order, text length, numeric precision/scale, nullability). The columns have been renamed so the names actually match what they contain:

| Old Column Name | New Column Name |
|-----------------|-----------------|
| `is_data_type_match` | `is_schema_match` |
| `data_type_mismatches` | `schema_mismatches` |

**Action required**: Rebuild `validation_log_report` and update any downstream model, dashboard, or SQL query that selects from `validation_log_report`:

```bash
dbt run -s validation_log_report
```

If you have BI dashboards or downstream models referencing the old names, update them before re-running the report — otherwise queries will fail with "column does not exist" errors.

## Renamed Macros

The internal macros that build the schema-mismatch payload and gate which schema rows get persisted have been renamed to match the broader scope:

| Old Macro | New Macro |
|-----------|-----------|
| `aggregate_data_type_mismatches_sql` | `aggregate_schema_mismatches_sql` |
| `filter_schema_validation_errors` | `filter_schema_validation_enabled_errors` |

**Action required**: If you've extended the package by dispatching adapter-specific overrides of these macros, rename them in your project. If you've only used them as variables (the default path), no action needed — `validation_log_report.sql` and `get_validation_schema.sql` were updated in lockstep.

## New Feature: Configurable Schema Validation Checks

`schema` validation is no longer hard-coded to "data type or column-presence drift only". A new variable, `audit_helper__schema_validation_checks`, lets you choose which drift attributes to flag — including column order, text length, numeric precision/scale, and nullability.

**Default** (matches pre-v0.11 behaviour, so no migration is required if you're happy with the prior coverage):

```yaml
vars:
  audit_helper__schema_validation_checks:
    - mismatch_data_type
    - in_a_only
```

**Strict mode** (catches every drift attribute the comparator emits):

```yaml
vars:
  audit_helper__schema_validation_checks:
    - mismatch_data_type
    - mismatch_ordinal_position
    - mismatch_character_maximum_length
    - mismatch_numeric_precision
    - mismatch_numeric_scale
    - mismatch_is_nullable
    - in_a_only
```

> **Adapter coverage caveat**: Length / precision / scale / nullable are currently surfaced on Snowflake only. Ordinal position is supported on Snowflake and SQL Server. Other adapters will silently skip those checks until their `compare_relation_columns` macro emits the corresponding `has_*_match` columns — see the [`audit_helper__schema_validation_checks` reference](./dbt-variables-reference.md#audit_helper__schema_validation_checks) for the full coverage matrix.

See the [dbt Variables Reference](./dbt-variables-reference.md#audit_helper__schema_validation_checks) for the full list of available checks and per-adapter coverage.

## Schema Mismatch Payload Format

The `schema_mismatches` column in `validation_log_report` now includes one or more "reasons" per drifted column, joined by `, `. Each reason is one of: `type a → b`, `length a → b`, `precision a → b`, `scale a → b`, `nullable a → b`, `position a → b`.

**Before** (v0.10.x — data-type only):

```text
• age: INTEGER → BIGINT
• status: VARCHAR → null
```

**After** (v0.11+ on Snowflake — multiple reasons per column):

```text
• name: length 50 → 100, nullable NO → YES
• optional_metric: precision 38 → 28, scale 4 → 24
• city: position 3 → 5
• not_exist_in_dbt: type VARCHAR → null
```

**Action required**: If you parse `schema_mismatches` programmatically (regex against the column, BI extracts, etc.), update your parser to handle the new multi-reason-per-line format. The leading `• ` bullet and trailing newline separator are unchanged.

On adapters other than Snowflake, the payload remains data-type-only with the legacy `column: a → b` format until their comparator is extended.
