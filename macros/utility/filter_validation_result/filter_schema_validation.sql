{# Schema validation filter macros #}

{% macro filter_schema_validation(row) %}
  {{ return(row['A_DATA_TYPE'] != row['B_DATA_TYPE']) }}
{% endmacro %}
