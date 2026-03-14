{{ config(tags=['detail_persistence']) }}
-- Verify that when store_matched_rows=false (default), no identical rows are persisted.
-- Returns failing rows if any identical rows exist.

{% set log_relation = ref('validation_log') %}
{% set detail_relation = log_relation.database ~ '.' ~ log_relation.schema ~ '.validation_log_detail__sample_1' %}

select dbt_audit_row_status, count(*) as cnt
from {{ detail_relation }}
where dbt_audit_row_status = 'identical'
group by dbt_audit_row_status
having count(*) > 0
