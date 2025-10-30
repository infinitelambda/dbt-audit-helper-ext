{% macro log_data(message) %}

  {% set grey = "\x1b[90m" %}
  {% set reset = "\x1b[0m" %}

  {{ log(grey ~ message ~ reset, info=True) }}

{% endmacro %}
