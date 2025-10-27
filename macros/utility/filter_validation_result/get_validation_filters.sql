{# Generic filter dispatcher - routes to appropriate filter based on validation type #}

{% macro get_validation_filters(validation_type) %}
  {{ return(adapter.dispatch('get_validation_filters', 'audit_helper_ext')(validation_type=validation_type)) }}
{% endmacro %}

{% macro default__get_validation_filters(validation_type) %}
  {% if validation_type | lower == 'count' %}
    {% set count_mismatch = namespace(
      name='count_mismatch',
      description='Rows where in_a != in_b',
      macro='filter_count_validation_mismatch'
    ) %}
    {% set count_zero = namespace(
      name='count_zero',
      description='Rows where in_a = in_b = 0',
      macro='filter_count_validation_zero'
    ) %}
    {{ return([count_mismatch, count_zero]) }}
  {% elif validation_type | lower == 'schema' %}
    {% set schema_mismatch = namespace(
      name='schema_mismatch',
      description='Columns where a_data_type != b_data_type',
      macro='filter_schema_validation'
    ) %}
    {{ return([schema_mismatch]) }}
  {% elif validation_type | lower == 'full' %}
    {% set in_a_not_b = namespace(
      name='in_a_not_b',
      description='Rows in A but not in B',
      macro='filter_full_validation_in_a_not_b'
    ) %}
    {% set in_b_not_a = namespace(
      name='in_b_not_a',
      description='Rows in B but not in A',
      macro='filter_full_validation_in_b_not_a'
    ) %}
    {% set mismatch = namespace(
      name='mismatch',
      description='Rows in both but values do not match',
      macro='filter_full_validation_mismatch'
    ) %}
    {{ return([in_a_not_b, in_b_not_a, mismatch]) }}
  {% elif validation_type | lower == 'upstream_row_count' %}
    {% set row_count_zero = namespace(
      name='row_count_zero',
      description='Rows where row count = 0',
      macro='filter_upstream_row_count_validation_zero'
    ) %}
    {{ return([row_count_zero]) }}
  {% else %}
    {{ return([]) }}
  {% endif %}
{% endmacro %}
