{{ config(tags=['detail_persistence']) }}
-- Verify custom column expressions are applied on the persisted detail table.
-- The source and target hold deliberately different raw values (3.14159265 vs 3.14,
-- '  HELLO WORLD  ' vs 'hello world'); they only reconcile once the configured
-- expressions run. Every persisted row must therefore be classified as identical.
-- Any other row status means the expressions never reached this code path.
-- Empty result = PASS.

{% set log_relation = ref('validation_log') %}

select
    dbt_audit_row_status,
    count(*) as row_count
from {{ log_relation.database }}.{{ log_relation.schema }}.validation_log_detail__sample_expressions_test
where dbt_audit_row_status != 'identical'
group by dbt_audit_row_status
