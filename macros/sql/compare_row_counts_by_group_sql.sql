{% macro compare_row_counts_by_group_sql(a_relation, b_relation, group_by) %}
  {{ return(adapter.dispatch('compare_row_counts_by_group_sql', 'audit_helper_ext')(
    a_relation=a_relation,
    b_relation=b_relation,
    group_by=group_by
  )) }}
{% endmacro %}

{% macro default__compare_row_counts_by_group_sql(a_relation, b_relation, group_by) %}

  {% set group_by_csv, _ = audit_helper_ext.convert_to_str_and_list(group_by) %}

  with a_relation_count as (
    select
      {{ group_by_csv }},
      count(*) as count_a
    from {{ a_relation }}
    group by {{ group_by_csv }}
  ),

  b_relation_count as (
    select
      {{ group_by_csv }},
      count(*) as count_b
    from {{ b_relation }}
    group by {{ group_by_csv }}
  )

  select
    {{ group_by_csv }},

    {% set count_a = "coalesce(count_a, 0)" -%}
    {{ count_a }} as count_a,

    {% set count_b = "coalesce(count_b, 0)" -%}
    {{ count_b }} as count_b,

    {% set diff -%}
      abs({{ count_a }} - {{ count_b }})
    {%- endset -%}
    {{ diff }} as diff,

    case when {{ diff }} > 0 then '❌' else '✅' end as diff_status

  from a_relation_count
  full outer join b_relation_count using ({{ group_by_csv }})
  order by {{ group_by_csv }}

{% endmacro %}
