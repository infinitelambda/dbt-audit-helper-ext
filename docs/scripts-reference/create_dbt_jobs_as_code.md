# Script: create_dbt_jobs_as_code.py

## Table of Contents

- [Script: create\_dbt\_jobs\_as\_code.py](#script-create_dbt_jobs_as_codepy)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Purpose](#purpose)
  - [Prerequisites](#prerequisites)
  - [Usage](#usage)
    - [Basic Syntax](#basic-syntax)
    - [Before Running](#before-running)
    - [Quick Start](#quick-start)
  - [Environment Variables](#environment-variables)
    - [Required Variables](#required-variables)
    - [Optional Variables (for Deployment)](#optional-variables-for-deployment)
  - [Command Line Arguments](#command-line-arguments)
  - [What It Does](#what-it-does)
  - [Generated Job Configuration](#generated-job-configuration)
    - [Job Structure](#job-structure)
    - [Base Template](#base-template)
  - [Job Scheduling Strategy](#job-scheduling-strategy)
    - [Time Distribution](#time-distribution)
    - [Scheduling Example](#scheduling-example)
    - [Customizing Schedule](#customizing-schedule)
  - [Using the Generated Configuration](#using-the-generated-configuration)
    - [Step 1: Generate Configuration](#step-1-generate-configuration)
    - [Step 2: Review Configuration](#step-2-review-configuration)
    - [Step 3: Plan Deployment (Dry Run)](#step-3-plan-deployment-dry-run)
    - [Step 4: Deploy to dbt Cloud](#step-4-deploy-to-dbt-cloud)
  - [Examples](#examples)
    - [Example 1: Generate for All Models](#example-1-generate-for-all-models)
    - [Example 2: Generate for Single Model](#example-2-generate-for-single-model)
    - [Example 3: Complete Workflow](#example-3-complete-workflow)
  - [Output](#output)
    - [File Location](#file-location)
    - [Generated File Structure](#generated-file-structure)
  - [Configuration Details](#configuration-details)
    - [Job Types](#job-types)
    - [Execute Steps Explained](#execute-steps-explained)
    - [Execution Settings](#execution-settings)
  - [Troubleshooting](#troubleshooting)
    - [Common Issues](#common-issues)
      - [Issue: "Environment variable not set"](#issue-environment-variable-not-set)
      - [Issue: "No models found"](#issue-no-models-found)
      - [Issue: dbt-jobs-as-code command not found](#issue-dbt-jobs-as-code-command-not-found)
      - [Issue: API authentication failed](#issue-api-authentication-failed)
      - [Issue: Jobs not triggering on schedule](#issue-jobs-not-triggering-on-schedule)
    - [Validation](#validation)
    - [Finding dbt Cloud IDs](#finding-dbt-cloud-ids)

## Overview

`create_dbt_jobs_as_code.py` is a Python script that generates dbt Cloud job configurations as YAML code. It's your automated job scheduler that takes your mart models and creates a complete job configuration file ready to be deployed to dbt Cloud using the `dbt-jobs-as-code` tool.

**Location**: `scripts/create_dbt_jobs_as_code.py`
**Location in your dbt project**: `dbt_packages/audit_helper_ext/scripts/create_dbt_jobs_as_code.py`

## Purpose

Managing dozens or hundreds of validation jobs in dbt Cloud UI can be tedious and error-prone. This script automates the process by:
- Creating standardized validation jobs for all your mart models
- Scheduling them intelligently to avoid resource contention
- Generating infrastructure-as-code that can be version controlled
- Making it easy to deploy and maintain consistent job configurations

## Prerequisites

- Python 3.9+ with `pyyaml` package installed
- Access to your dbt project structure
- dbt Cloud account with:
  - Account ID
  - Project ID
  - Environment ID
- [`dbt-jobs-as-code`](https://github.com/dbt-labs/dbt-jobs-as-code) CLI tool (for deployment)
- API key with Job Admin permissions (for deployment)

## Usage

### Basic Syntax

```bash
python scripts/create_dbt_jobs_as_code.py [MART_DIRECTORY] [MODEL_NAME]
```

### Before Running

Set required environment variables:

```bash
export DBT_CLOUD_ACCOUNT_ID=11553      # Your dbt Cloud account ID
export DBT_CLOUD_PROJECT_ID=380261     # Your dbt Cloud project ID
export DBT_CLOUD_ENVIRONMENT_ID=328988 # Your target environment ID
```

### Quick Start

```bash
# Generate jobs for all models in default directory
python scripts/create_dbt_jobs_as_code.py

# Generate jobs for all models in specific directory
python scripts/create_dbt_jobs_as_code.py models/03_mart

# Generate job for single model
python scripts/create_dbt_jobs_as_code.py models/03_mart customer_fact
```

## Environment Variables

### Required Variables

These **must** be set before running the script:

| Variable | Description | Example | Where to Find |
|----------|-------------|---------|---------------|
| `DBT_CLOUD_ACCOUNT_ID` | Your dbt Cloud account ID | `11553` | dbt Cloud URL or Account Settings |
| `DBT_CLOUD_PROJECT_ID` | Your dbt Cloud project ID | `380261` | Project Settings in dbt Cloud |
| `DBT_CLOUD_ENVIRONMENT_ID` | Target environment ID | `328988` | Environment Settings in dbt Cloud |

### Optional Variables (for Deployment)

Required only when using `dbt-jobs-as-code` to deploy:

| Variable | Description | Example |
|----------|-------------|---------|
| `DBT_API_KEY` | dbt Cloud API key with Job Admin permission | `dbtc_...` |

## Command Line Arguments

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `MART_DIRECTORY` | No | `models/03_mart` | Directory containing your mart models |
| `MODEL_NAME` | No | _(all models)_ | Name of single model to create job for |

## What It Does

The script performs these operations:

1. **Validates environment variables** - Ensures required dbt Cloud IDs are set
2. **Scans mart directory** - Finds all `.sql` model files
3. **Calculates scheduling** - Spreads jobs across time to avoid resource contention
4. **Generates YAML configuration** - Creates job definitions using YAML anchors for DRY principle
5. **Writes configuration file** - Saves to `dataops/dbt_cloud_jobs.yml`

## Generated Job Configuration

### Job Structure

Each generated job includes:

- **Build steps** - Standard validation workflow:
  1. Log initialization: `dbt run -s validation_log`
  2. Clone operation: `dbt run-operation clone_relation --args 'identifier: {model}'`
  3. Upstream build: `dbt build -s +{model} --exclude {model} --full-refresh`
  4. Model build: `dbt build -s {model}`
  5. Validation: `dbt run-operation validations__{model}`

- **Scheduling** - Automated with 15-minute intervals
- **Settings** - Consistent execution parameters
- **Environment** - Linked to specified dbt Cloud environment

### Base Template

All jobs inherit from a base template defined with YAML anchors:

```yaml
compile: &val_job
  name: "Compile"
  account_id: {DBT_CLOUD_ACCOUNT_ID}
  project_id: {DBT_CLOUD_PROJECT_ID}
  environment_id: {DBT_CLOUD_ENVIRONMENT_ID}
  execute_steps:
    - "dbt compile"
  execution:
    timeout_seconds: 0
  generate_docs: false
  run_generate_sources: false
  settings:
    target_name: default
    threads: 6
  triggers:
    custom_branch_only: false
    git_provider_webhook: false
    github_webhook: false
    schedule: false
  job_type: other
```

## Job Scheduling Strategy

### Time Distribution

To prevent overwhelming your data warehouse, jobs are automatically scheduled with staggered start times:

- **Base schedule**: Monday-Friday at 17:00 (5 PM)
- **Interval between jobs**: 15 minutes
- **Auto-rollover**: Automatically handles hour/day boundaries

### Scheduling Example

For 5 models, the schedule would be:

| Model | Job ID | Schedule |
|-------|--------|----------|
| `customer_fact` | `validation_00000` | 17:00 Mon-Fri |
| `order_summary` | `validation_00001` | 17:15 Mon-Fri |
| `product_sales` | `validation_00002` | 17:30 Mon-Fri |
| `revenue_daily` | `validation_00003` | 17:45 Mon-Fri |
| `inventory_snapshot` | `validation_00004` | 18:00 Mon-Fri |

### Customizing Schedule

To change the base schedule or interval, edit these constants in the script:

```python
CRON_BASE = "0 17 * * 1-5"  # Base cron expression
MINUTES_BETWEEN_RUNS = 15   # Minutes between job starts
```

## Using the Generated Configuration

### Step 1: Generate Configuration

```bash
# Set environment variables
export DBT_CLOUD_ACCOUNT_ID=11553
export DBT_CLOUD_PROJECT_ID=380261
export DBT_CLOUD_ENVIRONMENT_ID=328988

# Generate configuration
python scripts/create_dbt_jobs_as_code.py models/03_mart
```

### Step 2: Review Configuration

```bash
# Check generated file
cat dataops/dbt_cloud_jobs.yml
```

### Step 3: Plan Deployment (Dry Run)

```bash
# Set API key
export DBT_API_KEY=dbtc_your_api_key_here

# Preview changes
dbt-jobs-as-code plan dataops/dbt_cloud_jobs.yml
```

### Step 4: Deploy to dbt Cloud

```bash
# Apply configuration
dbt-jobs-as-code sync dataops/dbt_cloud_jobs.yml
```

## Examples

### Example 1: Generate for All Models

```bash
export DBT_CLOUD_ACCOUNT_ID=11553
export DBT_CLOUD_PROJECT_ID=380261
export DBT_CLOUD_ENVIRONMENT_ID=328988

python scripts/create_dbt_jobs_as_code.py models/03_mart
```

**Output**:
```
ℹ️  12 job(s) will be proceeded
✅ File: dataops/dbt_cloud_jobs.yml created or updated!
```

### Example 2: Generate for Single Model

```bash
python scripts/create_dbt_jobs_as_code.py models/03_mart customer_fact
```

**Output**:
```
ℹ️  1 job(s) will be proceeded
✅ File: dataops/dbt_cloud_jobs.yml created or updated!
```

### Example 3: Complete Workflow

```bash
# 1. Generate configuration
export DBT_CLOUD_ACCOUNT_ID=11553
export DBT_CLOUD_PROJECT_ID=380261
export DBT_CLOUD_ENVIRONMENT_ID=328988
python scripts/create_dbt_jobs_as_code.py

# 2. Review changes
git diff dataops/dbt_cloud_jobs.yml

# 3. Plan deployment
export DBT_API_KEY=dbtc_your_key
dbt-jobs-as-code plan dataops/dbt_cloud_jobs.yml

# 4. Deploy
dbt-jobs-as-code sync dataops/dbt_cloud_jobs.yml

# 5. Commit configuration
git add dataops/dbt_cloud_jobs.yml
git commit -m "Update dbt Cloud validation jobs"
```

## Output

### File Location

Generated configuration is saved to:
```
dataops/dbt_cloud_jobs.yml
```

The `dataops/` directory is created automatically if it doesn't exist.

### Generated File Structure

```yaml
# Usage instructions at the top
jobs:
  # Base template job
  compile: &val_job
    name: "Compile"
    # ... base configuration

  # Individual validation jobs
  validation_00000: # customer_fact
    <<: *val_job
    name: "customer_fact"
    execute_steps:
      - "dbt run -s validation_log"
      - "dbt run-operation clone_relation --args 'identifier: customer_fact'"
      - "dbt build -s +customer_fact --exclude customer_fact --full-refresh"
      - "dbt build -s customer_fact"
      - "dbt run-operation validations__customer_fact"
    schedule:
      cron: "0 17 * * 1-5"
    triggers:
      schedule: true
    job_type: scheduled

  validation_00001: # order_summary
    # ... similar structure
```

## Configuration Details

### Job Types

| Job Type | Description | When Used |
|----------|-------------|-----------|
| `other` | Non-scheduled base template | Base template job |
| `scheduled` | Scheduled validation jobs | All generated validation jobs |

### Execute Steps Explained

Each validation job runs these steps in order:

1. **`dbt run -s validation_log`**
   - Initialize validation logging table
   - Captures validation run metadata

2. **`dbt run-operation clone_relation --args 'identifier: {model}'`**
   - Clone legacy table for comparison
   - Creates snapshot of source data

3. **`dbt build -s +{model} --exclude {model} --full-refresh`**
   - Build all upstream dependencies
   - Ensures fresh data for validation

4. **`dbt build -s {model}`**
   - Build the target model itself
   - Creates the dbt version for comparison

5. **`dbt run-operation validations__{model}`**
   - Run all validation macros
   - Compares dbt output vs legacy data

### Execution Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| `timeout_seconds` | `0` | No timeout (unlimited execution time) |
| `threads` | `6` | Parallel execution threads |
| `target_name` | `default` | Use default target from profiles.yml |
| `generate_docs` | `false` | Skip documentation generation |
| `run_generate_sources` | `false` | Skip source freshness checks |

## Troubleshooting

### Common Issues

#### Issue: "Environment variable not set"

**Error**:
```
account_id: 0
project_id: 0
environment_id: 0
```

**Solution**: Set required environment variables:
```bash
export DBT_CLOUD_ACCOUNT_ID=11553
export DBT_CLOUD_PROJECT_ID=380261
export DBT_CLOUD_ENVIRONMENT_ID=328988
```

#### Issue: "No models found"

**Problem**: The script reports 0 jobs will be created.

**Solution**:
- Verify the mart directory path is correct
- Ensure `.sql` files exist in the directory
- Check file permissions

#### Issue: dbt-jobs-as-code command not found

**Problem**: Cannot deploy generated configuration.

**Solution**: Install dbt-jobs-as-code:
```bash
pip install dbt-jobs-as-code
```

#### Issue: API authentication failed

**Problem**: Deployment fails with authentication error.

**Solution**:
1. Verify API key has Job Admin permissions
2. Check API key is correctly set:
```bash
export DBT_API_KEY=dbtc_your_key_here
```

#### Issue: Jobs not triggering on schedule

**Problem**: Generated jobs exist but don't run on schedule.

**Solution**:
- Verify `triggers.schedule` is set to `true` in the YAML
- Check dbt Cloud environment is properly configured
- Ensure the environment has valid connection credentials

### Validation

After deployment, verify jobs in dbt Cloud:

1. Navigate to **Jobs** in dbt Cloud
2. Check that validation jobs appear with correct names
3. Verify schedule shows correct cron expression
4. Test trigger a job manually to ensure it runs successfully

### Finding dbt Cloud IDs

**Account ID**: Found in dbt Cloud URL: `cloud.getdbt.com/accounts/{ACCOUNT_ID}`

**Project ID**:
- Go to your project settings
- URL contains the project ID: `cloud.getdbt.com/accounts/{ACCOUNT_ID}/projects/{PROJECT_ID}`

**Environment ID**:
- Go to Environments settings
- URL contains environment ID when viewing an environment
- Or check the environment details page

---

**Pro tip**: Keep your `dataops/dbt_cloud_jobs.yml` under version control! This provides an audit trail of job configuration changes and makes it easy to recreate jobs if needed. It's also a great way to review job configurations during code reviews before deploying to production.
