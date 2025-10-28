{% macro get_validation_filters(validation_type) %}
  {{ return(adapter.dispatch('get_validation_filters', 'audit_helper_ext')(validation_type=validation_type)) }}
{% endmacro %}

{% macro default__get_validation_filters(validation_type) %}

  {% set all_filters = [
    namespace(
      name='count__mismatch',
      description='Row counts do not match between A and B',
      macro='filter_count_validation_mismatch',
      validation_type='count'
    ),
    namespace(
      name='count__equal_zero',
      description='Row counts are zero in both A and B',
      macro='filter_count_validation_equal_zero',
      validation_type='count'
    ),
    namespace(
      name='schema__mismatch_data_type',
      description='Column data types differ between A and B',
      macro='filter_schema_validation_mismatch_data_type',
      validation_type='schema'
    ),
    namespace(
      name='full__in_a_not_b',
      description='Rows exist in A but missing in B',
      macro='filter_full_validation_in_a_not_b',
      validation_type='full'
    ),
    namespace(
      name='full__in_b_not_a',
      description='Rows exist in B but missing in A',
      macro='filter_full_validation_in_b_not_a',
      validation_type='full'
    ),
    namespace(
      name='full__mismatch',
      description='Rows exist in both A and B but column values differ',
      macro='filter_full_validation_mismatch',
      validation_type='full'
    ),
    namespace(
      name='upstream_row_count__equal_zero',
      description='Upstream row count is zero',
      macro='filter_upstream_row_count_validation_equal_zero',
      validation_type='upstream_row_count'
    )
  ] %}

  {% set filtered_list = all_filters | selectattr('validation_type', 'equalto', validation_type | lower) | list %}
  {{ return(filtered_list) }}

{% endmacro %}
