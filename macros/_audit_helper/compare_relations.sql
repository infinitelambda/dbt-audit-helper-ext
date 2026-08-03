{% macro compare_relations(a_relation, b_relation, exclude_columns=[], primary_key=None, summarize=true, limit=None) %}
  {{ return(adapter.dispatch('compare_relations', 'audit_helper_ext')(
      a_relation=a_relation,
      b_relation=b_relation,
      exclude_columns=exclude_columns,
      primary_key=primary_key,
      summarize=summarize,
      limit=limit
  )) }}
{% endmacro %}


{% macro default__compare_relations(a_relation, b_relation, exclude_columns, primary_key, summarize, limit) %}

  {% set column_specs = audit_helper_ext.get_column_specs(a_relation, b_relation, exclude_columns) %}

  {% set column_selection %}
    {% for spec in column_specs %}
      {{ spec.select }}
      {% if not loop.last %}, {% endif %}
    {% endfor %}
  {% endset %}

  {% set a_query %}
  select

    {{ column_selection }}

  from {{ a_relation }}
  {% endset %}

  {% set b_query %}
  select

    {{ column_selection }}

  from {{ b_relation }}
  {% endset %}

  {{ audit_helper.compare_queries(a_query, b_query, primary_key, summarize, limit) }}

{% endmacro %}
