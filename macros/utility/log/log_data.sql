{% macro log_data(message) %}

  {% set esc = audit_helper_ext.get_ansi_esc() %}
  {% set grey = esc ~ "[90m" %}
  {% set reset = esc ~ "[0m" %}

  {{ log(grey ~ message ~ reset, info=True) }}

{% endmacro %}
