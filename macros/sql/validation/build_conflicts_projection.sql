{% macro build_conflicts_projection(columns, column_specs=none) %}
  {{ return(adapter.dispatch('build_conflicts_projection', 'audit_helper_ext')(
      columns=columns,
      column_specs=column_specs
  )) }}
{% endmacro %}


{% macro default__build_conflicts_projection(columns, column_specs) %}

  {% if not column_specs %}
    {{ return(columns | join(',')) }}
  {% endif %}

  {# Specs cover the whole relation; the conflicts path compares an explicit subset of it. #}
  {% set select_by_name = {} %}
  {% for spec in column_specs %}
    {% do select_by_name.update({spec.name | upper: spec.select}) %}
  {% endfor %}

  {% set projected = [] %}
  {% for column in columns %}
    {# Unmatched columns keep their bare identifier: the downstream pivot builds `<column>__a`
       aliases from the raw name, so the spec's `... as "column"` alias is what keeps those
       references resolving. #}
    {% do projected.append(select_by_name.get(column | upper, column)) %}
  {% endfor %}

  {{ return(projected | join(',')) }}

{% endmacro %}
