{# Upstream row count validation filter macros #}

{% macro filter_upstream_row_count_validation_zero(row) %}
  {{ return(row['ROW_COUNT'] == 0) }}
{% endmacro %}
