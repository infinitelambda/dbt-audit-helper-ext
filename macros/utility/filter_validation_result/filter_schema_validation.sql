{% macro filter_schema_validation_mismatch_data_type(row) %}
  {% set has_data_type_match_col = audit_helper_ext.get_actual_column_name(row, 'HAS_DATA_TYPE_MATCH') %}
  {% set in_both_col = audit_helper_ext.get_actual_column_name(row, 'IN_BOTH') %}
  {% set in_a_only = audit_helper_ext.get_actual_column_name(row, 'IN_A_ONLY') %}
  {{ return(not row[has_data_type_match_col] and (row[in_a_only] or row[in_both_col])) }}
{% endmacro %}

{% macro filter_schema_validation_errors(row) %}
  {% set has_data_type_match_col = audit_helper_ext.get_actual_column_name(row, 'HAS_DATA_TYPE_MATCH') %}
  {% set in_a_only_col = audit_helper_ext.get_actual_column_name(row, 'IN_A_ONLY') %}
  {% set in_b_only_col = audit_helper_ext.get_actual_column_name(row, 'IN_B_ONLY') %}
  {{ return(not row[has_data_type_match_col] or row[in_a_only_col] or row[in_b_only_col]) }}
{% endmacro %}
