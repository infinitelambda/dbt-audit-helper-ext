{% macro get_actual_column_name(agate_object, configured_column_name) %}
  {{ return(adapter.dispatch('get_actual_column_name', 'audit_helper_ext')(
    agate_object=agate_object,
    configured_column_name=configured_column_name
  )) }}
{% endmacro %}

{% macro default__get_actual_column_name(agate_object, configured_column_name) %}

  {% if not execute %}
    {{ return(none) }}
  {% endif %}

  {% set configured_upper = configured_column_name | upper %}
  {% if agate_object.column_names is defined %}
    {# agate.Table #}
    {% set available_columns = agate_object.column_names %}
  {% else %}
    {# agate.Row #}
    {% set available_columns = agate_object.keys() %}
  {% endif %}

  {# Try exact match first #}
  {% if configured_column_name in available_columns %}
    {{ return(configured_column_name) }}
  {% endif %}

  {# Try case-insensitive match #}
  {% for actual_column in available_columns %}
    {% if actual_column | upper == configured_upper %}
      {{ return(actual_column) }}
    {% endif %}
  {% endfor %}

  {# Column not found - raise error #}
  {% do exceptions.raise_compiler_error("Column '" ~ configured_column_name ~ "' not found. Available columns: " ~ available_columns | join(', ')) %}
{% endmacro %}
