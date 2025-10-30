# dbt Variables Reference

<!-- markdownlint-disable no-inline-html -->

## Table of Contents

- [dbt Variables Reference](#dbt-variables-reference)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Quick Reference](#quick-reference)
  - [Variables by Category](#variables-by-category)
    - [Logging Configuration](#logging-configuration)
      - [`audit_helper__database`](#audit_helper__database)
      - [`audit_helper__schema`](#audit_helper__schema)
      - [`audit_helper__full_refresh`](#audit_helper__full_refresh)
      - [`audit_helper__dbt_cloud_host_url`](#audit_helper__dbt_cloud_host_url)
    - [Source Configuration](#source-configuration)
      - [`audit_helper__source_database`](#audit_helper__source_database)
      - [`audit_helper__source_schema`](#audit_helper__source_schema)
    - [Legacy Table Name Mapping](#legacy-table-name-mapping)
      - [`audit_helper__old_identifier_naming_convention`](#audit_helper__old_identifier_naming_convention)
    - [Date Management](#date-management)
      - [`audit_helper__date_of_process`](#audit_helper__date_of_process)
      - [`audit_helper__allowed_date_of_processes`](#audit_helper__allowed_date_of_processes)
    - [Display and Formatting](#display-and-formatting)
      - [`audit_helper__print_table_enabled`](#audit_helper__print_table_enabled)
      - [`audit_helper_ext__result_format`](#audit_helper_ext__result_format)
      - [`audit_helper__validation_result_filters`](#audit_helper__validation_result_filters)
  - [Configuration Examples](#configuration-examples)
    - [Minimal Configuration](#minimal-configuration)
    - [Full Configuration](#full-configuration)
    - [Incremental Validation Setup](#incremental-validation-setup)

## Overview

This document provides a comprehensive reference for all dbt variables used in the `dbt-audit-helper-ext` package. These variables control everything from where validation logs are stored to how validation results are displayed. All variables should be configured in your `dbt_project.yml` file under the `vars:` key (unless specified otherwise). Most variables come with sensible defaults, so you only need to configure what you actually want to change.

## Quick Reference

| Variable | Category | Required | Default | Purpose |
|----------|----------|----------|---------|---------|
| `audit_helper__database` | Logging | No | `target.database` | Database for validation log tables |
| `audit_helper__schema` | Logging | No | `target.schema` | Schema for validation log tables |
| `audit_helper__full_refresh` | Logging | No | `0` | Force full refresh of validation_log model |
| `audit_helper__dbt_cloud_host_url` | Logging | No | `emea.dbt.com` | dbt Cloud host URL for job links |
| `audit_helper__source_database` | Source | No | `target.database` | Database containing legacy/source tables |
| `audit_helper__source_schema` | Source | No | `target.schema` | Schema containing legacy/source tables |
| `audit_helper__old_identifier_naming_convention` | Mapping | No | None | Pattern for transforming model names to legacy table names |
| `audit_helper__date_of_process` | Named Date | No | UTC now | Current snapshot date being validated e.g. '2025-10-20' or 'day1' |
| `audit_helper__allowed_date_of_processes` | Named Date | No | `[]` | List of valid snapshot dates e.g. ['2025-10-20', '2025-10-21'] or ['day1', 'day2'] |
| `audit_helper__print_table_enabled` | Display | No | Auto | Enable/disable table printing in terminal |
| `audit_helper_ext__result_format` | Display | No | `table` | Format for displaying audit results |
| `audit_helper__validation_result_filters` | Display | No | Default filters defined in macro | Filters for in-terminal validation result insights |

## Variables by Category

### Logging Configuration

Variables that control where and how validation logs are stored in your data warehouse.

#### `audit_helper__database`

**Type**: `string`
**Default**: `target.database`
**Used in**: `validation_log.sql`, `validation_log_report.sql`

The database where the `validation_log` and `validation_log_report` tables will be created and maintained. This is your central repository for all historical validation results.

**Example**:

```yaml
vars:
  audit_helper__database: "analytics_prod"
```

**When to use**:
- You want validation logs separate from your main dbt target database
- Different environments use different log databases
- You need to centralize logs across multiple projects

---

#### `audit_helper__schema`

**Type**: `string`
**Default**: `target.schema`
**Used in**: `validation_log.sql`, `validation_log_report.sql`

The schema where the `validation_log` and `validation_log_report` tables will be created and maintained.

**Example**:

```yaml
vars:
  audit_helper__schema: "validation_logs"
```

**When to use**:
- You want validation logs in a dedicated schema
- You need to separate logs from your main models
- You want consistent log location across environments

**Pro tip**: Combine with `audit_helper__database` for full control:

```yaml
vars:
  audit_helper__database: "audit_db"
  audit_helper__schema: "validation"
  # Results in: audit_db.validation.validation_log
  # (NOTE: can be different depening on `generate_schema_name` macro)
```

---

#### `audit_helper__full_refresh`

**Type**: `integer` (0 or 1)
**Default**: `0`
**Used in**: `validation_log.sql`

Controls whether the `validation_log` model performs a full refresh. When set to `1`, the model will be fully rebuilt instead of running incrementally.

**Example**:

```yaml
vars:
  audit_helper__full_refresh: 1
```

**When to use**:
- You need to rebuild the validation log from scratch
- Schema changes have been made to the log table
- You want to clean out old/corrupt data

**Command-line alternative**:

```bash
# ❌ This WON'T rebuild validation_log table
dbt run -s validation_log --full-refresh

# ✅ This WILL rebuild validation_log table
dbt run -s validation_log --full-refresh --vars '{audit_helper__full_refresh: 1}'
```

---

#### `audit_helper__dbt_cloud_host_url`

**Type**: `string`
**Default**: `emea.dbt.com`
**Used in**: `log_validation_result.sql`

The base URL for your dbt Cloud instance. Used to generate hyperlinks to job runs in the validation logs. This is only relevant when running in dbt Cloud environments.

**Example**:

```yaml
vars:
  audit_helper__dbt_cloud_host_url: "cloud.getdbt.com"  # US region
```

**Common values**:
- `cloud.getdbt.com` - US region
- `emea.dbt.com` - EMEA region
- `au.dbt.com` - Australia region

**When to use**:
- You're running validations in dbt Cloud
- You want clickable links to job runs in your validation logs
- You're in a non-EMEA region

---

### Source Configuration

Variables that point to where your legacy/source tables are located for validation comparison.

#### `audit_helper__source_database`

**Type**: `string`
**Default**: `target.database`
**Used in**: Generated validation macros, `clone_relation.sql`

The database containing the legacy or source tables that you're validating your dbt models against. This is the "old system" side of the comparison.

**Example**:

```yaml
vars:
  audit_helper__source_database: "legacy_dwh"
```

**When to use**:
- Legacy tables are in a different database than your dbt models
- You're validating against production while building in development
- You have different source databases per environment

**Model-level override**: You can also set this in individual model configs:

```sql
{{
  config(
    audit_helper__source_database='specific_legacy_db'
  )
}}
```

---

#### `audit_helper__source_schema`

**Type**: `string`
**Default**: `target.schema`
**Used in**: Generated validation macros, `clone_relation.sql`

The schema containing the legacy or source tables. Often used with versioning patterns like `legacy_schema__20240909` for snapshot-based validation.

**Example**:

```yaml
vars:
  audit_helper__source_schema: "legacy_prod"
```

**Dynamic versioning example**:

```yaml
sources:
  - name: legacy
    schema: "legacy__{{ var('audit_helper__date_of_process', 'day1') }}"
    tables:
      - name: customers
```

With `audit_helper__date_of_process: "2024-09-09"`, this resolves to `legacy__20240909.customers`.

**When to use**:
- Legacy tables are in a different schema
- You're using time-versioned schema names for snapshots
- Different models have sources in different schemas

**Model-level override**:

```sql
{{
  config(
    audit_helper__source_schema='specific_legacy_schema'
  )
}}
```

---

### Legacy Table Name Mapping

Variables that handle cases where your dbt model names don't match your legacy table names.

#### `audit_helper__old_identifier_naming_convention`

**Type**: `object` with `pattern` and `replacement` keys
**Default**: `none` (uses model name as-is)
**Used in**: `get_old_identifier_name.sql`

Defines a regex-based pattern for transforming dbt model names into legacy table names. This is your power tool for systematic name mapping when legacy tables follow a consistent naming pattern.

**Structure**:

```yaml
vars:
  audit_helper__old_identifier_naming_convention:
    pattern: '<regex_pattern>'
    replacement: '<replacement_string>'
```

**Examples**:

1. **Add prefix** (`customers` → `dim_customers`):

```yaml
vars:
  audit_helper__old_identifier_naming_convention:
    pattern: '^(.*)$'
    replacement: 'dim_\\1'
```

2. **Add suffix** (`customers` → `customers_legacy`):

```yaml
vars:
  audit_helper__old_identifier_naming_convention:
    pattern: '^(.*)$'
    replacement: '\\1_legacy'
```

3. **Replace prefix** (`dim_customers` → `legacy_customers`):

```yaml
vars:
  audit_helper__old_identifier_naming_convention:
    pattern: '^(dim|fact)_(.*)$'
    replacement: 'legacy_\\2'
```

4. **Remove prefix** (`stg_customers` → `customers`):

```yaml
vars:
  audit_helper__old_identifier_naming_convention:
    pattern: '^(stg|int)_(.*)$'
    replacement: '\\2'
```

**When to use**:
- Your legacy system has systematic prefix/suffix patterns
- You want DRY configuration instead of model-by-model overrides
- You're migrating many tables with consistent naming differences

**Resolution priority**: Model-level `audit_helper__old_identifier` config takes precedence over this variable. See [configure-legacy-table-name.md](./configure-legacy-table-name.md) for details.

---

### Date Management

Variables for managing snapshot dates in incremental validation scenarios.

#### `audit_helper__date_of_process`

**Type**: `string` (`YYYY-MM-DD` format or `free_text` without spaces)
**Default**: UTC current date (YYYY-MM-DD)
**Used in**: `date_of_process.sql`, validation macros, source definitions

The current snapshot date being validated. This is your "which version of the data am I testing?" variable. It can be a date string or a custom identifier.

**Example**:

```yaml
vars:
  audit_helper__date_of_process: "2024-09-10"
```

**Custom identifiers**:

```yaml
vars:
  audit_helper__date_of_process: "Day2"  # Or "sprint_1", "v1.2", etc.
```

**When to use**:
- You're testing against time-versioned snapshots
- You need to replay validation against historical data
- You're running incremental load validations

**Dynamic usage in sources**:

```yaml
sources:
  - name: raw_data
    schema: "snapshot__{{ var('audit_helper__date_of_process', '20240909') }}"
```

**Command-line override**:

```bash
dbt run --vars "{'audit_helper__date_of_process': '2024-09-10'}"
```

**Format flexibility**: The macro accepts YYYY-MM-DD format and can convert it to YYYYMMDD using the `format=true` parameter.

---

#### `audit_helper__allowed_date_of_processes`

**Type**: `list` of strings
**Default**: `[]` (empty list)
**Used in**: `date_of_process.sql`, `clone_relation.sql`

An ordered list of valid snapshot dates. This serves two purposes: validation that `audit_helper__date_of_process` is valid, and enabling automatic "previous date" lookups for incremental testing.

**Example**:

```yaml
vars:
  audit_helper__date_of_process: "2024-09-10"
  audit_helper__allowed_date_of_processes:
    - "2024-09-09"  # Day1
    - "2024-09-10"  # Day2
    - "2024-09-11"  # Day3
```

**When to use**:
- You're validating incremental loads across multiple snapshots
- You want to prevent accidental use of invalid/non-existent dates
- You need automatic "previous snapshot" detection

**Automatic previous date lookup**: When using `clone_relation` with `use_prev: true`, the package automatically finds the previous date:

```bash
# Current: 2024-09-10, Previous: 2024-09-09 (automatically detected)
dbt run-operation clone_relation \
  --args "{'identifier': 'customers', 'use_prev': true}" \
  --vars "{'audit_helper__date_of_process': '2024-09-10'}"
```

**Validation behavior**: If `audit_helper__date_of_process` is not in this list, the package will raise a compiler error.

---

### Display and Formatting

Variables that control how validation results are displayed in the terminal and logs.

#### `audit_helper__print_table_enabled`

**Type**: `string` or `boolean`
**Default**: Auto-detect (enabled in terminal, disabled in dbt Cloud)
**Used in**: `print_table.sql`

Controls whether validation results are printed as tables in the terminal output. The package automatically detects dbt Cloud and disables table printing there (due to the need of preventing data to be exposing in logs).

**Example**:

```yaml
vars:
  audit_helper__print_table_enabled: "yes"  # Force enable
```

**Valid values**:
- `"yes"` - Force enable table printing
- `"no"` or `""` - Disable table printing
- Omit - Auto-detect based on environment

**When to use**:
- You want to force enable/disable regardless of environment
- You're running in a custom environment and auto-detect isn't working
- You prefer clean logs without table formatting

**Auto-detection logic**: The package checks for `DBT_CLOUD_PROJECT_ID` environment variable. If present, assumes dbt Cloud and disables printing.

---

#### `audit_helper_ext__result_format`

**Type**: `string`
**Default**: `table`
**Used in**: `print_audit_result.sql`

The format used when printing audit results to the terminal.

**Example**:

```yaml
vars:
  audit_helper_ext__result_format: "table"
```

**Valid values**:
- `table` - Formatted table output (default and recommended)
- Other formats may be supported in future versions

**When to use**:
- You want to customize output format (currently limited to table)
- Future: When additional format options are available (JSON, CSV, etc.)

---

#### `audit_helper__validation_result_filters`

**Type**: `list` of filter objects
**Default**: Built-in filters (count mismatch, full validation in A not B)
**Used in**: `get_validation_result_filters.sql`

Defines filters for reporting validation results in the terminal. Each filter specifies a condition to highlight in the validation summary.

**Default configuration** (from `dbt_project.yml`):

```yaml
vars:
  audit_helper__validation_result_filters:
    - name: count__mismatch
      description: Row counts do not match between A and B
      macro: filter_count_validation_mismatch
      validation_type: count
      failed_calc:
        column: TOTAL_RECORDS
    - name: full__in_a_not_b
      description: Rows exist in A but missing in B
      macro: filter_full_validation_in_a_not_b
      validation_type: full
      failed_calc:
        agg: sum
        column: COUNT
```

**Filter structure**:
- `name` - Unique identifier for the filter
- `description` - Human-readable explanation of what this filter catches
- `macro` - The macro that implements the filter logic (always return `boolean` expression)
- `validation_type` - Type of validation this applies to (count, full, schema, etc.)
- `failed_calc` - How to calculate the failure count for display

**When to use**:
- You want to add custom filters for specific validation scenarios
- You need different highlighting logic for your reports
- You want to extend the default failure detection

**Custom filter example**:

```yaml
vars:
  audit_helper__validation_result_filters:
    - name: schema__type_mismatch
      description: Column data types do not match
      macro: filter_schema_validation_mismatch
      validation_type: schema
      failed_calc:
        column: MISMATCH_COUNT
```

---

## Configuration Examples

### Minimal Configuration

Good for quick starts and simple projects where defaults work fine:

```yaml
# dbt_project.yml
vars:
  audit_helper__source_database: "legacy_prod"
  audit_helper__source_schema: "legacy_schema"
```

This is all you need if:
- Your dbt model names match legacy table names
- You're okay with logs in your target database/schema
- You're not doing snapshot-based validation

---

### Full Configuration

A comprehensive setup showing all available options:

```yaml
# dbt_project.yml
vars:
  # Logging
  audit_helper__database: "analytics_prod"
  audit_helper__schema: "validation_logs"
  audit_helper__dbt_cloud_host_url: "cloud.getdbt.com"

  # Source location
  audit_helper__source_database: "legacy_dwh"
  audit_helper__source_schema: "legacy_prod"

  # Legacy table name mapping
  audit_helper__old_identifier_naming_convention:
    pattern: '^(.*)$'
    replacement: 'dim_\\1'

  # Date management
  audit_helper__date_of_process: "2024-09-10"
  audit_helper__allowed_date_of_processes:
    - "2024-09-09"
    - "2024-09-10"
    - "2024-09-11"

  # Display
  audit_helper__print_table_enabled: "yes"
  audit_helper_ext__result_format: "table"
```

---

### Incremental Validation Setup

Configuration for testing incremental loads across snapshots:

```yaml
# dbt_project.yml
vars:
  # Source with dynamic versioning
  audit_helper__source_database: "snapshots"
  audit_helper__source_schema: "legacy__{{ var('audit_helper__date_of_process', '20240909') }}"

  # Date configuration
  audit_helper__date_of_process: "2024-09-09"  # Override via CLI for Day2
  audit_helper__allowed_date_of_processes:
    - "2024-09-09"
    - "2024-09-10"

  # Legacy naming
  audit_helper__old_identifier_naming_convention:
    pattern: '^(.*)$'
    replacement: 'tbl_\\1'
```

**Usage**:

```bash
# Day1 validation (full load)
dbt_packages/audit_helper_ext/scripts/validation__all.sh -r

# Day2 validation (incremental load)
dbt_packages/audit_helper_ext/scripts/validation__all.sh -r -p 2024-09-10
```

---

_Need more detailed guidance on specific variables? Check out:_
- [configure-legacy-table-name.md](./configure-legacy-table-name.md) for legacy name mapping
- [validation-incremental-load.md](./validation-incremental-load.md) for date management
- [getting-started.md](./getting-started.md) for basic setup

_Happy validating! May your match rates be forever 100%. 🎯_
