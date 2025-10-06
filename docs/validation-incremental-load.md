# Validation: Incremental Load

<!-- markdownlint-disable no-inline-html -->
- [Validation: Incremental Load](#validation-incremental-load)
  - [Prerequisites](#prerequisites)
    - [1. Two Consecutive Data Snapshots](#1-two-consecutive-data-snapshots)
    - [2. Validation Macros Generated](#2-validation-macros-generated)
  - [Configuration](#configuration)
    - [Step 1: Configure Date Variables](#step-1-configure-date-variables)
    - [Step 2: Configure Source Location](#step-2-configure-source-location)
  - [Validation Strategy](#validation-strategy)
    - [Scenario 1: Full Load Validation (Day1)](#scenario-1-full-load-validation-day1)
    - [Scenario 2: Incremental Load Validation (Day2)](#scenario-2-incremental-load-validation-day2)
  - [Understanding the Results](#understanding-the-results)
  - [Next Steps](#next-steps)

Testing against a full load is great, but it's only half the story. The real test? Making sure your incremental runs work flawlessly. After all, your pipeline will be running incrementally in production, not doing full refreshes every time (we hope!).

## Prerequisites

Before we dive into incremental validation, you'll need:

### 1. Two Consecutive Data Snapshots

> Sometime we need 3 consecutive snapshots

Think of these as your time machine checkpoints. You need snapshots from two consecutive dates, let's call them **Day1** and **Day2**:

- **Source data snapshots**: `source__YYYYMMDD1` and `source__YYYYMMDD2`
- **Mart table snapshots**: `mart__YYYYMMDD1` and `mart__YYYYMMDD2`

These snapshots represent your data frozen at specific points in time, allowing you to replay history and validate that your dbt transformations produce the same results as your legacy system.

### 2. Validation Macros Generated

If you haven't generated validation macros yet, head back to the [Getting Started guide](./getting-started.md#your-first-validation) first.

## Configuration

### Step 1: Configure Date Variables

Set up the date configuration in your `dbt_project.yml`:

```yaml
vars:
  # The current date we're validating against
  audit_helper__date_of_process: "2024-09-10"  # Day2

  # List of available snapshot dates (order matters!)
  audit_helper__allowed_date_of_processes:
    - "2024-09-09"  # Day1
    - "2024-09-10"  # Day2
```

**Why both variables?**
- `audit_helper__date_of_process`: Points to the date you're currently validating
- `audit_helper__allowed_date_of_processes`: Defines the chronological order of your snapshots, enabling the system to automatically find the "previous" snapshot for incremental testing

**Alternative date formats**: If you prefer human-readable names, you can use:

```yaml
vars:
  audit_helper__date_of_process: "Day2"
  audit_helper__allowed_date_of_processes: ["Day1", "Day2"]
```

### Step 2: Configure Source Location

Point your sources to the versioned Source snapshot tables:

```yml
sources:
  - name: source_1
    schema: "whatever_stuff__{{ var('audit_helper__date_of_process', 'day1') }}"
    tables:
      - name: table_1
      ...
```

With this config in place, once you run dbt:

```bash
# Source data is pointing to the Day1 schema named: `whatever_stuff__20240909`
uv run dbt run -s +<model> 
# Source data is pointing to the Day2 schema named: `whatever_stuff__20240910`
uv run dbt run -s +<model> --vars '{audit_helper__date_of_process: 2024-09-10}'
```

## Validation Strategy

We follow a two-scenario approach that mirrors how your pipeline will actually run in production:

### Scenario 1: Full Load Validation (Day1)

First, let's validate a fresh, full run against Day1 data.

**Step 1: Point sources to Source Day1 snapshot (default)**

```yaml
# dbt_project.yml
vars:
  audit_helper__date_of_process: "2024-09-09"  # Day1
```

**Step 2: Run dbt to build mart tables**

```bash
uv run dbt run -s +models/03_mart/ --full-refresh
```

This creates your `mart_dbt` tables from the Day1 source data.

**Step 3: Run validation**

```bash
# Run validation for a specific model
dbt_packages/audit_helper_ext/scripts/validation__all.sh -r -m dim_customer

# Or run for all models in the mart directory
dbt_packages/audit_helper_ext/scripts/validation__all.sh -r
```

The `-r` flag skips rebuilding models since we just did that in Step 2.

Remove it if we want to performa Run and Valiation sequencely.

**Step 4: Check results**

```sql
select * from {{ ref('validation_log_report') }}
where date_of_process = '2024-09-09'
```

✅ Expect 100% match rate for count, schema, and full validations!

### Scenario 2: Incremental Load Validation (Day2)

Now for the real test: validating incremental runs. This is where we ensure your incremental logic works exactly like the legacy system.

**Step 1: Point sources to Day2 snapshot**

Add `--vars "{'audit_helper__date_of_process': '2024-09-10'}"` to dbt command!

**Step 2: Clone Day1 mart tables to simulate existing data**

Before running incrementally, we need to start with Target Day1 data already in place (just like production would have) by Cloning:

```bash
# Clone a specific model's Target Day1 data
uv run dbt run-operation clone_relation \
  --args "{'identifier': 'dim_customer', 'use_prev': true}" \
  --vars "{'audit_helper__date_of_process': '2024-09-10'}"
```

The magic here: `use_prev: true` automatically finds Target Day1 from your `allowed_date_of_processes` list and clones `mart__20240909.dim_customer` to your target location.

**Step 3: Run incremental dbt build**

```bash
uv run dbt run -s +models/03_mart/ --vars "{'audit_helper__date_of_process': '2024-09-10'}"
```

This runs your models incrementally on top of the cloned Target Day1 data.

**Step 4: Run validation**

```bash
dbt_packages/audit_helper_ext/scripts/validation__all.sh -r -m dim_customer -p 2024-09-10

# or run & validation in 1 command
dbt_packages/audit_helper_ext/scripts/validation__all.sh -m dim_customer -p 2024-09-10
```

**Step 5: Check results**

```sql
select * from {{ ref('validation_log_report') }}
where validation_date = '2024-09-10'
```

✅ 100% match = Your incremental logic is perfect!
🟡 ≥99% match = Pretty good, investigate minor differences
❌ <99% match = Houston, we have a problem

## Understanding the Results

The validation report shows several key metrics:

- **upstream_row_count**: Rows processed from upstream (helps identify if incremental actually ran)
- **is_count_match**: Percentage of row count matching between dbt and legacy
- **is_data_type_match**: Whether column definitions match
- **match_rate_percentage**: Percentage of rows with identical data

**Pro tip**: Check `upstream_row_count` to confirm your incremental run actually processed new data. If it's 0 and you have 100% match rate, you might just be comparing identical static datasets!

## Next Steps

Now that you've got the basics down, you might want to:

- **Explore validation types**: Count, schema, and full row-by-row validations are at your fingertips
- **Check the validation strategy**: Read about our battle-tested approach for migration projects in the [main README](../README.md#validation-strategy)
- **Automate validations**: Integrate validation runs into your CI/CD pipeline for continuous peace of mind