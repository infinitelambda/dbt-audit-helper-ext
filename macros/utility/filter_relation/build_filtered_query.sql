{# Builds a filtered SELECT to feed audit_helper.compare_queries (see .yml). Pass the SAME #}
{# `columns` list for both A and B sides so the INTERSECT/EXCEPT set logic lines up. #}

{% macro build_filtered_query(relation, columns=none, exclude_columns=[], filter=none, extra_select=none, column_specs=none) %}
  {{ return(adapter.dispatch('build_filtered_query', 'audit_helper_ext')(
    relation=relation,
    columns=columns,
    exclude_columns=exclude_columns,
    filter=filter,
    extra_select=extra_select,
    column_specs=column_specs
  )) }}
{% endmacro %}


{% macro default__build_filtered_query(relation, columns, exclude_columns, filter, extra_select, column_specs) %}

  {% if columns is none %}
    {% set columns = dbt_utils.get_filtered_columns_in_relation(from=relation, except=exclude_columns) %}
  {% endif %}

  {# String concat (not a {% set %} block) so the value survives return() from a macro call. #}
  {% set quoted_columns = [] %}
  {% if column_specs %}
    {% for spec in column_specs %}
      {% do quoted_columns.append(spec.select) %}
    {% endfor %}
  {% else %}
    {% for column_name in columns %}
      {% do quoted_columns.append(adapter.quote(column_name)) %}
    {% endfor %}
  {% endif %}

  {% set projection = quoted_columns | join(', ') %}
  {% if extra_select %}
    {% set projection = projection ~ ', ' ~ extra_select %}
  {% endif %}

  {% set query = 'select ' ~ projection ~ ' from ' ~ relation %}
  {% if filter %}
    {% set query = query ~ ' where ' ~ filter %}
  {% endif %}

  {{ return(query) }}

{% endmacro %}
