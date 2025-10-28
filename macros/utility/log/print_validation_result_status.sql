{% macro print_validation_result_status(result, validation_type) %}
  {{ return(adapter.dispatch('print_validation_result_status', 'audit_helper_ext')(
    result=result,
    validation_type=validation_type
  )) }}
{% endmacro %}


{% macro default__print_validation_result_status(result, validation_type) %}
  {% if execute %}
    {# Get the list of filters for this validation type #}
    {% set filters = audit_helper_ext.get_validation_filters(validation_type) %}

    {# If no filters defined for this validation type, skip #}
    {% if filters | length == 0 %}
      {{ return('') }}
    {% endif %}

    {# Evaluate each filter using Agate's bulk where() method #}
    {% for filter_config in filters %}
      {% set filter_description = filter_config.description %}
      {% set filter_macro = filter_config.macro %}
      {% set filter_macro_call = context[filter_macro] or audit_helper_ext[filter_macro] %}

      {# Use Agate's where() method for bulk filtering instead of row-by-row iteration #}
      {% set filtered_table = result.where(filter_macro_call) %}
      {% set row_count = filtered_table.rows | length %}

      {# Determine emoji based on row count #}
      {% if row_count == 0 %}
        {% set emoji = '✅' %}
        {% set status = 'PASS' %}
      {% else %}
        {% set emoji = '❌' %}
        {% set status = 'FAIL' %}
      {% endif %}

      {# Log the filter result with emoji #}
      {% do audit_helper_ext.log_data(emoji ~ ' ' ~ status ~ ' - ' ~ filter_description ~ ' (' ~ row_count ~ ' failures)') %}
    {% endfor %}
  {% endif %}
{% endmacro %}
