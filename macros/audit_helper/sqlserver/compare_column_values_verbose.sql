{# Override at v0.12 #}

{% macro sqlserver__compare_column_values_verbose(a_query, b_query, primary_key, column_to_compare) -%}

    select
        coalesce(a_query.{{ primary_key }}, b_query.{{ primary_key }}) as primary_key,
        '{{ column_to_compare }}' as column_name,
        case
            when a_query.{{ column_to_compare }} = b_query.{{ column_to_compare }}
                and a_query.{{ primary_key }} is not null
                and b_query.{{ primary_key }} is not null then cast(1 as bit)
            when a_query.{{ column_to_compare }} is null
                and b_query.{{ column_to_compare }} is null then cast(1 as bit)
            else cast(0 as bit)
        end as perfect_match,
        case
            when a_query.hk_h_products is null and a_query.dbt_audit_helper_pk is not null then cast(1 as bit)
            else cast(0 as bit)
        end as null_in_a,
        case
            when b_query.{{ column_to_compare }} is null and b_query.{{ primary_key }} is not null then cast(1 as bit)
            else cast(0 as bit)
        end as null_in_b,
        case
            when a_query.{{ primary_key }} is null then cast(1 as bit)
            else cast(0 as bit)
        end as missing_from_a,
        case
            when b_query.{{ primary_key }} is null then cast(1 as bit)
            else cast(0 as bit)
        end as missing_from_b,
        case
            when a_query.{{ primary_key }} is not null and b_query.{{ primary_key }} is not null and
                -- ensure that neither value is missing before considering it a conflict
                (
                    a_query.{{ column_to_compare }} != b_query.{{ column_to_compare }} or -- two not-null values that do not match
                    (a_query.{{ column_to_compare }} is not null and b_query.{{ column_to_compare }} is null) or -- null in b and not null in a
                    (a_query.{{ column_to_compare }} is null and b_query.{{ column_to_compare }} is not null) -- null in a and not null in b
                ) then cast(1 as bit)
            else cast(0 as bit)
        end as conflicting_values
        -- considered a conflict if the values do not match AND at least one of the values is not null.

    from (
        {{ a_query }}
    ) as a_query

    full outer join (
        {{ b_query }}
    ) as b_query on (a_query.{{ primary_key }} = b_query.{{ primary_key }})

{% endmacro %}