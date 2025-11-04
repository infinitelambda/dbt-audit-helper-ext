{% macro filter_full_validation_in_a_not_b(row) %}
  {% set in_a = audit_helper_ext.get_actual_column_name(row, 'IN_A') %}
  {% set in_b = audit_helper_ext.get_actual_column_name(row, 'IN_B') %}
  {{ return(in_a and not in_b) }}
{% endmacro %}

{% macro filter_full_validation_in_b_not_a(row) %}
  {% set in_a = audit_helper_ext.get_actual_column_name(row, 'IN_A') %}
  {% set in_b = audit_helper_ext.get_actual_column_name(row, 'IN_B') %}
  {{ return(in_b and not in_a) }}
{% endmacro %}
