{% macro filter_schema_validation_mismatch_data_type(row) %}
  {% set has_data_type_match = audit_helper_ext.get_actual_column_name(row, 'HAS_DATA_TYPE_MATCH') %}
  {% set in_a_only = audit_helper_ext.get_actual_column_name(row, 'IN_A_ONLY') %}
  {{ return(not has_data_type_match and in_a_only) }}
{% endmacro %}

{% macro filter_schema_validation_errors(row) %}
  {% set has_data_type_match = audit_helper_ext.get_actual_column_name(row, 'HAS_DATA_TYPE_MATCH') %}
  {% set in_a_only = audit_helper_ext.get_actual_column_name(row, 'IN_A_ONLY') %}
  {% set in_b_only = audit_helper_ext.get_actual_column_name(row, 'IN_B_ONLY') %}
  {{ return(not has_data_type_match or in_a_only or in_b_only) }}
{% endmacro %}
