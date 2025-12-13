
{% macro aggregate_upstream_row_count_sql(
  validation_type_field='validation_type',
  result_field='result',
  row_count_field='row_count',
  model_name_field='model_name'
) %}
  {{ return(adapter.dispatch('aggregate_upstream_row_count_sql', 'audit_helper_ext')(
    validation_type_field,
    result_field,
    row_count_field,
    model_name_field
  )) }}
{% endmacro %}


{% macro sqlserver__aggregate_upstream_row_count_sql(
  validation_type_field,
  result_field,
  row_count_field,
  model_name_field
) %}

  {% set sql -%}
    string_agg(
      case
        when {{ validation_type_field }} = 'upstream_row_count'
          then concat(
              case
                when {{ json_field_sql(result_field, row_count_field) }} <> '0' then {{ audit_helper_ext.unicode_prefix() }}'✅ '
                when {{ json_field_sql(result_field, row_count_field) }} = '0' then {{ audit_helper_ext.unicode_prefix() }}'🟡 '
              end,
              {{ json_field_sql(result_field, model_name_field) }}, {{ audit_helper_ext.unicode_prefix() }}': ',
              {{ json_field_sql(result_field, row_count_field) }}, {{ audit_helper_ext.unicode_prefix() }}' row(s)',
              char(13) + char(10)
            )
        end, ''
      )
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro bigquery__aggregate_upstream_row_count_sql(
  validation_type_field,
  result_field,
  row_count_field,
  model_name_field
) %}

  {% set sql -%}
    {{ string_agg_sql() }}(
      case
        when {{ validation_type_field }} = 'upstream_row_count'
          then concat(
              case
                when {{ json_field_sql(result_field, row_count_field) }} <> '0' then '✅ '
                when {{ json_field_sql(result_field, row_count_field) }} = '0' then '🟡 '
              end,
              {{ json_field_sql(result_field, model_name_field) }}, ': ',
              {{ json_field_sql(result_field, row_count_field) }}, ' row(s)',
              '\n'
            )
        end
        order by {{ safe_cast_sql() }}({{ json_field_sql(result_field, row_count_field) }} as integer)
      )
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro postgres__aggregate_upstream_row_count_sql(
  validation_type_field,
  result_field,
  row_count_field,
  model_name_field
) %}

  {% set sql -%}
    string_agg(
      case
        when {{ validation_type_field }} = 'upstream_row_count'
          then concat(
              case
                when {{ json_field_sql(result_field, row_count_field) }} <> '0' then '✅ '
                when {{ json_field_sql(result_field, row_count_field) }} = '0' then '🟡 '
              end,
              {{ json_field_sql(result_field, model_name_field) }}, ': ',
              {{ json_field_sql(result_field, row_count_field) }}, ' row(s)',
              E'\n'
            )
        end, '' order by cast({{ json_field_sql(result_field, row_count_field) }} as integer)
      )
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro default__aggregate_upstream_row_count_sql(
  validation_type_field,
  result_field,
  row_count_field,
  model_name_field
) %}

  {% set sql -%}
    {{ string_agg_sql() }}(
      case
        when {{ validation_type_field }} = 'upstream_row_count'
          then concat(
              case
                when {{ json_field_sql(result_field, row_count_field) }} <> '0' then '✅ '
                when {{ json_field_sql(result_field, row_count_field) }} = '0' then '🟡 '
              end,
              {{ json_field_sql(result_field, model_name_field) }}, ': ',
              {{ json_field_sql(result_field, row_count_field) }}, ' row(s)',
              '\n'
            )
        end
      )
      within group (order by {{ safe_cast_sql() }}({{ json_field_sql(result_field, row_count_field) }} as integer))
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro databricks__aggregate_upstream_row_count_sql(
  validation_type_field,
  result_field,
  row_count_field,
  model_name_field
) %}

  {% set sql -%}
    array_join(
      collect_list(
        case
          when {{ validation_type_field }} = 'upstream_row_count'
            then concat(
                case
                  when {{ json_field_sql(result_field, row_count_field) }} <> '0' then '✅ '
                  when {{ json_field_sql(result_field, row_count_field) }} = '0' then '🟡 '
                end,
                {{ json_field_sql(result_field, model_name_field) }}, ': ',
                {{ json_field_sql(result_field, row_count_field) }}, ' row(s)',
                '\n'
              )
        end
      ),
      ''
    )
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}
