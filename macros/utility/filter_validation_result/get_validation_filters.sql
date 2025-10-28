{% macro get_validation_filters(validation_type) %}
  {{ return(adapter.dispatch('get_validation_filters', 'audit_helper_ext')(validation_type=validation_type)) }}
{% endmacro %}

{% macro default__get_validation_filters(validation_type) %}

  {% set all_filters = [
    namespace(
      name='count__mismatch',
      description='Rows where in_a != in_b',
      macro='filter_count_validation_mismatch',
      validation_type='count'
    ),
    namespace(
      name='count__equal_zero',
      description='Rows where in_a = in_b = 0',
      macro='filter_count_validation_equal_zero',
      validation_type='count'
    ),
    namespace(
      name='schema__mismatch_data_type',
      description='Columns where a_data_type != b_data_type',
      macro='filter_schema_validation_mismatch_data_type',
      validation_type='schema'
    ),
    namespace(
      name='full__in_a_not_b',
      description='Rows in A but not in B',
      macro='filter_full_validation_in_a_not_b',
      validation_type='full'
    ),
    namespace(
      name='full__in_b_not_a',
      description='Rows in B but not in A',
      macro='filter_full_validation_in_b_not_a',
      validation_type='full'
    ),
    namespace(
      name='full__mismatch',
      description='Rows in both but values do not match',
      macro='filter_full_validation_mismatch',
      validation_type='full'
    ),
    namespace(
      name='upstream_row_count__equal_zero',
      description='Rows where row count = 0',
      macro='filter_upstream_row_count_validation_equal_zero',
      validation_type='upstream_row_count'
    )
  ] %}

  {% set filtered_list = all_filters | selectattr('validation_type', 'equalto', validation_type | lower) | list %}
  {{ return(filtered_list) }}

{% endmacro %}
