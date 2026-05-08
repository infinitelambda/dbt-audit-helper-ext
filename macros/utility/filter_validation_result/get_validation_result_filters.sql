{% macro get_validation_result_filters(validation_type) %}
  {{ return(adapter.dispatch('get_validation_result_filters', 'audit_helper_ext')(validation_type=validation_type)) }}
{% endmacro %}

{% macro default__get_validation_result_filters(validation_type) %}

  {% set all_filters = var('audit_helper__validation_result_filters', [
    namespace(
      name='count__mismatch',
      description='Row counts do not match between A and B',
      macro='filter_count_validation_mismatch',
      validation_type='count',
      failed_calc=namespace(agg='<irrelevant>', column='TOTAL_RECORDS')
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
      name='schema__mismatch_ordinal_position',
      description='Column order differs between A and B',
      macro='filter_schema_validation_mismatch_ordinal_position',
      validation_type='schema'
    ),
    namespace(
      name='schema__mismatch_character_maximum_length',
      description='Text character_maximum_length differs between A and B',
      macro='filter_schema_validation_mismatch_character_maximum_length',
      validation_type='schema'
    ),
    namespace(
      name='schema__mismatch_numeric_precision',
      description='Numeric precision differs between A and B',
      macro='filter_schema_validation_mismatch_numeric_precision',
      validation_type='schema'
    ),
    namespace(
      name='schema__mismatch_numeric_scale',
      description='Numeric scale differs between A and B',
      macro='filter_schema_validation_mismatch_numeric_scale',
      validation_type='schema'
    ),
    namespace(
      name='schema__mismatch_is_nullable',
      description='Nullability (NOT NULL constraint) differs between A and B',
      macro='filter_schema_validation_mismatch_is_nullable',
      validation_type='schema'
    ),
    namespace(
      name='schema__in_a_only',
      description='Columns exist in A but missing in B',
      macro='filter_schema_validation_in_a_only',
      validation_type='schema'
    ),
    namespace(
      name='full__in_a_not_b',
      description='Rows exist in A but missing in B',
      macro='filter_full_validation_in_a_not_b',
      validation_type='full',
      failed_calc=namespace(agg='sum', column='COUNT')
    ),
    namespace(
      name='full__in_b_not_a',
      description='Rows exist in B but missing in A',
      macro='filter_full_validation_in_b_not_a',
      validation_type='full',
      failed_calc=namespace(agg='sum', column='COUNT')
    ),
    namespace(
      name='upstream_row_count__equal_zero',
      description='Upstream row count is zero',
      macro='filter_upstream_row_count_validation_equal_zero',
      validation_type='upstream_row_count'
    )
  ]) %}

  {% set filtered_list = all_filters | selectattr('validation_type', 'equalto', validation_type | lower) | list %}

  {{ return(filtered_list) }}

{% endmacro %}
