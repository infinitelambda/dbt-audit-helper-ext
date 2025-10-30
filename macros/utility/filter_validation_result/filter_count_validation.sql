{% macro filter_count_validation_mismatch(result) %}
  {% if result.rows | length != 2 %}
    {{ return(false) }}
  {% endif %}
  {% set count_a = result.rows[0]['TOTAL_RECORDS'] %}
  {% set count_b = result.rows[1]['TOTAL_RECORDS'] %}
  {{ return(count_a != count_b) }}
{% endmacro %}

{% macro filter_count_validation_equal_zero(result) %}
  {% if result.rows | length != 2 %}
    {{ return(false) }}
  {% endif %}
  {% set count_a = result.rows[0]['TOTAL_RECORDS'] %}
  {% set count_b = result.rows[1]['TOTAL_RECORDS'] %}
  {{ return(count_a == count_b and count_b == 0) }}
{% endmacro %}
