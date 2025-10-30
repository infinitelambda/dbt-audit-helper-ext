# Script: create_validation_macros.py

## Table of Contents

- [Script: create\_validation\_macros.py](#script-create_validation_macrospy)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Purpose](#purpose)
  - [Prerequisites](#prerequisites)
  - [Usage](#usage)
    - [Basic Syntax](#basic-syntax)
    - [Quick Start](#quick-start)
  - [Command Line Arguments](#command-line-arguments)
  - [Environment Variables](#environment-variables)
  - [What It Does](#what-it-does)
  - [Generated Macros](#generated-macros)
  - [Model Configuration](#model-configuration)
    - [Setting Source Configuration](#setting-source-configuration)
      - [1. Model-Level Configuration (Highest Priority)](#1-model-level-configuration-highest-priority)
      - [2. Environment Variables (Medium Priority)](#2-environment-variables-medium-priority)
      - [3. dbt Variables (Lowest Priority/Fallback)](#3-dbt-variables-lowest-priorityfallback)
    - [Configuration Options](#configuration-options)
  - [Examples](#examples)
    - [Example 1: Generate for All Models](#example-1-generate-for-all-models)
    - [Example 2: Generate for Single Model](#example-2-generate-for-single-model)
    - [Example 3: With Environment Variables](#example-3-with-environment-variables)
  - [Output](#output)
    - [File Location Pattern](#file-location-pattern)
    - [Generated File Structure](#generated-file-structure)
  - [Troubleshooting](#troubleshooting)
    - [Common Issues](#common-issues)
      - [Issue: "Directory does not exist"](#issue-directory-does-not-exist)
      - [Issue: No validation files generated](#issue-no-validation-files-generated)
      - [Issue: Missing unique\_key in generated macros](#issue-missing-unique_key-in-generated-macros)
      - [Issue: Wrong source table reference](#issue-wrong-source-table-reference)
    - [Getting Help](#getting-help)

## Overview

`create_validation_macros.py` is a Python code generation script that automatically creates dbt validation macros for your mart models. Think of it as your automated macro factory - it reads your model definitions and churns out all the validation macros you need to compare your dbt models against legacy data sources.

**Location**: `scripts/create_validation_macros.py`
**Location in your dbt project**: `dbt_packages/audit_helper_ext/scripts/create_validation_macros.py`

## Purpose

When migrating from legacy data pipelines to dbt, you need to ensure your new models produce identical results to the old ones. This script automates the tedious process of creating validation macros for each model, saving you hours of repetitive work and reducing human error.

## Prerequisites

- Python 3.9+ installed
- Access to your dbt project structure
- Model files located in the mart directory (default: `models/03_mart`)
- Model configurations set up with unique keys (if applicable)

## Usage

### Basic Syntax

```bash
python scripts/create_validation_macros.py [MART_DIRECTORY] [MODEL_NAME]
```

### Quick Start

```bash
# Generate validation macros for all models in default directory
python scripts/create_validation_macros.py

# Generate for all models in a specific directory
python scripts/create_validation_macros.py models/03_mart

# Generate for a single specific model
python scripts/create_validation_macros.py models/03_mart sample_target_1
```

## Command Line Arguments

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `MART_DIRECTORY` | No | `models/03_mart` | The directory containing your mart models |
| `MODEL_NAME` | No | _(all models)_ | Name of a single model to generate macros for |

## Environment Variables

The script supports environment variables for configuring source database and schema when they're consistent across all models:

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `SOURCE_DATABASE` | No | Default source database name | `LEGACY_DB` |
| `SOURCE_SCHEMA` | No | Default source schema name | `LEGACY_SCHEMA` |

**Note**: Model-specific configurations in the dbt model files take precedence over environment variables.

## What It Does

The script performs the following operations:

1. **Scans your mart directory** - Walks through the specified directory to find all `.sql` model files
2. **Reads model configurations** - Extracts configuration from model files with a priority-based lookup:
   - `audit_helper__unique_key` - Primary keys for row-by-row comparison (falls back to `unique_key`)
   - `audit_helper__exclude_columns` - Columns to exclude from validation
   - `audit_helper__source_database` - Source database override
   - `audit_helper__source_schema` - Source schema override
   - `audit_helper__old_identifier` - Source table name override

   **Configuration Priority Order** (for each key):
   1. `config.meta.audit_helper__<key>` (NEW preferred format)
   2. `config.audit_helper__<key>` (existing format, still supported)
   3. `config.<key>` (fallback - e.g., `unique_key` when looking for `audit_helper__unique_key`)

3. **Generates validation macros** - Creates 8 different validation macros per model
4. **Writes macro files** - Saves generated macros to `macros/validation/{model_path}/validation__{model_name}.sql`

## Generated Macros

For each model, the script generates the following macros:

| Macro Name Pattern | Purpose | Usage Example |
|-------------------|---------|---------------|
| `get_validation_config__{model}` | Configuration namespace | Internal use by other macros |
| `validation_count__{model}` ⭐ | Row count comparison | Quick count verification |
| `validation_schema__{model}` ⭐ | Schema/column structure comparison | Detect schema drift |
| `validation_full__{model}` ⭐ | Row-by-row detailed comparison | Full data validation |
| `validation_all_col__{model}` | Column-by-column validation | Debug specific column issues |
| `validations__{model}` 🌟 | Run all validations at once | Comprehensive validation in one go |
| `validation_count_by_group__{model}` | Count comparison by group | Validate aggregated metrics |
| `validation_col__{model}` | Show column conflicts | Debug specific column mismatches |

## Model Configuration

### Setting Source Configuration

You can configure the source table location at three levels (in order of precedence):

#### 1. Model-Level Configuration (Highest Priority)

You can add configuration directly in your model file using either the **new preferred `meta` format** or the **legacy direct config format**.

**Option A: Using `meta` block (NEW preferred format)** - Keeps audit helper configs separate from dbt core configs:

```sql
{{
  config(
    materialized = 'incremental',
    unique_key = ['id'],
    on_schema_change = 'sync_all_columns',
    meta = {
      "audit_helper__unique_key": ["id", "date"],
      "audit_helper__source_database": "PROD_DB",
      "audit_helper__source_schema": "LEGACY_MART",
      "audit_helper__old_identifier": "legacy_customer_table",
      "audit_helper__exclude_columns": ["created_at", "updated_at"]
    }
  )
}}

SELECT ...
```

- `unique_key = ['id']`:  dbt's incremental key
- `"audit_helper__unique_key": ["id", "date"]`: Validation comparison key (can differ from unique_key)

**Option B: Direct config format (LEGACY, still supported)** - Places configs directly in config block:

```sql
{{
  config(
    unique_key = ['id', 'date'],
    audit_helper__source_database = 'PROD_DB',
    audit_helper__source_schema = 'LEGACY_MART',
    audit_helper__old_identifier = 'legacy_customer_table',
    audit_helper__exclude_columns = ['created_at', 'updated_at']
  )
}}

SELECT ...
```

**Why use the `meta` format?**
- **Avoids dbt Fusion errors** - Custom config keys (like `audit_helper__*`) can trigger validation errors in dbt Fusion, which expects only recognized dbt config keys
- Cleaner separation between dbt core configs and audit helper configs
- Allows `unique_key` (for incremental materialization) and `audit_helper__unique_key` (for validation) to differ
- Better organization for configuration metadata
- The `meta` block is dbt's official way to store custom metadata without interfering with core functionality

#### 2. Environment Variables (Medium Priority)

Set environment variables before running the script:

```bash
export SOURCE_DATABASE="PROD_DB"
export SOURCE_SCHEMA="LEGACY_MART"
python scripts/create_validation_macros.py
```

#### 3. dbt Variables (Lowest Priority/Fallback)

The generated macros use dbt variables as fallback:
- `audit_helper__source_database` (defaults to `target.database`)
- `audit_helper__source_schema` (defaults to `target.schema`)

### Configuration Options

| Config Key | Type | Description | Example | Priority Lookup |
|------------|------|-------------|---------|-----------------|
| `audit_helper__unique_key` | list | Primary key columns for validation comparison | `["customer_id", "date"]` | 1. `meta.audit_helper__unique_key`<br>2. `audit_helper__unique_key`<br>3. `unique_key` (fallback) |
| `audit_helper__exclude_columns` | list | Columns to skip in validation | `["updated_at", "etl_timestamp"]` | 1. `meta.audit_helper__exclude_columns`<br>2. `audit_helper__exclude_columns` |
| `audit_helper__source_database` | string | Source database name | `"LEGACY_DB"` | 1. `meta.audit_helper__source_database`<br>2. `audit_helper__source_database` |
| `audit_helper__source_schema` | string | Source schema name | `"LEGACY_SCHEMA"` | 1. `meta.audit_helper__source_schema`<br>2. `audit_helper__source_schema` |
| `audit_helper__old_identifier` | string | Source table name (if different from model) | `"old_customer_facts"` | 1. `meta.audit_helper__old_identifier`<br>2. `audit_helper__old_identifier` |

**Note on `audit_helper__unique_key` vs `unique_key`:**
- `audit_helper__unique_key` is specifically for validation/comparison purposes
- dbt's `unique_key` is for incremental materialization
- If `audit_helper__unique_key` is not specified, the script falls back to using `unique_key`
- In many cases they're the same, but you may want different keys for validation vs incremental updates

## Examples

### Example 1: Generate for All Models

```bash
python scripts/create_validation_macros.py models/03_mart
```

**Output**:
```
💁 Assuming the mart directory is [models/03_mart]
🏃 Working on the model: customer_fact ...
    ✅ macros/validation/03_mart/validation__customer_fact.sql created or updated!
◾◾◾
🏃 Working on the model: order_summary ...
    ✅ macros/validation/03_mart/validation__order_summary.sql created or updated!
◾◾◾
🚏🚏🚏
```

### Example 2: Generate for Single Model

```bash
python scripts/create_validation_macros.py models/03_mart customer_fact
```

**Output**:
```
🏃 Working on the model: customer_fact ...
    ✅ macros/validation/03_mart/validation__customer_fact.sql created or updated!
◾◾◾
🚏🚏🚏
```

### Example 3: With Environment Variables

```bash
export SOURCE_DATABASE="PROD_LEGACY"
export SOURCE_SCHEMA="MART_V1"
python scripts/create_validation_macros.py
```

This applies `PROD_LEGACY.MART_V1` as the default source location for all models that don't have model-specific overrides.

## Output

### File Location Pattern

Generated validation macro files are saved to:
```
macros/validation/{relative_model_path}/validation__{model_name}.sql
```

**Example**: For a model at `models/03_mart/finance/customer_fact.sql`, the validation macros are created at:
```
macros/validation/03_mart/finance/validation__customer_fact.sql
```

### Generated File Structure

Each validation file contains 8 macros in this order:

```sql
{# Validation config #}
{% macro get_validation_config__model_name() %}
  ...
{% endmacro %}

{# Row count #}
{% macro validation_count__model_name() %}
  ...
{% endmacro %}

{# Schema diff validation #}
{% macro validation_schema__model_name() %}
  ...
{% endmacro %}

{# Column comparison #}
{% macro validation_all_col__model_name() %}
  ...
{% endmacro %}

{# Row-by-row validation #}
{% macro validation_full__model_name() %}
  ...
{% endmacro %}

{# Validations for All #}
{% macro validations__model_name() %}
  ...
{% endmacro %}

{# Row count by group #}
{% macro validation_count_by_group__model_name(group_by) %}
  ...
{% endmacro %}

{# Show column conflicts #}
{% macro validation_col__model_name(columns_to_compare, summarize=true, limit=100) %}
  ...
{% endmacro %}
```

## Troubleshooting

### Common Issues

#### Issue: "Directory does not exist"

**Problem**: The specified mart directory doesn't exist.

**Solution**:
```bash
# Check if directory exists
ls -la models/03_mart

# Use correct path
python scripts/create_validation_macros.py models/02_intermediate
```

#### Issue: No validation files generated

**Problem**: No `.sql` files found in the specified directory.

**Solution**: Ensure you have model files with `.sql` extension in your mart directory.

#### Issue: Missing unique_key in generated macros

**Problem**: The script couldn't find `unique_key` or `audit_helper__unique_key` configuration in the model.

**Solution**: Add the key configuration to your model using one of these approaches:

**Option 1 - Using meta block (preferred):**
```sql
{{
  config(
    materialized = 'incremental',
    unique_key = ['id'],
    meta = {
      "audit_helper__unique_key": ["id"]
    }
  )
}}
```

**Option 2 - Using direct config:**
```sql
{{
  config(
    unique_key = ['id']
  )
}}
```

#### Issue: Wrong source table reference

**Problem**: Generated macros reference incorrect source table.

**Solution**: Add `audit_helper__old_identifier` to your model config:

**Option 1 - Using meta block (preferred):**
```sql
{{
  config(
    meta = {
      "audit_helper__old_identifier": "correct_legacy_table_name"
    }
  )
}}
```

**Option 2 - Using direct config:**
```sql
{{
  config(
    audit_helper__old_identifier = 'correct_legacy_table_name'
  )
}}
```

### Getting Help

If you encounter issues:

1. **Check model file syntax** - Ensure your model config block is properly formatted
2. **Verify permissions** - Ensure you have write access to the `macros/validation/` directory
3. **Review script output** - The script prints helpful progress messages
4. **Check model paths** - Ensure model files are in the expected directory structure

---

**Pro tip**: Run this script whenever you add new models or update model configurations to keep your validation macros in sync! It's safe to run multiple times - it will overwrite existing files with updated versions.
