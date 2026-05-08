
{% macro aggregate_schema_mismatches_sql(
  validation_type_field='validation_type',
  result_field='result'
) %}
  {{ return(adapter.dispatch('aggregate_schema_mismatches_sql', 'audit_helper_ext')(
    validation_type_field,
    result_field
  )) }}
{% endmacro %}


{# Schema rows are already gated upstream by filter_schema_validation_enabled_errors. #}
{# Read side just rolls up whatever drift attributes the JSON carries. #}
{% macro _schema_mismatches_presence_predicate(result_field) %}
  {{ return("(lower(" ~ json_field_sql(result_field, 'in_a_only') ~ ") in ('true', '1') or lower(" ~ json_field_sql(result_field, 'in_both') ~ ") in ('true', '1'))") }}
{% endmacro %}


{% macro sqlserver__aggregate_schema_mismatches_sql(
  validation_type_field,
  result_field
) %}

  {% set sql -%}
    string_agg(
      case
        when {{ validation_type_field }} = 'schema'
          and {{ audit_helper_ext._schema_mismatches_presence_predicate(result_field) }}
          and lower({{ json_field_sql(result_field, 'has_data_type_match') }}) in ('false', '0')
          then concat(
              {{ audit_helper_ext.unicode_prefix() }}'• ',
              {{ json_field_sql(result_field, 'column_name') }}, ': ',
              {{ json_field_sql(result_field, 'a_data_type') }}, {{ audit_helper_ext.unicode_prefix() }}' → ',
              {{ json_field_sql(result_field, 'b_data_type') }},
              char(13) + char(10)
            )
        end, ''
      )
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro bigquery__aggregate_schema_mismatches_sql(
  validation_type_field,
  result_field
) %}

  {% set sql -%}
    {{ string_agg_sql() }}(
      case
        when {{ validation_type_field }} = 'schema'
          and {{ audit_helper_ext._schema_mismatches_presence_predicate(result_field) }}
          and lower({{ json_field_sql(result_field, 'has_data_type_match') }}) in ('false', '0')
          then concat(
              '• ',
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


{% macro postgres__aggregate_schema_mismatches_sql(
  validation_type_field,
  result_field
) %}

  {% set sql -%}
    string_agg(
      case
        when {{ validation_type_field }} = 'schema'
          and {{ audit_helper_ext._schema_mismatches_presence_predicate(result_field) }}
          and lower({{ json_field_sql(result_field, 'has_data_type_match') }}) in ('false', '0')
          then concat(
              '• ',
              {{ json_field_sql(result_field, 'column_name') }}, ': ',
              {{ json_field_sql(result_field, 'a_data_type') }}, ' → ',
              {{ json_field_sql(result_field, 'b_data_type') }},
              E'\n'
            )
        end, '' order by {{ json_field_sql(result_field, 'column_name') }}
      )
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro default__aggregate_schema_mismatches_sql(
  validation_type_field,
  result_field
) %}

  {%- set has_data_type_match = json_field_sql(result_field, 'has_data_type_match') -%}
  {%- set has_ordinal_position_match = json_field_sql(result_field, 'has_ordinal_position_match') -%}
  {%- set has_character_maximum_length_match = json_field_sql(result_field, 'has_character_maximum_length_match') -%}
  {%- set has_numeric_precision_match = json_field_sql(result_field, 'has_numeric_precision_match') -%}
  {%- set has_numeric_scale_match = json_field_sql(result_field, 'has_numeric_scale_match') -%}
  {%- set has_is_nullable_match = json_field_sql(result_field, 'has_is_nullable_match') -%}
  {%- set in_a_only = json_field_sql(result_field, 'in_a_only') -%}
  {%- set in_both = json_field_sql(result_field, 'in_both') -%}

  {# Row-level WHEN: any has_*_match attribute is false. #}
  {%- set row_predicate_parts = [
    "lower(" ~ has_data_type_match ~ ") in ('false', '0')",
    "lower(coalesce(" ~ has_ordinal_position_match ~ ", 'true')) in ('false', '0')",
    "lower(coalesce(" ~ has_character_maximum_length_match ~ ", 'true')) in ('false', '0')",
    "lower(coalesce(" ~ has_numeric_precision_match ~ ", 'true')) in ('false', '0')",
    "lower(coalesce(" ~ has_numeric_scale_match ~ ", 'true')) in ('false', '0')",
    "lower(coalesce(" ~ has_is_nullable_match ~ ", 'true')) in ('false', '0')"
  ] -%}
  {%- set row_predicate = row_predicate_parts | join(' or ') -%}

  {%- set presence_predicate = "lower(" ~ in_a_only ~ ") in ('true', '1') or lower(" ~ in_both ~ ") in ('true', '1')" -%}

  {# Snowflake's concat_ws poisons the result to NULL when any argument is NULL, #}
  {# so we use array_to_string(array_compact(array_construct(...))) which skips NULLs. #}
  {% set sql -%}
    {{ string_agg_sql() }}(
      case
        when {{ validation_type_field }} = 'schema'
          and ({{ presence_predicate }})
          and ({{ row_predicate }})
          then concat(
              '• ',
              {{ json_field_sql(result_field, 'column_name') }}, ': ',
              array_to_string(array_compact(array_construct(
                case when lower({{ has_data_type_match }}) in ('false', '0')
                  then concat('type ', coalesce({{ json_field_sql(result_field, 'a_data_type') }}, 'null'),
                              ' → ', coalesce({{ json_field_sql(result_field, 'b_data_type') }}, 'null')) end,
                case when lower(coalesce({{ has_character_maximum_length_match }}, 'true')) in ('false', '0')
                  then concat('length ', coalesce({{ json_field_sql(result_field, 'a_character_maximum_length') }}, 'null'),
                              ' → ', coalesce({{ json_field_sql(result_field, 'b_character_maximum_length') }}, 'null')) end,
                case when lower(coalesce({{ has_numeric_precision_match }}, 'true')) in ('false', '0')
                  then concat('precision ', coalesce({{ json_field_sql(result_field, 'a_numeric_precision') }}, 'null'),
                              ' → ', coalesce({{ json_field_sql(result_field, 'b_numeric_precision') }}, 'null')) end,
                case when lower(coalesce({{ has_numeric_scale_match }}, 'true')) in ('false', '0')
                  then concat('scale ', coalesce({{ json_field_sql(result_field, 'a_numeric_scale') }}, 'null'),
                              ' → ', coalesce({{ json_field_sql(result_field, 'b_numeric_scale') }}, 'null')) end,
                case when lower(coalesce({{ has_is_nullable_match }}, 'true')) in ('false', '0')
                  then concat('nullable ', coalesce({{ json_field_sql(result_field, 'a_is_nullable') }}, 'null'),
                              ' → ', coalesce({{ json_field_sql(result_field, 'b_is_nullable') }}, 'null')) end,
                case when lower(coalesce({{ has_ordinal_position_match }}, 'true')) in ('false', '0')
                  then concat('position ', coalesce({{ json_field_sql(result_field, 'a_ordinal_position') }}, 'null'),
                              ' → ', coalesce({{ json_field_sql(result_field, 'b_ordinal_position') }}, 'null')) end,
                null
              )), ', '),
              '\n'
            )
        end
      )
      within group (order by {{ json_field_sql(result_field, 'column_name') }})
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro databricks__aggregate_schema_mismatches_sql(
  validation_type_field,
  result_field
) %}

  {% set sql -%}
    array_join(
      collect_list(
        case
          when {{ validation_type_field }} = 'schema'
            and {{ audit_helper_ext._schema_mismatches_presence_predicate(result_field) }}
            and lower({{ json_field_sql(result_field, 'has_data_type_match') }}) in ('false', '0')
            then concat(
                '• ',
                {{ json_field_sql(result_field, 'column_name') }}, ': ',
                {{ json_field_sql(result_field, 'a_data_type') }}, ' → ',
                {{ json_field_sql(result_field, 'b_data_type') }},
                '\n'
              )
        end
      ),
      ''
    )
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}
