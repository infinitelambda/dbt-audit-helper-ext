-- Verify metadata columns are populated correctly.
-- mart_table should be 'sample_1', date_of_process and dbt_cloud_job_start_at should not be null.
-- Returns failing rows for any metadata violation.

{% set log_relation = ref('validation_log') %}
{% set detail_relation = log_relation.database ~ '.' ~ log_relation.schema ~ '.validation_log_detail__sample_1' %}

select mart_table, date_of_process, dbt_cloud_job_start_at
from {{ detail_relation }}
where mart_table != 'sample_1'
   or date_of_process is null
   or dbt_cloud_job_start_at is null
