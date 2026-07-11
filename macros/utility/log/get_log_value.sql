{% macro get_log_value(value) %}

  {% set esc = audit_helper_ext.get_ansi_esc() %}
  {% set orange = esc ~ "[38;2;255;165;0m" %}
  {% set reset = esc ~ "[0m" %}

  {{ return(orange ~ value ~ reset) }}

{% endmacro %}
