{# Override of audit_helper 0.14.0: project through get_column_specs so custom column #}
{# expressions apply. #}

{% macro compare_relations(a_relation, b_relation, exclude_columns=[], primary_key=None, summarize=true, limit=None, package_name=none) %}
  {{ return(adapter.dispatch('compare_relations', 'audit_helper_ext')(
      a_relation=a_relation,
      b_relation=b_relation,
      exclude_columns=exclude_columns,
      primary_key=primary_key,
      summarize=summarize,
      limit=limit,
      package_name=package_name
  )) }}
{% endmacro %}


{% macro default__compare_relations(a_relation, b_relation, exclude_columns, primary_key, summarize, limit, package_name) %}

  {% set column_specs = audit_helper_ext.get_column_specs(
      a_relation=a_relation,
      b_relation=b_relation,
      exclude_columns=exclude_columns,
      package_name=package_name
  ) %}

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
