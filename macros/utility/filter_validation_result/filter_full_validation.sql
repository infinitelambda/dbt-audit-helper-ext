{% macro filter_full_validation_in_a_not_b(row) %}
  {% set in_a_col = audit_helper_ext.get_actual_column_name(row, 'IN_A') %}
  {% set in_b_col = audit_helper_ext.get_actual_column_name(row, 'IN_B') %}
  {{ return(row[in_a_col] and not row[in_b_col]) }}
{% endmacro %}

{% macro filter_full_validation_in_b_not_a(row) %}
  {% set in_a_col = audit_helper_ext.get_actual_column_name(row, 'IN_A') %}
  {% set in_b_col = audit_helper_ext.get_actual_column_name(row, 'IN_B') %}
  {{ return(row[in_b_col] and not row[in_a_col]) }}
{% endmacro %}
