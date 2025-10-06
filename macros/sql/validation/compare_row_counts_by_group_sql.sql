{% macro compare_row_counts_by_group_sql(a_relation, b_relation, group_by) %}
  {{ return(adapter.dispatch('compare_row_counts_by_group_sql', 'audit_helper_ext')(
    a_relation=a_relation,
    b_relation=b_relation,
    group_by=group_by
  )) }}
{% endmacro %}

{% macro default__compare_row_counts_by_group_sql(a_relation, b_relation, group_by) %}

  {% set group_by_csv, group_bys = audit_helper_ext.convert_to_str_and_list(group_by) %}

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
    {% for group_by in group_bys %}
      a_relation_count.{{ group_by }} as {{ group_by }}_a,
      b_relation_count.{{ group_by }} as {{ group_by }}_b,
    {% endfor %}

    {% set count_a = "coalesce(count_a, 0)" -%}
    {{ count_a }} as count_a,

    {% set count_b = "coalesce(count_b, 0)" -%}
    {{ count_b }} as count_b,

    {% set diff -%}
      abs({{ count_a }} - {{ count_b }})
    {%- endset -%}
    {{ diff }} as diff,
    case
      when {{ diff }} > 0 then {{ audit_helper_ext.unicode_prefix() }}'❌'
      else {{ audit_helper_ext.unicode_prefix() }}'✅'
    end as diff_status

  from a_relation_count
  full outer join b_relation_count
    {% for group_by in group_bys -%}
      on {{ dbt.hash("a_relation_count." ~ group_by) }} = {{ dbt.hash("b_relation_count." ~ group_by) }}
      {% if not loop.last %}and {% endif %}
    {% endfor %}
  order by diff desc

{% endmacro %}
