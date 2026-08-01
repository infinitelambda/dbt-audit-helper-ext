# Breaking Changes since v0.9

<!-- markdownlint-disable no-inline-html -->

- [Breaking Changes since v0.9](#breaking-changes-since-v09)
  - [Renamed Columns](#renamed-columns)
  - [Renamed dbt Variable](#renamed-dbt-variable)
  - [New Feature: Row-Level Detail Persistence](#new-feature-row-level-detail-persistence)

> If you are upgrading from a version prior to v0.9.0, please review the following changes carefully. Nothing too scary, but your pipelines will thank you for reading this before they start complaining.

## Renamed Columns

The following columns in `validation_log` and `validation_log_report` have been renamed to drop the `dbt_cloud_` prefix, since these columns are used regardless of whether you run in dbt Cloud or Core:

| Old Column Name | New Column Name |
|-----------------|-----------------|
| `dbt_cloud_job_url` | `job_url` |
| `dbt_cloud_job_run_url` | `job_run_url` |
| `dbt_cloud_job_start_at` | `job_started_at` |

**Action required**: Rebuild `validation_log` with `--full-refresh` and `audit_helper__full_refresh: 1`. Any downstream queries referencing the old column names must be updated.

```bash
dbt run -s audit_helper_ext --full-refresh --vars '{audit_helper__full_refresh: 1}'
```

## Renamed dbt Variable

| Old Variable | New Variable |
|--------------|--------------|
| `audit_helper__dbt_cloud_host_url` | `audit_helper__dbt_host_url` |

**Action required**: Update your `dbt_project.yml` if you have this variable configured. See the [dbt Variables Reference](./dbt-variables-reference.md#audit_helper__dbt_host_url) for details.

## New Feature: Row-Level Detail Persistence

When the `full` validation runs, you can now optionally persist the row-level comparison data into a dedicated detail table per mart model (`validation_log_detail__<mart_table>`). This makes investigating mismatches much easier -- no need to re-run the comparison query manually.

See the [README](../README.md#row-level-detail-persistence) and [dbt Variables Reference](./dbt-variables-reference.md#row-level-detail-persistence) for configuration details.
