# Script: validation__all.sh

## Table of Contents

- [Script: validation\_\_all.sh](#script-validation__allsh)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Purpose](#purpose)
  - [Prerequisites](#prerequisites)
    - [Required Tools](#required-tools)
    - [Project Setup](#project-setup)
  - [Usage](#usage)
    - [Basic Syntax](#basic-syntax)
    - [Quick Start](#quick-start)
  - [Command Line Options](#command-line-options)
    - [Option Details](#option-details)
      - [`-t TYPE` - Validation Type](#-t-type---validation-type)
      - [`-d DIR` - Models Directory](#-d-dir---models-directory)
      - [`-m MODEL` - Single Model](#-m-model---single-model)
      - [`-p DATE` - Date of Process](#-p-date---date-of-process)
      - [`-c RUNNER` - Command Runner](#-c-runner---command-runner)
      - [`-r` - Skip Model Runs](#-r---skip-model-runs)
      - [`-v` - Skip Validation](#-v---skip-validation)
  - [Validation Types](#validation-types)
    - [1. Count Validation (`count`)](#1-count-validation-count)
    - [2. Schema Validation (`schema`)](#2-schema-validation-schema)
    - [3. Row-by-Row Validation (`all_row`)](#3-row-by-row-validation-all_row)
    - [4. Column-by-Column Validation (`all_col`)](#4-column-by-column-validation-all_col)
    - [5. Upstream Row Count (`upstream_row_count`)](#5-upstream-row-count-upstream_row_count)
    - [6. All Validations (`all`)](#6-all-validations-all)
  - [Environment Configuration](#environment-configuration)
    - [Command Runner Detection](#command-runner-detection)
    - [Setting Default Runner](#setting-default-runner)
  - [Workflow Modes](#workflow-modes)
    - [Mode 1: Full Workflow (Default)](#mode-1-full-workflow-default)
    - [Mode 2: With Date-Based Cloning](#mode-2-with-date-based-cloning)
    - [Mode 3: Validate-Only](#mode-3-validate-only)
    - [Mode 4: Build-Only](#mode-4-build-only)
    - [Mode 5: Single Model + Specific Validation](#mode-5-single-model--specific-validation)
  - [Examples](#examples)
    - [Example 1: Quick Count Validation](#example-1-quick-count-validation)
    - [Example 2: Single Model Full Validation](#example-2-single-model-full-validation)
    - [Example 3: Validate Without Rebuilding](#example-3-validate-without-rebuilding)
    - [Example 4: Use UV Runner](#example-4-use-uv-runner)
    - [Example 5: Date-Based Validation](#example-5-date-based-validation)
    - [Example 6: Build Models for Later](#example-6-build-models-for-later)
    - [Example 7: Intermediate Models Validation](#example-7-intermediate-models-validation)
    - [Example 8: Complex Combination](#example-8-complex-combination)
  - [Logging](#logging)
    - [Log Location](#log-location)
    - [Log File Structure](#log-file-structure)
    - [Log Contents](#log-contents)
    - [Viewing Logs](#viewing-logs)
  - [Understanding the Output](#understanding-the-output)
    - [Color Coding](#color-coding)
    - [Progress Indicators](#progress-indicators)
    - [Timestamp Format](#timestamp-format)
    - [Operation Flow](#operation-flow)
  - [Advanced Usage](#advanced-usage)
    - [Running in CI/CD](#running-in-cicd)
    - [Parallel Execution](#parallel-execution)
    - [Automated Daily Validation](#automated-daily-validation)
    - [Integration with Notifications](#integration-with-notifications)
  - [Troubleshooting](#troubleshooting)
    - [Common Issues](#common-issues)
      - [Issue: "Missing required dependencies"](#issue-missing-required-dependencies)
      - [Issue: "Directory does not exist"](#issue-directory-does-not-exist)
      - [Issue: "Model file does not exist"](#issue-model-file-does-not-exist)
      - [Issue: Permission denied](#issue-permission-denied)
      - [Issue: Validation macros not found](#issue-validation-macros-not-found)
      - [Issue: Both skip flags set](#issue-both-skip-flags-set)
      - [Issue: No log files generated](#issue-no-log-files-generated)
      - [Issue: Script hangs or runs very slowly](#issue-script-hangs-or-runs-very-slowly)
    - [Debugging Tips](#debugging-tips)
      - [Enable Verbose Mode](#enable-verbose-mode)
      - [Check dbt Commands Directly](#check-dbt-commands-directly)
      - [Review Logs in Real-Time](#review-logs-in-real-time)
      - [Check Environment](#check-environment)

## Overview

`validation__all.sh` is a comprehensive bash script that orchestrates the entire data validation workflow for dbt mart models. It's your one-stop-shop for running validations - from simple row counts to detailed row-by-row comparisons - with beautiful colored output and organized logging.

**Location**: `scripts/validation__all.sh`
**Location in your dbt project**: `dbt_packages/audit_helper_ext/scripts/validation__all.sh`

## Purpose

This script is the workhorse of your validation pipeline. It:
- Runs multiple validation types (count, schema, row-level, column-level)
- Manages model builds and clone operations
- Provides flexible execution modes (validate-only, build-only, specific validation types)
- Generates organized logs per model
- Handles both single model and bulk validations
- Supports different command runners (poetry, uv)

## Prerequisites

### Required Tools

- **bash** shell (version 4.0+)
- **dbt-core** (1.7.0+)
- **Command runner**: Either:
  - `poetry` (default)
  - `uv` (alternative)
- Standard Unix utilities: `find`, `sort`, `date`, `tee`

### Project Setup

- dbt project properly configured
- Validation macros generated (using `create_validation_macros.py`)
- Models located in mart directory (default: `models/03_mart`)

## Usage

### Basic Syntax

```bash
./scripts/validation__all.sh [OPTIONS]
```

### Quick Start

```bash
# Run all validations with defaults
./scripts/validation__all.sh

# Run only count validation
./scripts/validation__all.sh -t count

# Validate single model
./scripts/validation__all.sh -m customer_fact

# Skip model runs, validate existing builds
./scripts/validation__all.sh -r

# Build models only, skip validation
./scripts/validation__all.sh -v
```

## Command Line Options

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `-h` | Show help message | - | `-h` |
| `-t TYPE` | Validation type | `all` | `-t count` |
| `-d DIR` | Models directory path | `models/03_mart` | `-d models/02_intermediate` |
| `-m MODEL` | Single model name | _(all models)_ | `-m customer_fact` |
| `-p DATE` | Audit helper date of process | _(empty)_ | `-p "2024-01-01"` |
| `-c RUNNER` | Command runner | `poetry` | `-c uv` |
| `-r` | Skip model runs, validate only | `false` | `-r` |
| `-v` | Run models only, skip validation | `false` | `-v` |

### Option Details

#### `-t TYPE` - Validation Type

Choose what type of validation to run:

| Type | Speed | Description | Use Case |
|------|-------|-------------|----------|
| `upstream_row_count` | Fast | Source table row counts | Pre-validation check |
| `count` | Fast | Row count comparison | Quick smoke test |
| `schema` | Fast | Schema/column structure | Detect schema drift |
| `all_row` | Moderate | Row-by-row detailed comparison | Full validation |
| `all_col` | Slow | Column-by-column debug output | Troubleshooting |
| `all` | Slowest | All validations (except all_col) | Comprehensive validation |

#### `-d DIR` - Models Directory

Specify which directory contains the models to validate:

```bash
# Validate mart models (default)
./scripts/validation__all.sh -d models/03_mart

# Validate intermediate models
./scripts/validation__all.sh -d models/02_intermediate

# Validate staging models
./scripts/validation__all.sh -d models/01_staging
```

#### `-m MODEL` - Single Model

Target a specific model instead of all models:

```bash
# Validate only customer_fact model
./scripts/validation__all.sh -m customer_fact

# Combine with validation type
./scripts/validation__all.sh -m customer_fact -t count
```

#### `-p DATE` - Date of Process

Triggers clone operations from legacy data at a specific date:

```bash
# Clone from specific date before validation
./scripts/validation__all.sh -p "2024-01-01"

# Without date, runs with full-refresh (default)
./scripts/validation__all.sh
```

**Behavior**:
- **With `-p`**: Clones legacy data → builds models → runs validations
- **Without `-p`**: Full-refresh build → runs validations

#### `-c RUNNER` - Command Runner

Choose which command runner to use:

```bash
# Use poetry (default)
./scripts/validation__all.sh -c poetry

# Use uv
./scripts/validation__all.sh -c uv
```

The script automatically prepends `poetry run` or `uv run` to all dbt commands.

#### `-r` - Skip Model Runs

Skip building models and only run validations:

```bash
# Models already built, just validate
./scripts/validation__all.sh -r

# Useful for quick re-validation
./scripts/validation__all.sh -t count -r
```

**Use when**: Models are already built and you want to save time.

#### `-v` - Skip Validation

Build models but skip validation steps:

```bash
# Just build models, no validation
./scripts/validation__all.sh -v
```

**Use when**: You want to prepare models but run validations later.

## Validation Types

### 1. Count Validation (`count`)

**What it does**: Compares row counts between dbt model and legacy source

**Speed**: ⚡ Fast (seconds per model)

**Use case**: Quick sanity check, smoke testing

**Example**:
```bash
./scripts/validation__all.sh -t count
```

### 2. Schema Validation (`schema`)

**What it does**: Compares column names, types, and structure

**Speed**: ⚡ Fast (seconds per model)

**Use case**: Detect schema drift, column name changes

**Example**:
```bash
./scripts/validation__all.sh -t schema
```

### 3. Row-by-Row Validation (`all_row`)

**What it does**: Detailed row-by-row comparison with summarized results

**Speed**: 🐢 Moderate (minutes per model, depends on data volume)

**Use case**: Comprehensive data validation

**Example**:
```bash
./scripts/validation__all.sh -t all_row
```

**Runs twice**:
1. With `summarize=true` (summary statistics)
2. With `summarize=false` (detailed differences)

### 4. Column-by-Column Validation (`all_col`)

**What it does**: Column-level validation for debugging

**Speed**: 🐌 Slow (debug mode, very detailed)

**Use case**: Troubleshooting specific column mismatches

**Example**:
```bash
./scripts/validation__all.sh -t all_col -m customer_fact
```

**Note**: Not included in `all` type due to verbosity.

### 5. Upstream Row Count (`upstream_row_count`)

**What it does**: Gets source table row counts

**Speed**: ⚡ Fast

**Use case**: Pre-validation check, verify sources exist

**Example**:
```bash
./scripts/validation__all.sh -t upstream_row_count
```

### 6. All Validations (`all`)

**What it does**: Runs all validation types except `all_col`

**Speed**: 🐢 Slowest (combines multiple validations)

**Use case**: Comprehensive validation suite

**Example**:
```bash
./scripts/validation__all.sh -t all
```

**Includes**:
- upstream_row_count
- count
- schema
- all_row (both summarize modes)

## Environment Configuration

### Command Runner Detection

The script validates that the selected command runner is installed:

```bash
# Poetry runner (default)
command -v poetry || error

# UV runner
command -v uv || error
```

### Setting Default Runner

You can set a default in your shell profile:

```bash
# In ~/.bashrc or ~/.zshrc
export COMMAND_RUNNER=uv
```

Then run without `-c` flag:
```bash
./scripts/validation__all.sh  # Uses COMMAND_RUNNER env var
```

## Workflow Modes

### Mode 1: Full Workflow (Default)

**Command**: `./scripts/validation__all.sh`

**Steps**:
1. Build all models with full-refresh
2. Run all validation types
3. Generate logs

### Mode 2: With Date-Based Cloning

**Command**: `./scripts/validation__all.sh -p "2024-01-01"`

**Steps**:
1. Clone legacy tables (from specified date)
2. Build all models
3. Run all validation types
4. Generate logs

### Mode 3: Validate-Only

**Command**: `./scripts/validation__all.sh -r`

**Steps**:
1. ~~Skip model builds~~
2. Run all validation types
3. Generate logs

**Use when**: Models already built, saves time.

### Mode 4: Build-Only

**Command**: `./scripts/validation__all.sh -v`

**Steps**:
1. Build all models
2. ~~Skip validations~~

**Use when**: Want to prepare models for later validation.

### Mode 5: Single Model + Specific Validation

**Command**: `./scripts/validation__all.sh -m customer_fact -t count`

**Steps**:
1. Build single model
2. Run specific validation type
3. Generate log for single model

**Use when**: Debugging or focused validation.

## Examples

### Example 1: Quick Count Validation

```bash
./scripts/validation__all.sh -t count
```

**Output**:
```
09:30:45  📋  Found 12 models in models/03_mart/
09:30:45  🛫  Starting [ COUNT ] validation(s) for ALL mart models...

09:30:46  👀 📊            Validate count - (12) model(s)                    👀
09:30:47  🔍  [1/12] Count validation: customer_fact
09:30:48  🔍  [2/12] Count validation: order_summary
...
09:31:02  ✅  Completed [ COUNT ] validation(s) for ALL mart models!
09:31:02  📂  Total log files created: 12 model logs
```

### Example 2: Single Model Full Validation

```bash
./scripts/validation__all.sh -m customer_fact -t all
```

**Output**:
```
09:35:10  📋  Validating single model: customer_fact
09:35:10      Located at: models/03_mart/finance/customer_fact.sql
09:35:10  🛫  Starting [ ALL ] validation(s) for model: customer_fact...

09:35:11  ▶️  Run single model: customer_fact (with full-refresh)
09:35:25  👀 📊            Get upstream row counts - (1) model(s)                    👀
09:35:26  👀 📊            Validate count - (1) model(s)                    👀
09:35:28  👀 📊            Validate schema - (1) model(s)                    👀
09:35:30  👀 📊            Validate Row by row - (1) model(s)                    👀

09:35:45  ✅  Completed [ ALL ] validation(s) for model: customer_fact!
09:35:45  📂  Model log: [ logs/validation__customer_fact.log ]
```

### Example 3: Validate Without Rebuilding

```bash
./scripts/validation__all.sh -t count -r
```

Skips model building, runs count validation on existing models.

### Example 4: Use UV Runner

```bash
./scripts/validation__all.sh -c uv -t schema
```

Uses `uv run` instead of `poetry run` for dbt commands.

### Example 5: Date-Based Validation

```bash
./scripts/validation__all.sh -p "2024-10-15"
```

**Workflow**:
1. Clones legacy tables from October 15, 2024
2. Builds models against that date
3. Runs validations comparing new vs legacy

### Example 6: Build Models for Later

```bash
# Build all models
./scripts/validation__all.sh -v

# Later, run validations without rebuilding
./scripts/validation__all.sh -r
```

### Example 7: Intermediate Models Validation

```bash
./scripts/validation__all.sh -d models/02_intermediate -t all_row
```

Validates intermediate models instead of mart models.

### Example 8: Complex Combination

```bash
./scripts/validation__all.sh \
  -d models/03_mart \
  -t all_row \
  -p "2024-10-15" \
  -c uv
```

**Effect**:
- Validates mart models
- Row-by-row validation only
- Uses date-based cloning
- Uses UV as command runner

## Logging

### Log Location

All logs are saved to:
```
logs/validation__{model_name}.log
```

### Log File Structure

Each model gets its own log file containing:

```
==========================================
VALIDATION LOG FOR MODEL: customer_fact
==========================================
Execution started: Mon Oct 29 09:30:45 UTC 2024
Validation types: COUNT
==========================================

[Timestamp]  Executing: poetry run dbt run-operation validation_count__customer_fact
[dbt output...]
[Validation results...]

[If multiple validation types, all append to same file]
```

### Log Contents

Each validation operation logs:
- Timestamp
- Command executed
- Full dbt output
- Validation results
- Error messages (if any)

### Viewing Logs

```bash
# View specific model log
cat logs/validation__customer_fact.log

# View recent logs
ls -lt logs/validation__*.log | head

# Search for errors
grep -i error logs/validation__*.log

# Follow log in real-time (during execution)
tail -f logs/validation__customer_fact.log
```

## Understanding the Output

### Color Coding

The script uses colors for better readability:

| Color | Meaning | Example |
|-------|---------|---------|
| 🔵 Blue | Informational | Finding models, configuration |
| 🟢 Green | Success | Validation completed |
| 🟡 Yellow | Warning | Skipping operations, empty configs |
| 🔴 Red | Error | Failures, missing dependencies |
| 🟣 Purple | Header | Section markers |
| 🔵 Cyan | Operation | Current operation being executed |

### Progress Indicators

```
🔍  [3/12] Count validation: product_sales
    ↑    ↑                   ↑
    |    |                   └─ Model being processed
    |    └───────────────────── Progress counter
    └────────────────────────── Operation icon
```

### Timestamp Format

All log messages include UTC timestamps:
```
09:30:45  🔍  [1/12] Count validation: customer_fact
↑
└─ HH:MM:SS format
```

### Operation Flow

```
🛫  Starting validation...           # Initialization
📋  Found 12 models                  # Discovery
▶️  Run all models                   # Build phase
👀 📊  Validate count - (12) models  # Validation phase
🔍  [1/12] Count validation: model1  # Individual operations
✅  Completed validation!            # Success
📂  Model log: [logs/...]            # Log location
```

## Advanced Usage

### Running in CI/CD

```bash
#!/bin/bash
# ci-validation.sh

set -e  # Exit on error

# Set environment
export DBT_PROFILES_DIR=/path/to/profiles
export COMMAND_RUNNER=poetry

# Run validations
./scripts/validation__all.sh -t count || {
    echo "Count validation failed"
    exit 1
}

./scripts/validation__all.sh -t schema || {
    echo "Schema validation failed"
    exit 1
}

echo "All validations passed!"
```

### Parallel Execution

For large projects, run validations in parallel using background jobs:

```bash
#!/bin/bash
# parallel-validation.sh

models=("customer_fact" "order_summary" "product_sales")

for model in "${models[@]}"; do
    ./scripts/validation__all.sh -m "$model" -t all &
done

# Wait for all to complete
wait

echo "All parallel validations completed"
```

### Automated Daily Validation

```bash
# crontab entry
0 2 * * * cd /path/to/project && ./scripts/validation__all.sh -t count 2>&1 | tee -a /var/log/dbt-validation.log
```

### Integration with Notifications

```bash
#!/bin/bash
# validation-with-notify.sh

./scripts/validation__all.sh -t all

if [ $? -eq 0 ]; then
    # Send success notification
    curl -X POST https://hooks.slack.com/... \
        -d '{"text": "✅ Validation passed!"}'
else
    # Send failure notification
    curl -X POST https://hooks.slack.com/... \
        -d '{"text": "❌ Validation failed!"}'
fi
```

## Troubleshooting

### Common Issues

#### Issue: "Missing required dependencies"

**Error**:
```
Missing required dependencies: poetry
Please install missing dependencies and try again.
```

**Solution**: Install the required command runner:
```bash
# Install poetry
curl -sSL https://install.python-poetry.org | python3 -

# Or install uv
pip install uv
```

#### Issue: "Directory does not exist"

**Error**:
```
Directory does not exist: models/03_mart
```

**Solution**:
- Verify the directory path
- Use `-d` flag with correct path
```bash
ls -la models/
./scripts/validation__all.sh -d models/02_intermediate
```

#### Issue: "Model file does not exist"

**Error**:
```
Model file does not exist: customer_fact.sql in models/03_mart/
```

**Solution**:
- Check model name spelling
- List available models:
```bash
find models/03_mart -name "*.sql" -type f -exec basename {} .sql \;
```

#### Issue: Permission denied

**Error**:
```
bash: ./scripts/validation__all.sh: Permission denied
```

**Solution**: Make script executable:
```bash
chmod +x scripts/validation__all.sh
./scripts/validation__all.sh
```

#### Issue: Validation macros not found

**Error**:
```
dbt run-operation validation_count__customer_fact
Compilation Error: ...macro 'validation_count__customer_fact' does not exist
```

**Solution**: Generate validation macros first:
```bash
python scripts/create_validation_macros.py
```

#### Issue: Both skip flags set

**Error**:
```
Cannot skip both model runs and validation. Nothing would be executed.
```

**Solution**: Use only one skip flag at a time:
```bash
# Either this
./scripts/validation__all.sh -r  # Skip runs only

# Or this
./scripts/validation__all.sh -v  # Skip validation only

# Not both
```

#### Issue: No log files generated

**Problem**: Script runs but no logs appear in `logs/` directory.

**Solution**:
1. Check if `logs/` directory exists (script creates it)
2. Check write permissions:
```bash
ls -la logs/
# Should show drwxr-xr-x
```
3. Try running with sudo if needed (not recommended for production)

#### Issue: Script hangs or runs very slowly

**Problem**: Validation takes extremely long time.

**Solution**:
1. Start with fast validation types:
```bash
./scripts/validation__all.sh -t count  # Fast
```
2. Validate single model first:
```bash
./scripts/validation__all.sh -m customer_fact -t count
```
3. Check warehouse resource availability
4. Avoid `all_col` type unless debugging

### Debugging Tips

#### Enable Verbose Mode

Add `set -x` to see command execution:
```bash
# Edit script temporarily
set -x  # Add after set -e, set -u

./scripts/validation__all.sh -t count
```

#### Check dbt Commands Directly

Test dbt commands independently:
```bash
# Test model build
poetry run dbt run -s customer_fact

# Test validation macro
poetry run dbt run-operation validation_count__customer_fact
```

#### Review Logs in Real-Time

```bash
# In one terminal, run validation
./scripts/validation__all.sh -m customer_fact

# In another terminal, follow the log
tail -f logs/validation__customer_fact.log
```

#### Check Environment

```bash
# Verify command runner installed
which poetry  # or which uv

# Verify dbt installed
poetry run dbt --version

# Check dbt profiles
poetry run dbt debug
```

---

**Pro tip**: Start your validation journey with fast validation types (`count`, `schema`) to quickly verify the setup works, then graduate to comprehensive validations (`all_row`, `all`) once you're confident. For large datasets, always test with a single model first using the `-m` flag before running validations across all models!
