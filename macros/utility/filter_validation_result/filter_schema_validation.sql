{% macro filter_schema_validation_mismatch_data_type(row) %}
  {{ return(row['A_DATA_TYPE'] != row['B_DATA_TYPE']) }}
{% endmacro %}
