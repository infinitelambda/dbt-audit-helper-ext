{% macro filter_count_validation_mismatch(result) %}
  {% if result.rows | length != 2 %}
    {{ return(false) }}
  {% endif %}
  {% set column_name = audit_helper_ext.get_actual_column_name(result, 'TOTAL_RECORDS') %}
  {% set count_a = result.rows[0][column_name] %}
  {% set count_b = result.rows[1][column_name] %}
  {{ return(count_a != count_b) }}
{% endmacro %}

{% macro filter_count_validation_equal_zero(result) %}
  {% if result.rows | length != 2 %}
    {{ return(false) }}
  {% endif %}
  {% set column_name = audit_helper_ext.get_actual_column_name(result, 'TOTAL_RECORDS') %}
  {% set count_a = result.rows[0][column_name] %}
  {% set count_b = result.rows[1][column_name] %}
  {{ return(count_a == count_b and count_b == 0) }}
{% endmacro %}
