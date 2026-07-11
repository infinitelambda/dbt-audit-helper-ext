{#-
  DuckDB override for audit_helper's _count_num_rows_in_status.

  The upstream default__ emits `count(distinct a, b) over (...)`, which DuckDB rejects:
  it supports neither multi-argument count(distinct) nor count(distinct) inside a window
  function. Like the postgres__ and databricks__ branches, DuckDB uses the dense_rank
  workaround shipped by audit_helper. This macro is picked up via the `audit_helper`
  dispatch search order (audit_helper_ext first) configured in dbt_project.yml.
-#}
{%- macro duckdb___count_num_rows_in_status() -%}
    {{ audit_helper._count_num_rows_in_status_without_distinct_window_func() }}
{% endmacro %}
