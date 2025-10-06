
{% macro aggregate_data_type_mismatch_detail_sql(
  validation_type_field='validation_type',
  result_field='result'
) %}
  {{ return(adapter.dispatch('aggregate_data_type_mismatch_detail_sql', 'audit_helper_ext')(
    validation_type_field,
    result_field
  )) }}
{% endmacro %}


{% macro sqlserver__aggregate_data_type_mismatch_detail_sql(
  validation_type_field,
  result_field
) %}

  {% set sql -%}
    string_agg(
      case
        when {{ validation_type_field }} = 'schema'
          and (
            --exclude columns that exist in dbt only
            lower({{ json_field_sql(result_field, 'in_a_only') }}) in ('true', '1')
            or lower({{ json_field_sql(result_field, 'in_both') }}) in ('true', '1')
          )
          and lower({{ json_field_sql(result_field, 'has_data_type_match') }}) in ('false', '0')
          then concat(
              {{ json_field_sql(result_field, 'column_name') }}, ': ',
              {{ json_field_sql(result_field, 'a_data_type') }}, {{ audit_helper_ext.unicode_prefix() }}' → ',
              {{ json_field_sql(result_field, 'b_data_type') }},
              char(13) + char(10)
            )
        end, ''
      ) within group (order by {{ json_field_sql(result_field, 'column_name') }})
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro bigquery__aggregate_data_type_mismatch_detail_sql(
  validation_type_field,
  result_field
) %}

  {% set sql -%}
    {{ string_agg_sql() }}(
      case
        when {{ validation_type_field }} = 'schema'
          and (
            --exclude columns that exist in dbt only
            lower({{ json_field_sql(result_field, 'in_a_only') }}) in ('true', '1')
            or lower({{ json_field_sql(result_field, 'in_both') }}) in ('true', '1')
          )
          and lower({{ json_field_sql(result_field, 'has_data_type_match') }}) in ('false', '0')
          then concat(
              {{ json_field_sql(result_field, 'column_name') }}, ': ',
              {{ json_field_sql(result_field, 'a_data_type') }}, ' → ',
              {{ json_field_sql(result_field, 'b_data_type') }},
              '\n'
            )
        end
        order by {{ json_field_sql(result_field, 'column_name') }}
      )
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro default__aggregate_data_type_mismatch_detail_sql(
  validation_type_field,
  result_field
) %}

  {% set sql -%}
    {{ string_agg_sql() }}(
      case
        when {{ validation_type_field }} = 'schema'
          and (
            --exclude columns that exist in dbt only
            lower({{ json_field_sql(result_field, 'in_a_only') }}) in ('true', '1')
            or lower({{ json_field_sql(result_field, 'in_both') }}) in ('true', '1')
          )
          and lower({{ json_field_sql(result_field, 'has_data_type_match') }}) in ('false', '0')
          then concat(
              {{ json_field_sql(result_field, 'column_name') }}, ': ',
              {{ json_field_sql(result_field, 'a_data_type') }}, ' → ',
              {{ json_field_sql(result_field, 'b_data_type') }},
              '\n'
            )
        end
      )
      within group (order by {{ json_field_sql(result_field, 'column_name') }})
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}
