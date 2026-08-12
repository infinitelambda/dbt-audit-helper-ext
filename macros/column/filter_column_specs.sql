{% macro filter_column_specs(column_specs, columns) %}
  {{ return(adapter.dispatch('filter_column_specs', 'audit_helper_ext')(
      column_specs=column_specs,
      columns=columns
  )) }}
{% endmacro %}


{% macro default__filter_column_specs(column_specs, columns) %}

  {% set select_by_name = {} %}
  {% for spec in column_specs or [] %}
    {% do select_by_name.update({spec.name | lower: spec}) %}
  {% endfor %}

  {% set filtered = [] %}
  {% for column in columns %}
    {% do filtered.append(select_by_name.get(column | lower, namespace(
        name=column,
        expression=adapter.quote(column),
        select=adapter.quote(column),
        macro_ref=none
    ))) %}
  {% endfor %}

  {{ return(filtered) }}

{% endmacro %}
