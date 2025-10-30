{% macro print_validation_result_status(result, validation_type) %}
  {{ return(adapter.dispatch('print_validation_result_status', 'audit_helper_ext')(
    result=result,
    validation_type=validation_type
  )) }}
{% endmacro %}


{% macro default__print_validation_result_status(result, validation_type) %}

  {% set filters = audit_helper_ext.get_validation_result_filters(validation_type) %}
  {% if not execute or (filters | length == 0) %}
      {{ return('') }}
  {% endif %}

  {# Evaluate filters #}
  {% for filter_config in filters %}
    {% set filter_description = filter_config.description %}
    {% set filter_macro = filter_config.macro %}
    {% set filter_macro_call = context.get(filter_macro, none) or audit_helper_ext.get(filter_macro) %}
    {% set failed_calc_config = filter_config.failed_calc | default(namespace(agg=none)) %}

    {# For count validation: table level #}
    {% if validation_type == 'count' %}
      {% set filter_result = filter_macro_call(result) %}
      {% if filter_result and (result.rows | length) == 2 %}
        {% set count_a = result.rows[0][failed_calc_config.column] %}
        {% set count_b = result.rows[1][failed_calc_config.column] %}
        {% set failure_count = (count_a - count_b) | abs %}
      {% else %}
        {% set failure_count = 1 if filter_result else 0 %}
      {% endif %}

    {% else %}
      {# For other validation: row level #}
      {% set filtered_table = result.where(filter_macro_call) %}

      {# Calculate failure count based on aggregate method in config #}
      {% if failed_calc_config.agg is none %}
        {% set failure_count = filtered_table.rows | length %}
      {% else %}
        {% set column_values = filtered_table.columns[failed_calc_config.column | upper].values() %}
        {% set aggregates = {
          'sum': column_values | sum,
          'max': column_values | max,
          'min': column_values | min
        } %}
        {% set failure_count = aggregates[failed_calc_config.agg] %}
      {% endif %}
    {% endif %}

    {# Log the filter result with status indicators #}
    {% set status_indicators = [
      namespace(condition=(failure_count == 0), emoji='✅', text='PASS'),
      namespace(condition=(failure_count > 0) , emoji='❌', text='FAIL')
    ] %}
    {% set status = status_indicators | selectattr('condition') | first %}
    {% do audit_helper_ext.log_data(status.emoji ~ ' ' ~ status.text ~ ' - ' ~ filter_description ~ ' (' ~ failure_count ~ ' failures)') %}
  {% endfor %}
  
{% endmacro %}
