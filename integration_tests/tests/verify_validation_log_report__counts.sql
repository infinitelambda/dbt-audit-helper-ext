-- Integration test: verify validation_log_report populates count/match fields
-- correctly after validation macros run, on all adapters.
-- Empty result = PASS.

select *
from {{ ref('validation_log_report') }}
where mart_table = 'sample_1'
  and (
    old_relation_row_count is null
    or dbt_relation_row_count is null
    or match_count is null
  )
