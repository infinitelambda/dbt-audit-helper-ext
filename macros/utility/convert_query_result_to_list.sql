{% macro convert_query_result_to_list(result) %}
  {{ return(adapter.dispatch('convert_query_result_to_list', 'audit_helper_ext')(result=result)) }}
{% endmacro %}


{% macro default__convert_query_result_to_list(result) %}

  {% set results = [] %}

  {% for column_name, column in result.columns.items() %}
    {% if results == [] %}
      {% for column_value in column.values() %}
        {% do results.append({column_name: column_value~''}) %}
      {% endfor %}
    {% else %}
      {% for column_value in column.values() %}
        {% set column_value = column_value~'' %}
        {% do results[loop.index0].update({column_name: column_value}) %}
      {% endfor %}
    {% endif %}
  {% endfor %}

  {{ return(results) }}

{% endmacro %}
