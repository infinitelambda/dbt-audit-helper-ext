{# Override at v0.12: upstream uses `column_to_compare` both as a SQL identifier and as the #}
{# reported label, so a quoted identifier leaks quotes into the report. `column_label` keeps #}
{# the two apart -- pass the quoted name to compare, the bare name to display. #}

{% macro compare_column_values_verbose(a_query, b_query, primary_key, column_to_compare, column_label=none) -%}
  {{ return(adapter.dispatch('compare_column_values_verbose', 'audit_helper_ext')(
      a_query, b_query, primary_key, column_to_compare, column_label
  )) }}
{%- endmacro %}


{% macro default__compare_column_values_verbose(a_query, b_query, primary_key, column_to_compare, column_label=none) -%}

{% set column_label = column_label or column_to_compare %}

with a_query as (
    {{ a_query }}
),

b_query as (
    {{ b_query }}
)
    select
        coalesce(a_query.{{ primary_key }}, b_query.{{ primary_key }}) as primary_key,

        {% if target.name == 'postgres' or target.name == 'redshift' %}
            '{{ column_label }}'::text as column_name,
        {% else %}
            '{{ column_label }}' as column_name,
        {% endif %}

        coalesce(
            a_query.{{ column_to_compare }} = b_query.{{ column_to_compare }} and
                a_query.{{ primary_key }} is not null and b_query.{{ primary_key }} is not null,
            (a_query.{{ column_to_compare }} is null and b_query.{{ column_to_compare }} is null),
            false
        ) as perfect_match,
        a_query.{{ column_to_compare }} is null and a_query.{{ primary_key }} is not null as null_in_a,
        b_query.{{ column_to_compare }} is null and b_query.{{ primary_key }} is not null as null_in_b,
        a_query.{{ primary_key }} is null as missing_from_a,
        b_query.{{ primary_key }} is null as missing_from_b,
        coalesce(
            a_query.{{ primary_key }} is not null and b_query.{{ primary_key }} is not null and
            -- ensure that neither value is missing before considering it a conflict
            (
                a_query.{{ column_to_compare }} != b_query.{{ column_to_compare }} or -- two not-null values that do not match
                (a_query.{{ column_to_compare }} is not null and b_query.{{ column_to_compare }} is null) or -- null in b and not null in a
                (a_query.{{ column_to_compare }} is null and b_query.{{ column_to_compare }} is not null) -- null in a and not null in b
            ),
            false
        ) as conflicting_values
        -- considered a conflict if the values do not match AND at least one of the values is not null.

    from a_query

    full outer join b_query on (a_query.{{ primary_key }} = b_query.{{ primary_key }})

{% endmacro %}
