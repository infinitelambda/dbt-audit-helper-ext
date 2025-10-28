{% macro filter_count_validation_mismatch(row) %}
  {{ return(row['IN_A'] != row['IN_B']) }}
{% endmacro %}

{% macro filter_count_validation_equal_zero(row) %}
  {{ return(row['IN_A'] == row['IN_B'] and row['IN_B'] == 0) }}
{% endmacro %}
