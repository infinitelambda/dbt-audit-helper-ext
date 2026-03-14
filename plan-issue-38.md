# Plan: Persist Row-by-Row Comparison Detail

## Table of Contents

- [Problem Statement](#problem-statement)
- [Solution Overview](#solution-overview)
- [Comparison Macro](#comparison-macro)
- [Table Schema](#table-schema)
- [Configuration](#configuration)
- [New and Modified Files](#new-and-modified-files)
- [Data Flow](#data-flow)
- [Persistence Strategy](#persistence-strategy)
- [Scope](#scope)
- [Testing](#testing)
- [Trade-offs](#trade-offs)

## Problem Statement

Currently, `get_validation_full` with `summarize=true` logs only aggregated counts to `validation_log` (e.g., "100 matched, 3 in A only, 2 in B only") as a JSON summary. The actual row-level detail — all columns from both tables, with matched/mismatched status — is never persisted. When `summarize=false`, detailed rows are printed to logs (limited to 100) and discarded.

There is no way to investigate historical mismatches without re-running the comparison.

### Requirements

- Persist **all** columns from the comparison (old table columns + dbt table columns, excluding `exclude_columns`)
- Include row classification status (`identical`, `modified`, `added`, `removed`)
- **Mismatched rows**: always stored when the feature is enabled
- **Matched rows**: opt-in via separate config, off by default
- Global on/off toggle for the entire feature, off by default
- Applies to **row-by-row (full) validation only**

## Solution Overview

Create a **per-mart-table detail table** named `validation_log_detail__<mart_table>` using runtime DDL. Since the table name is dynamic (based on `dbt_identifier`), this cannot be a static dbt model — instead, tables are created/inserted into at runtime, following the same pattern as `clone_relation` / `create_or_replace_table_as`.

### Naming Convention

```
validation_log_detail__customers
validation_log_detail__orders
validation_log_detail__products
```

All created in the same `audit_helper__database` / `audit_helper__schema` as `validation_log`.

### Why Per-Table?

- Cleaner querying — no need to filter by `mart_table` column
- Schema varies per mart table (different column sets) — separate tables avoid schema conflicts
- Smaller, focused tables rather than one massive shared table

## Comparison Macro

### Using `audit_helper.compare_and_classify_relation_rows`

Instead of `audit_helper.compare_relations(summarize=false)`, we use `compare_and_classify_relation_rows` from `dbt-audit-helper` (available since v0.12.0, already the minimum version in `packages.yml`). **No version upgrade needed.**

This macro provides richer row classification out of the box:

```
audit_helper.compare_and_classify_relation_rows(
    a_relation=old_relation,
    b_relation=dbt_relation,
    primary_key_columns=primary_keys,
    columns=<intersecting columns minus excluded>,
    sample_limit=var('audit_helper__store_comparison_data_limit', none)  -- default: no limit
)
```

### Output Columns (Persisted)

The upstream macro produces many `dbt_audit_*` columns, but we only persist the 3 that are useful for investigation. The rest (`dbt_audit_surrogate_key`, `dbt_audit_pk_row_num`, `dbt_audit_row_hash`, `dbt_audit_num_rows_in_status`, `dbt_audit_sample_number`) are internal machinery used during query execution and are excluded from the detail table via an explicit column list in the `SELECT`.

| Column | Description |
|---|---|
| `col_1, col_2, ..., col_n` | All comparison columns from old/dbt tables |
| `dbt_audit_in_a` | `true` if row exists in old table |
| `dbt_audit_in_b` | `true` if row exists in dbt table |
| `dbt_audit_row_status` | Classification: `identical`, `modified`, `added`, `removed`, `nonunique_pk` |

### Classification Logic

```sql
CASE
  WHEN max(dbt_audit_pk_row_num) OVER (PARTITION BY dbt_audit_surrogate_key) > 1 THEN 'nonunique_pk'
  WHEN dbt_audit_in_a AND dbt_audit_in_b THEN 'identical'
  WHEN bool_or(dbt_audit_in_a) OVER (...) AND bool_or(dbt_audit_in_b) OVER (...) THEN 'modified'
  WHEN dbt_audit_in_a THEN 'removed'
  WHEN dbt_audit_in_b THEN 'added'
END
```

### Why This Is Better Than `compare_relations`

| Aspect | `compare_relations(summarize=false)` | `compare_and_classify_relation_rows` |
|---|---|---|
| Row status | `in_a`/`in_b` booleans only | `dbt_audit_row_status` with 5 classifications |
| Matched rows | Filtered out (`WHERE NOT (in_a AND in_b)`) | Included as `identical`, can be filtered |
| Modified detection | Not distinguished from added/removed | Explicit `modified` status (same PK, different values) |
| Duplicate PK detection | None | `nonunique_pk` status |
| Row limit | Baked into SQL (`limit=100`) | `sample_limit` param (set to `none`) |
| Upstream support | Being superseded | Actively maintained, adapter-dispatched |

## Table Schema

```sql
CREATE OR REPLACE TABLE validation_log_detail__<mart_table> AS
SELECT
  -- Metadata columns (added by our macro)
  '<mart_table>'            AS mart_table,
  '<job_run_url>'           AS dbt_cloud_job_run_url,
  '<date_of_process>'       AS date_of_process,
  '<run_started_at>'::TIMESTAMP AS dbt_cloud_job_start_at,

  -- All data columns
  col_1, col_2, ..., col_n,

  -- Classification columns (only 3 from the upstream macro)
  dbt_audit_in_a,
  dbt_audit_in_b,
  dbt_audit_row_status

FROM (
  {{ audit_helper.compare_and_classify_relation_rows(..., sample_limit=var('audit_helper__store_comparison_data_limit', none)) }}
)
WHERE dbt_audit_row_status != 'identical'  -- unless store_matched_rows=true
;
```

### Row Layout Example

The detail table uses a **single column set** (intersecting columns between old and dbt, minus excluded). For `modified` rows, the same primary key appears **twice** — once from each side:

```
| col1 | col2 | dbt_audit_in_a | dbt_audit_in_b | dbt_audit_row_status |
|------|------|----------------|----------------|----------------------|
| foo  | 100  | true           | false          | modified             |  ← old row
| foo  | 200  | false          | true           | modified             |  ← dbt row
| bar  | 300  | true           | false          | removed              |  ← only in old
| baz  | 400  | false          | true           | added                |  ← only in dbt
| qux  | 500  | true           | true           | identical            |  ← matched (only when store_matched_rows=true)
```

It is **not** a side-by-side layout like `old_col1 | dbt_col1`. To compare modified rows, filter by `dbt_audit_row_status = 'modified'` and match on the primary key columns.

## Configuration

### Variables

Three variables control this feature:

```yaml
# dbt_project.yml
vars:
  # audit_helper__store_comparison_data: false        # enable/disable row-level detail persistence (default: false)
  # audit_helper__store_matched_rows: false            # also persist matched rows in detail tables (default: false)
  # audit_helper__store_comparison_data_limit: none    # max rows to persist per detail table (default: none = no limit)
```

### Behavior Matrix

| `store_comparison_data` | `store_matched_rows` | Result |
|---|---|---|
| `false` (default) | _any_ | **Nothing stored** — feature is off |
| `true` | `false` (default) | All non-identical rows (`modified`, `added`, `removed`, `nonunique_pk`) |
| `true` | `true` | All rows including `identical` |

`store_comparison_data` is the **global gate** — when off, `log_validation_detail_result` is never called, so there is zero overhead (no extra queries, no tables created).

`store_matched_rows` is only relevant when the feature is on. Filtering is applied via a `WHERE` clause:

- `false`: `WHERE dbt_audit_row_status != 'identical'`
- `true`: no filter — all rows

## New and Modified Files

### New: `macros/validation/log_validation_detail_result.sql`

New macro with signature:

```jinja
{% macro log_validation_detail_result(
    dbt_identifier,
    old_relation,
    dbt_relation,
    primary_keys,
    exclude_columns,
    store_matched_rows
) %}
```

Logic:

1. Build the target relation using `api.Relation.create()` with identifier `'validation_log_detail__' ~ dbt_identifier`, in the same database/schema as `validation_log`
2. Resolve the intersecting columns between old and dbt relations, minus `exclude_columns`
3. Generate comparison SQL via `audit_helper.compare_and_classify_relation_rows(sample_limit=var('audit_helper__store_comparison_data_limit', none))`
4. Wrap with metadata columns (`mart_table`, `dbt_cloud_job_run_url`, `date_of_process`, `dbt_cloud_job_start_at`)
5. If `store_matched_rows=false`: add `WHERE dbt_audit_row_status != 'identical'`
6. Execute `CREATE OR REPLACE TABLE ... AS SELECT ...` — drop/recreate on every run

The query executes **entirely in-warehouse** — no results are pulled into Jinja, avoiding memory pressure regardless of result size.

### Modified: `macros/validation/get_validation_full.sql`

Add a conditional call to `log_validation_detail_result` in the `summarize=false` branch, gated by `store_comparison_data`. The existing `compare_relations` call for terminal display is **unchanged** — keeps all adapters safe.

```jinja
{% if summarize %}
  {# Existing: log summary to validation_log (unchanged) #}
  {{ audit_helper_ext.log_validation_result('full', audit_results, ...) }}
{% else %}
  {# Existing: compare_relations terminal display (unchanged) #}
  ...
  {# Existing: print sample query, lineage, etc. (unchanged) #}
  ...

  {# New: persist row-level detail (only when feature is enabled) #}
  {% if var('audit_helper__store_comparison_data', false) %}
    {{ audit_helper_ext.log_validation_detail_result(
        dbt_identifier=dbt_identifier,
        old_relation=old_relation,
        dbt_relation=dbt_relation,
        primary_keys=primary_keys,
        exclude_columns=exclude_columns,
        store_matched_rows=var('audit_helper__store_matched_rows', false)
    ) }}
  {% endif %}
{% endif %}
```

### Modified: `dbt_project.yml`

Add commented variables:

```yaml
vars:
  # audit_helper__store_comparison_data: false        # enable row-level detail persistence (default: false)
  # audit_helper__store_matched_rows: false            # also persist matched rows in detail tables (default: false)
  # audit_helper__store_comparison_data_limit: none    # max rows to persist per detail table (default: none = no limit)
```

### No Changes Needed

- `packages.yml` — `dbt-audit-helper >=0.12.0` already includes `compare_and_classify_relation_rows`
- `macros/validation/get_validation_full.sql` (summarize=true branch) — still uses `compare_relations`, untouched
- `macros/validation/get_validation_full.sql` (summarize=false, step 1) — still uses `compare_relations`, untouched
- `macros/utility/discrepancy/generate_sample_query.sql` — untouched (step 1 still produces `IN_A`/`IN_B` columns)
- `models/validation_log.sql` — untouched
- `models/validation_log_report.sql` — untouched
- `scripts/create_validation_macros.py` — detail persistence is internal to `get_validation_full`

## Data Flow

```
get_validation_full(summarize=false)
  │
  ├─ 1. compare_relations(summarize=false, limit=100)        [ALL ADAPTERS]
  │     → run_audit_query() — display to terminal (existing, unchanged)
  │     → print sample query, lineage (existing, unchanged)
  │
  └─ 2. IF audit_helper__store_comparison_data = true:        [SNOWFLAKE ONLY]
        log_validation_detail_result()
          → compare_and_classify_relation_rows(sample_limit=store_comparison_data_limit)
          → CREATE OR REPLACE TABLE
             validation_log_detail__<mart_table>
          → WHERE dbt_audit_row_status != 'identical'  — unless store_matched_rows=true
          → All data columns + dbt_audit_in_a, dbt_audit_in_b, dbt_audit_row_status + metadata
```

When `audit_helper__store_comparison_data = false` (default), step 2 is skipped entirely — no extra query, no table creation, no overhead.

Step 1 uses `compare_relations` (existing behavior, all adapters, unchanged). Step 2 uses `compare_and_classify_relation_rows` (richer classification, Snowflake-only scope, no row limit). This separation ensures zero impact on existing adapter behavior.

## Persistence Strategy

**Drop/recreate on every run** using `CREATE OR REPLACE TABLE ... AS SELECT ...`.

### Why Drop/Recreate Instead of Append?

- **Schema drift safety**: If the mart table's columns change between runs (added/removed/renamed), an `INSERT INTO` would fail due to column mismatch. Drop/recreate handles this automatically.
- **Simpler logic**: No need for schema evolution handling or existence checks.
- **Fit for purpose**: The detail table is an **investigation tool** for the current run's mismatches, not a historical log. Historical summary counts are already tracked in `validation_log` / `validation_log_report`.

### Querying

```sql
-- All mismatches from latest run (the only data in the table)
SELECT *
FROM validation_log_detail__customers
WHERE dbt_audit_row_status != 'identical';

-- Only modified rows (same PK, different values — the most interesting ones)
SELECT *
FROM validation_log_detail__customers
WHERE dbt_audit_row_status = 'modified';

-- Rows only in old table (removed/missing in dbt)
SELECT *
FROM validation_log_detail__customers
WHERE dbt_audit_row_status = 'removed';

-- Rows only in dbt table (newly added, not in old)
SELECT *
FROM validation_log_detail__customers
WHERE dbt_audit_row_status = 'added';

-- All data in the table (when store_matched_rows=true)
SELECT *
FROM validation_log_detail__customers;
```

## Scope

### Current Scope: Snowflake Only

This initial implementation targets **Snowflake** as the only supported adapter. Snowflake natively supports:

- `CREATE OR REPLACE TABLE ... AS SELECT ...`
- `BOOLEAN` type for `dbt_audit_in_a`, `dbt_audit_in_b`
- `hash()` function used by the Snowflake dispatch of `_generate_set_results`

The macro will use `adapter.dispatch()` to allow future adapter-specific overrides, but only the `default__` (Snowflake) implementation will be provided in this phase.

### Dependency

- `dbt-audit-helper >= 0.12.0` (already satisfied — no upgrade needed)
- `compare_and_classify_relation_rows` introduced in v0.12.0

### Future Scope (Not in This Phase)

- BigQuery, Databricks, PostgreSQL, SQL Server adapter support
- A report view over the detail tables (similar to `validation_log_report`)
- Cleanup/retention policies for old detail data

## Testing

Testing follows the existing integration test pattern: `poe init-sf` seeds data, `poe validate-sf` runs `validation__all.sh` which calls `dbt run-operation` macros against real Snowflake tables. No Python tests or dbt unit tests (YAML-based) are used in this project — all validation is end-to-end via `run-operation`.

### Test Strategy

Testing the `log_validation_detail_result` macro requires verifying that:

1. **Detail table is created** with correct name and schema
2. **Data columns** match the intersecting columns (minus excluded)
3. **Classification columns** (`dbt_audit_in_a`, `dbt_audit_in_b`, `dbt_audit_row_status`) are present and correct
4. **Metadata columns** (`mart_table`, `dbt_cloud_job_run_url`, `date_of_process`, `dbt_cloud_job_start_at`) are populated
5. **Row filtering** works — matched rows excluded by default, included when `store_matched_rows=true`
6. **Feature gating** — nothing happens when `audit_helper__store_comparison_data=false`
7. **Row limit** — `audit_helper__store_comparison_data_limit` caps the number of persisted rows

### Test Execution: Reuse `validation__all.sh` + `poe` Tasks

The existing `sample_1` model is ideal for testing because it has known differences between the dbt model and the seed data (different ages, missing/added rows), and it already exercises `validation_full__sample_1(summarize=false)`.

#### Step 1: Add `poe` Tasks for Detail Persistence

Add new `poe` tasks that run `validation_full__sample_1` with the `store_comparison_data` var enabled:

```toml
# pyproject.toml
validate-detail-store = [
  {shell = "cd integration_tests && dbt run-operation validation_full__sample_1 --args \"{'summarize': false}\" --vars \"{'audit_helper__store_comparison_data': true}\""},
]
validate-detail-store-with-matched = [
  {shell = "cd integration_tests && dbt run-operation validation_full__sample_1 --args \"{'summarize': false}\" --vars \"{'audit_helper__store_comparison_data': true, 'audit_helper__store_matched_rows': true}\""},
]
validate-detail-store-with-limit = [
  {shell = "cd integration_tests && dbt run-operation validation_full__sample_1 --args \"{'summarize': false}\" --vars \"{'audit_helper__store_comparison_data': true, 'audit_helper__store_comparison_data_limit': 2}\""},
]
```

#### Step 2: Add a Verification Macro

Create `integration_tests/macros/validation/verify_detail_table.sql` — a macro that queries the created detail table and asserts expected outcomes:

```jinja
{% macro verify_detail_table__sample_1(expect_matched_rows, expect_max_rows) %}
  {% if execute %}
    {# 1. Verify the detail table exists #}
    {% set detail_relation = adapter.get_relation(
        database = target.database,
        schema = ref('validation_log').schema,
        identifier = 'validation_log_detail__sample_1'
    ) %}
    {% if detail_relation is none %}
      {{ exceptions.raise_compiler_error('FAIL: validation_log_detail__sample_1 does not exist') }}
    {% endif %}

    {# 2. Check required columns are present #}
    {% set columns = adapter.get_columns_in_relation(detail_relation) %}
    {% set column_names = columns | map(attribute='name') | map('upper') | list %}
    {% set required_columns = ['MART_TABLE', 'DATE_OF_PROCESS', 'DBT_CLOUD_JOB_RUN_URL', 'DBT_CLOUD_JOB_START_AT',
                               'DBT_AUDIT_IN_A', 'DBT_AUDIT_IN_B', 'DBT_AUDIT_ROW_STATUS'] %}
    {% for col in required_columns %}
      {% if col not in column_names %}
        {{ exceptions.raise_compiler_error('FAIL: Missing column ' ~ col ~ ' in detail table. Found: ' ~ column_names) }}
      {% endif %}
    {% endfor %}

    {# 3. Verify excluded columns are NOT present #}
    {% set excluded = ['SAMPLE_1_SK', 'NOT_EXIST_IN_DBT'] %}
    {% for col in excluded %}
      {% if col in column_names %}
        {{ exceptions.raise_compiler_error('FAIL: Excluded column ' ~ col ~ ' should not be in detail table') }}
      {% endif %}
    {% endfor %}

    {# 4. Verify data columns are present (from sample_1 minus excluded) #}
    {% set expected_data_columns = ['NAME', 'AGE', 'CITY', 'LIFE_TIME_VALUE'] %}
    {% for col in expected_data_columns %}
      {% if col not in column_names %}
        {{ exceptions.raise_compiler_error('FAIL: Expected data column ' ~ col ~ ' not in detail table. Found: ' ~ column_names) }}
      {% endif %}
    {% endfor %}

    {# 5. Verify upstream audit columns are excluded (only keep 3) #}
    {% set excluded_audit_columns = ['DBT_AUDIT_SURROGATE_KEY', 'DBT_AUDIT_PK_ROW_NUM',
                                     'DBT_AUDIT_ROW_HASH', 'DBT_AUDIT_NUM_ROWS_IN_STATUS',
                                     'DBT_AUDIT_SAMPLE_NUMBER'] %}
    {% for col in excluded_audit_columns %}
      {% if col in column_names %}
        {{ exceptions.raise_compiler_error('FAIL: Internal audit column ' ~ col ~ ' should not be in detail table') }}
      {% endif %}
    {% endfor %}

    {# 6. Query row counts by status #}
    {% set count_query %}
      select dbt_audit_row_status, count(*) as cnt
      from {{ detail_relation }}
      group by dbt_audit_row_status
      order by dbt_audit_row_status
    {% endset %}
    {% set results = run_query(count_query) %}
    {{ log('ℹ️  Detail table row counts by status:', true) }}
    {{ audit_helper_ext.print_audit_result(results) }}

    {# 7. Verify matched row filtering #}
    {% set has_identical = results.columns['DBT_AUDIT_ROW_STATUS'].values() | select('equalto', 'identical') | list | length > 0 %}
    {% if not expect_matched_rows and has_identical %}
      {{ exceptions.raise_compiler_error('FAIL: Found identical rows but store_matched_rows=false') }}
    {% endif %}
    {% if expect_matched_rows and not has_identical %}
      {{ exceptions.raise_compiler_error('FAIL: Expected identical rows but none found (store_matched_rows=true)') }}
    {% endif %}

    {# 8. Verify row limit if specified #}
    {% if expect_max_rows is not none %}
      {% set total_query %}
        select count(*) as total from {{ detail_relation }}
      {% endset %}
      {% set total = run_query(total_query).columns[0].values()[0] %}
      {% if total > expect_max_rows %}
        {{ exceptions.raise_compiler_error('FAIL: Expected max ' ~ expect_max_rows ~ ' rows but found ' ~ total) }}
      {% endif %}
    {% endif %}

    {# 9. Verify metadata columns have values #}
    {% set meta_query %}
      select mart_table, date_of_process, dbt_cloud_job_start_at
      from {{ detail_relation }}
      limit 1
    {% endset %}
    {% set meta_row = run_query(meta_query) %}
    {% if meta_row.columns['MART_TABLE'].values()[0] != 'sample_1' %}
      {{ exceptions.raise_compiler_error('FAIL: mart_table should be sample_1, got ' ~ meta_row.columns['MART_TABLE'].values()[0]) }}
    {% endif %}

    {{ log('✅  All detail table assertions passed!', true) }}
  {% endif %}
{% endmacro %}
```

#### Step 3: Add `poe` Verification Tasks

```toml
# pyproject.toml
verify-detail-store = [
  {shell = "cd integration_tests && dbt run-operation verify_detail_table__sample_1 --args \"{'expect_matched_rows': false, 'expect_max_rows': none}\""},
]
verify-detail-store-with-matched = [
  {shell = "cd integration_tests && dbt run-operation verify_detail_table__sample_1 --args \"{'expect_matched_rows': true, 'expect_max_rows': none}\""},
]
verify-detail-store-with-limit = [
  {shell = "cd integration_tests && dbt run-operation verify_detail_table__sample_1 --args \"{'expect_matched_rows': false, 'expect_max_rows': 2}\""},
]
```

#### Step 4: Add `poe` Composite Tasks

```toml
# pyproject.toml
test-detail = [
  # Test 1: Default (mismatched rows only, no limit)
  {cmd = "poe validate-detail-store"},
  {cmd = "poe verify-detail-store"},
  # Test 2: With matched rows
  {cmd = "poe validate-detail-store-with-matched"},
  {cmd = "poe verify-detail-store-with-matched"},
  # Test 3: With row limit
  {cmd = "poe validate-detail-store-with-limit"},
  {cmd = "poe verify-detail-store-with-limit"},
]
```

### Test Scenarios

| # | Scenario | Vars | Assertions |
|---|----------|------|------------|
| 1 | **Feature off (default)** | _none_ | No `validation_log_detail__sample_1` table created. Verified by existing `poe validate-sample-1` succeeding without changes. |
| 2 | **Mismatched rows only** | `store_comparison_data: true` | Table exists, contains `modified`/`added`/`removed` rows, no `identical` rows. Metadata columns populated. Excluded columns absent. Internal audit columns (`dbt_audit_surrogate_key`, etc.) absent. |
| 3 | **With matched rows** | `store_comparison_data: true, store_matched_rows: true` | Same as #2, plus `identical` rows present. |
| 4 | **With row limit** | `store_comparison_data: true, store_comparison_data_limit: 2` | Table exists, total row count ≤ 2. |
| 5 | **Column correctness** | `store_comparison_data: true` | Data columns = intersecting columns of `sample_1` model and seed minus `exclude_columns`. Only 3 audit columns retained (`dbt_audit_in_a`, `dbt_audit_in_b`, `dbt_audit_row_status`). |
| 6 | **Drop/recreate idempotency** | Run `store_comparison_data: true` twice | Table exists, no duplicate data, row count matches single-run expectation. |

### Test Data: `sample_1`

The existing `sample_1` model + seed setup provides all needed row classification scenarios:

- **Modified rows**: Seed has different `age`/`city`/`life_time_value` values for several names
- **Added rows**: `sample_1` model includes `Jack2` on incremental runs (not in seed)
- **Removed rows**: Seed may include rows not in the dbt model
- **Identical rows**: Several rows match exactly between model and seed
- **Excluded columns**: `sample_1_sk` (surrogate key) and `not_exist_in_dbt` already configured

This means no new seeds or models are needed — the existing `poe init-sf` + seed data covers all classification scenarios.

### New and Modified Files (Testing)

| File | Action | Purpose |
|---|---|---|
| `integration_tests/macros/validation/verify_detail_table.sql` | **New** | Verification macro that asserts detail table schema, data, and row filtering |
| `pyproject.toml` | **Modified** | Add `poe` tasks: `validate-detail-store*`, `verify-detail-store*`, `test-detail` |

### Execution

```bash
# Full test run (Snowflake)
poe init-sf          # Seed data + build models (existing)
poe test-detail      # Run all 3 detail persistence test scenarios

# Or individually
poe validate-detail-store && poe verify-detail-store
```

## Trade-offs

| Pro | Con |
|---|---|
| Zero overhead when feature is off (default) | One extra query execution per `full` validation when on |
| Rich classification (`modified`/`added`/`removed`/`nonunique_pk`) | Many detail tables if many mart tables are validated |
| Leverages upstream `compare_and_classify_relation_rows` | Dependency on upstream macro stability (marked "v0" in 0.12.0 release notes) |
| No row limit — stores **all** mismatches | Schema varies per table (column set depends on mart) |
| In-warehouse execution — no Jinja memory pressure | No historical detail data (only latest run, but summaries are in `validation_log`) |
| Per-table isolation — clean schema, easy querying | Snowflake-only in initial scope |
| Drop/recreate — no schema drift issues | When `store_matched_rows=true`, table can be large |
| Matched rows opt-in keeps default storage minimal | — |
