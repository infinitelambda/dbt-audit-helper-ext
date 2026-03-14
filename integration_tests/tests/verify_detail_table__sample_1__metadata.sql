-- Verify metadata columns are populated correctly.
-- dbt_audit_ext_mart_table should be 'sample_1', date_of_process should not be null.
-- Returns failing rows for any metadata violation.

{% set log_relation = ref('validation_log') %}
{% set detail_relation = log_relation.database ~ '.' ~ log_relation.schema ~ '.validation_log_detail__sample_1' %}

select dbt_audit_ext_mart_table, dbt_audit_ext_date_of_process
from {{ detail_relation }}
where dbt_audit_ext_mart_table != 'sample_1'
   or dbt_audit_ext_date_of_process is null
