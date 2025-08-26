{# Override at v0.12 #}

{% macro sqlserver__compare_queries(a_query, b_query, primary_key=None, summarize=true, limit=None) %}

{%- set base_union_query -%}
    select
        *,
        1 as in_a,
        1 as in_b
    from (
        select * from ({{ a_query }}) a
        {{ dbt.intersect() }}
        select * from ({{ b_query }}) b
    ) a_intersect_b

    union all

    select
        *,
        1 as in_a,
        0 as in_b
    from (
        select * from ({{ a_query }}) a
        {{ dbt.except() }}
        select * from ({{ b_query }}) b
    ) a_except_b

    union all

    select
        *,
        0 as in_a,
        1 as in_b
    from (
        select * from ({{ b_query }}) b
        {{ dbt.except() }}
        select * from ({{ a_query }}) a
    ) b_except_a
{%- endset %}

{%- if summarize %}

select
    *,
    round(100.0 * count / sum(count) over (), 2) as percent_of_total
from (
    select
        in_a,
        in_b,
        count(*) as count
    from (
        {{ base_union_query }}
    ) all_records
    group by in_a, in_b
) summary_stats

{%- else %}

select 
{%- if limit %}
top {{ limit }}
{%- endif %} * 
from (
    {{ base_union_query }}
) all_records
where not (in_a = 1 and in_b = 1)

{%- endif %}

{% endmacro %}