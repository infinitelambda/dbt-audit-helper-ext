{% macro get_intersecting_columns(a_relation, b_relation, exclude_columns=[]) %}
  {{ return(adapter.dispatch('get_intersecting_columns', 'audit_helper_ext')(
    a_relation=a_relation,
    b_relation=b_relation,
    exclude_columns=exclude_columns
  )) }}
{% endmacro %}


{% macro default__get_intersecting_columns(a_relation, b_relation, exclude_columns) %}

  {% set a_cols = dbt_utils.get_filtered_columns_in_relation(a_relation) %}
  {% set b_cols = dbt_utils.get_filtered_columns_in_relation(b_relation) %}
  {% set exclude_lower = exclude_columns | map('lower') | list %}

  {% set columns = [] %}
  {% for col in a_cols %}
    {% if col in b_cols and col | lower not in exclude_lower %}
      {% do columns.append(col) %}
    {% endif %}
  {% endfor %}

  {{ return(columns) }}

{% endmacro %}
