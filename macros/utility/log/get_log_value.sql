{% macro get_log_value(value) %}

  {% set orange = "\x1b[38;2;255;165;0m" %}
  {% set reset = "\x1b[0m" %}

  {{ return(orange ~ value ~ reset) }}

{% endmacro %}
