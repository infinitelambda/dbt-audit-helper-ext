{% macro filter_full_validation_in_a_not_b(row) %}
  {{ return(row['IN_A'] and not row['IN_B']) }}
{% endmacro %}

{% macro filter_full_validation_in_b_not_a(row) %}
  {{ return(row['IN_B'] and not row['IN_A']) }}
{% endmacro %}

{% macro filter_full_validation_mismatch(row) %}
  {{ return(row['IN_A'] and row['IN_B'] and not row['is_match']) }}
{% endmacro %}
