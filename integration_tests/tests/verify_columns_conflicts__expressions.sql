{{ config(tags=['column_expressions']) }}
-- Asserts the Show Column Conflicts drill-down honours `audit_helper__custom_column_expressions`,
-- so it agrees with the `all_col` summary (issue #67): float_value/text_value are perfect matches,
-- precision_value is the single real conflict. Any row emitted here is a disagreement.

{% set dbt_relation = ref('sample_expressions_test') %}

{# The source relation only resolves at run time, so keep introspection out of the parse pass. #}
{% if not execute %}
  select 1 as scenario where false
{% else %}

{% set old_relation = adapter.get_relation(
    database=var('audit_helper__source_database', target.database),
    schema=audit_helper_ext.get_versioned_name(name=var('audit_helper__source_schema', target.schema)),
    identifier=audit_helper_ext.get_old_identifier_name('sample_expressions_test')
) %}

{% set column_specs = audit_helper_ext.get_column_specs(
    a_relation=old_relation,
    b_relation=dbt_relation
) %}

{% set clean_query = audit_helper_ext.show_columns_conflicts_sql(
    a_relation=old_relation,
    b_relation=dbt_relation,
    primary_keys=['id'],
    columns_to_compare=['float_value', 'text_value'],
    summarize=true,
    limit=none,
    column_specs=column_specs
) %}

{% set conflicting_query = audit_helper_ext.show_columns_conflicts_sql(
    a_relation=old_relation,
    b_relation=dbt_relation,
    primary_keys=['id'],
    columns_to_compare=['precision_value'],
    summarize=true,
    limit=none,
    column_specs=column_specs
) %}

{# Same columns as a spaced CSV string, the shape `--args` produces: names must be trimmed
   before matching against the specs. #}
{% set spaced_csv_query = audit_helper_ext.show_columns_conflicts_sql(
    a_relation=old_relation,
    b_relation=dbt_relation,
    primary_keys='id',
    columns_to_compare='float_value, text_value',
    summarize=true,
    limit=none,
    column_specs=column_specs
) %}

with clean_columns as (
    select count(*) as actual, 0 as expected, 'float_value+text_value' as scenario
    from ({{ clean_query }}) as _clean
),

conflicting_column as (
    select count(*) as actual, 1 as expected, 'precision_value' as scenario
    from ({{ conflicting_query }}) as _conflicting
),

spaced_csv_columns as (
    select count(*) as actual, 0 as expected, 'spaced csv' as scenario
    from ({{ spaced_csv_query }}) as _spaced
),

all_scenarios as (
    select * from clean_columns
    union all
    select * from conflicting_column
    union all
    select * from spaced_csv_columns
)

select *
from all_scenarios
where actual != expected

{% endif %}
