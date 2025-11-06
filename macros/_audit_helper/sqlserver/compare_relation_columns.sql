{# SQL Server-specific override for compare_relation_columns #}
{# SQL Server doesn't support: #}
{#   1. Boolean expressions in COALESCE - use CAST to convert to bit (0/1) #}
{#   2. USING clause in joins - use ON instead #}

{% macro sqlserver__compare_relation_columns(a_relation, b_relation) %}

with a_cols as (
    {{ audit_helper.get_columns_in_relation_sql(a_relation) }}
),

b_cols as (
    {{ audit_helper.get_columns_in_relation_sql(b_relation) }}
)

select
    coalesce(a_cols.column_name, b_cols.column_name) as column_name,
    a_cols.ordinal_position as a_ordinal_position,
    b_cols.ordinal_position as b_ordinal_position,
    a_cols.data_type as a_data_type,
    b_cols.data_type as b_data_type,
    cast(case
        when a_cols.ordinal_position = b_cols.ordinal_position then 1
        else 0
    end as bit) as has_ordinal_position_match,
    cast(case
        when a_cols.data_type = b_cols.data_type then 1
        else 0
    end as bit) as has_data_type_match,
    cast(case when a_cols.data_type is not null and b_cols.data_type is null then 1 else 0 end as bit) as in_a_only,
    cast(case when b_cols.data_type is not null and a_cols.data_type is null then 1 else 0 end as bit) as in_b_only,
    cast(case when b_cols.data_type is not null and a_cols.data_type is not null then 1 else 0 end as bit) as in_both
from a_cols
full outer join b_cols on a_cols.column_name = b_cols.column_name
order by coalesce(a_cols.ordinal_position, b_cols.ordinal_position)

{% endmacro %}
