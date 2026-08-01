{% macro log_debug(message) %}

  {% set esc = audit_helper_ext.get_ansi_esc() %}
  {% set blue = esc ~ "[34m" %}
  {% set reset = esc ~ "[0m" %}

  {{ log(blue ~ "ℹ️  DEBUG: " ~ message ~ reset, info=True) }}

{% endmacro %}
