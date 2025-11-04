{% macro get_actual_column_name(row, column_name) %}
  {{ return(adapter.dispatch('get_actual_column_name', 'audit_helper_ext')(row=row, column_name=column_name)) }}
{% endmacro %}


{% macro default__get_actual_column_name(row, column_name) %}

  {% set actual_column = none %}
  {% for col_name in row.keys() %}
    {% if col_name | upper == column_name | upper %}
      {% set actual_column = col_name %}
    {% endif %}
  {% endfor %}

  {% if actual_column %}
    {{ return(row[actual_column]) }}
  {% else %}
    {{ return(none) }}
  {% endif %}

{% endmacro %}
