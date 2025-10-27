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

    {# Evaluate each filter and display results with emoji indicators #}
    {% for filter_config in filters %}
      {% set filter_name = filter_config.name %}
      {% set filter_description = filter_config.description %}
      {% set filter_macro = filter_config.macro %}

      {# Apply filter to each row #}
      {% set filtered_rows = [] %}
      {% for row in result.rows %}
        {% set should_include = audit_helper_ext[filter_macro](row) %}
        {% if should_include %}
          {% do filtered_rows.append(row) %}
        {% endif %}
      {% endfor %}

      {% set row_count = filtered_rows | length %}

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
