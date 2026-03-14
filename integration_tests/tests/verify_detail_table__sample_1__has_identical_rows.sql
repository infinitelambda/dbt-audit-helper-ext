-- Verify that when store_matched_rows=true, identical rows ARE persisted.
-- Returns a failing row if no identical rows exist.
-- This test should only be run after validate-detail-store-with-matched.

{% set log_relation = ref('validation_log') %}
{% set detail_relation = log_relation.database ~ '.' ~ log_relation.schema ~ '.validation_log_detail__sample_1' %}

with check_identical as (
    select count(*) as cnt
    from {{ detail_relation }}
    where dbt_audit_row_status = 'identical'
)

select 1 as failure
from check_identical
where cnt = 0
