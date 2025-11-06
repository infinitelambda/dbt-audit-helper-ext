# Getting Started

<!-- markdownlint-disable no-inline-html -->
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
    - [1. Add the package](#1-add-the-package)
    - [2. Install dependencies](#2-install-dependencies)
    - [3. Initialize resources](#3-initialize-resources)
  - [Configuration](#configuration)
    - [Option 1: Using Environment Variables (Recommended for Single Location)](#option-1-using-environment-variables-recommended-for-single-location)
    - [Option 2: Model-Level Configuration](#option-2-model-level-configuration)
  - [Your First Validation](#your-first-validation)
    - [1. Generate validation macros](#1-generate-validation-macros)
    - [2. Run validations](#2-run-validations)
    - [3. Check results](#3-check-results)
  - [Next Steps](#next-steps)

## Prerequisites

Before diving in, make sure you have:

- **Python 3.9+** installed
- **dbt Core >= 1.7.0** installed and configured
- A working dbt project (because, well, you need something to validate!)
- One of the supported data warehouses:
  - ❄️ Snowflake (default)
  - ☁️ BigQuery
  - ⛱️ SQL Server
  - 🐘 PostgreSQL

## Installation

Let's get this party started with three simple steps:

### 1. Add the package

Add to your `packages.yml`:

```yml
packages:
  - package: infinitelambda/audit_helper_ext
    version: [">=0.1.0", "<1.0.0"]
```

### 2. Install dependencies

```bash
dbt deps
```

### 3. Initialize resources

This creates the validation log table and summary view (don't worry, it's quick):

```bash
dbt run -s audit_helper_ext
```

**SQL Server and PostgreSQL users only**: Add this dispatch configuration to your `dbt_project.yml`:

```yml
dispatch:
  - macro_namespace: audit_helper
    search_order: ['audit_helper_ext', 'audit_helper']
  - macro_namespace: dbt
    search_order: ['audit_helper_ext', 'dbt']
```

## Configuration

You can start right away with simple setup. Here's what you need:

### Option 1: Using Environment Variables (Recommended for Single Location)

If all your source tables live in the same database and schema, just set these:

```bash
export SOURCE_DATABASE=my_source_db
export SOURCE_SCHEMA=my_source_schema
```

### Option 2: Model-Level Configuration

For projects with source tables scattered across different locations, add this to your model's config block:

```sql
{{
  config(
    materialized='table',
    meta={
      'audit_helper__source_database': 'my_source_db',
      'audit_helper__source_schema': 'my_source_schema'
    }
  )
}}

select * from {{ source('my_source', 'my_table') }}
```

**Alternative (legacy format - still supported):**
```sql
{{
  config(
    materialized='table',
    audit_helper__source_database='my_source_db',
    audit_helper__source_schema='my_source_schema'
  )
}}

select * from {{ source('my_source', 'my_table') }}
```

### PostgreSQL Specific Configuration

PostgreSQL users may need to disable parallel execution to improve validation match rates, especially when dealing with window functions or double precision data types:

```yaml
vars:
  # PostgreSQL: Disable parallel execution to improve match rate
  audit_helper__audit_query_pre_hooks:
    - 'SET max_parallel_workers_per_gather = 0'
```

This configuration executes the specified SQL statements before each audit query, ensuring more consistent results.

## Your First Validation

Time to validate something! Let's say you want to validate models in your `models/03_mart` directory:

### 1. Generate validation macros

```bash
python dbt_packages/audit_helper_ext/scripts/create_validation_macros.py models/03_mart
```

This creates validation macros in `macros/validation/` in your dbt project.

### 2. Run validations

Execute the generated validation macros:

**Option A: Run individual macro**

```bash
dbt run-operation validations__<model>
# dbt run-operation validations__sample_1
```

**Option B: Run via shell script**

```bash
dbt_packages/audit_helper_ext/scripts/validation__all.sh -r -m <model>
# -r to skip model build
# dbt_packages/audit_helper_ext/scripts/validation__all.sh -r -m sample_1
```


### 3. Check results

Query your validation report to see how things went:

```sql
select * from {{ ref('validation_log_report') }}
```

Look for:
- ✅ 100% match rate = Perfect!
- 🟡 ≥99% match rate = Pretty good
- ❌ <99% match rate = Time to investigate

## Next Steps

- **Configure incremental load validation**: Since testing against a full load that's NOT enough!
