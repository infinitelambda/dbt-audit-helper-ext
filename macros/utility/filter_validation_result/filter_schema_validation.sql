{% macro filter_schema_validation_mismatch_data_type(row) %}
  {{ return(not row['HAS_DATA_TYPE_MATCH'] and row["IN_BOTH"]) }}
{% endmacro %}

{% macro filter_schema_validation_errors(row) %}
  {{ return(not row['HAS_DATA_TYPE_MATCH'] or row['IN_A_ONLY'] or row['IN_B_ONLY']) }}
{% endmacro %}
