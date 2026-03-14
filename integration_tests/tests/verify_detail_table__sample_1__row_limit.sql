-- Verify that store_comparison_data_limit caps the number of persisted rows.
-- sample_limit=2 limits to 2 sampled PKs; each modified PK produces 2 rows, so max is 4.
-- This test should only be run after validate-detail-store-with-limit.

{% set log_relation = ref('validation_log') %}
{% set detail_relation = log_relation.database ~ '.' ~ log_relation.schema ~ '.validation_log_detail__sample_1' %}

with total as (
    select count(*) as cnt
    from {{ detail_relation }}
)

select cnt as row_count, 4 as max_expected
from total
where cnt > 4
