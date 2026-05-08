{% macro filter_schema_validation_mismatch_data_type(row) %}
  {% set has_data_type_match_col = audit_helper_ext.get_actual_column_name(row, 'HAS_DATA_TYPE_MATCH') %}
  {% set in_both_col = audit_helper_ext.get_actual_column_name(row, 'IN_BOTH') %}
  {% set in_a_only = audit_helper_ext.get_actual_column_name(row, 'IN_A_ONLY') %}
  {{ return(not row[has_data_type_match_col] and (row[in_a_only] or row[in_both_col])) }}
{% endmacro %}

{% macro _filter_schema_validation_mismatch_attribute(row, has_match_column) %}
  {% set has_match_col = audit_helper_ext.try_get_actual_column_name(row, has_match_column) %}
  {% if has_match_col is none %}
    {{ return(false) }}
  {% endif %}
  {% set in_both_col = audit_helper_ext.get_actual_column_name(row, 'IN_BOTH') %}
  {{ return(row[in_both_col] and not row[has_match_col]) }}
{% endmacro %}

{% macro filter_schema_validation_mismatch_ordinal_position(row) %}
  {{ return(audit_helper_ext._filter_schema_validation_mismatch_attribute(row, 'HAS_ORDINAL_POSITION_MATCH')) }}
{% endmacro %}

{% macro filter_schema_validation_mismatch_character_maximum_length(row) %}
  {{ return(audit_helper_ext._filter_schema_validation_mismatch_attribute(row, 'HAS_CHARACTER_MAXIMUM_LENGTH_MATCH')) }}
{% endmacro %}

{% macro filter_schema_validation_mismatch_numeric_precision(row) %}
  {{ return(audit_helper_ext._filter_schema_validation_mismatch_attribute(row, 'HAS_NUMERIC_PRECISION_MATCH')) }}
{% endmacro %}

{% macro filter_schema_validation_mismatch_numeric_scale(row) %}
  {{ return(audit_helper_ext._filter_schema_validation_mismatch_attribute(row, 'HAS_NUMERIC_SCALE_MATCH')) }}
{% endmacro %}

{% macro filter_schema_validation_mismatch_is_nullable(row) %}
  {{ return(audit_helper_ext._filter_schema_validation_mismatch_attribute(row, 'HAS_IS_NULLABLE_MATCH')) }}
{% endmacro %}

{% macro filter_schema_validation_in_a_only(row) %}
  {% set in_a_only_col = audit_helper_ext.get_actual_column_name(row, 'IN_A_ONLY') %}
  {{ return(row[in_a_only_col]) }}
{% endmacro %}

{# Gate persisted schema rows on audit_helper__schema_validation_checks. #}
{# Drops in_b_only (column in dbt only — not actionable as drift). #}
{# Falls back to mismatch_data_type + in_a_only if the var is unset or empty, #}
{# matching the pre-configurable behavior so silent-no-op never happens. #}
{% macro filter_schema_validation_enabled_errors(row) %}
  {% set enabled_suffixes = var('audit_helper__schema_validation_checks', ['mismatch_data_type', 'in_a_only']) or ['mismatch_data_type', 'in_a_only'] %}

  {% set in_a_only_col = audit_helper_ext.get_actual_column_name(row, 'IN_A_ONLY') %}
  {% set in_both_col = audit_helper_ext.get_actual_column_name(row, 'IN_BOTH') %}

  {% if row[in_a_only_col] %}
    {{ return('in_a_only' in enabled_suffixes) }}
  {% endif %}

  {% if not row[in_both_col] %}
    {{ return(false) }}
  {% endif %}

  {% set match_column_by_suffix = {
    'mismatch_data_type': 'HAS_DATA_TYPE_MATCH',
    'mismatch_ordinal_position': 'HAS_ORDINAL_POSITION_MATCH',
    'mismatch_character_maximum_length': 'HAS_CHARACTER_MAXIMUM_LENGTH_MATCH',
    'mismatch_numeric_precision': 'HAS_NUMERIC_PRECISION_MATCH',
    'mismatch_numeric_scale': 'HAS_NUMERIC_SCALE_MATCH',
    'mismatch_is_nullable': 'HAS_IS_NULLABLE_MATCH'
  } %}

  {% for suffix, match_column in match_column_by_suffix.items() %}
    {% if suffix in enabled_suffixes %}
      {% set actual_col = audit_helper_ext.try_get_actual_column_name(row, match_column) %}
      {% if actual_col is not none and not row[actual_col] %}
        {{ return(true) }}
      {% endif %}
    {% endif %}
  {% endfor %}

  {{ return(false) }}
{% endmacro %}
