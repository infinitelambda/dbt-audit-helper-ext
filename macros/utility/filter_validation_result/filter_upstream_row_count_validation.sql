{% macro filter_upstream_row_count_validation_equal_zero(row) %}
  {% set row_count = audit_helper_ext.get_actual_column_name(row, 'ROW_COUNT') %}
  {{ return(row_count == 0) }}
{% endmacro %}
