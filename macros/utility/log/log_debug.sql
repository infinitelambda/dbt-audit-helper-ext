{% macro log_debug(message) %}

  {% set blue = "\x1b[34m" %}
  {% set reset = "\x1b[0m" %}

  {{ log(blue ~ "ℹ️  DEBUG: " ~ message ~ reset, info=True) }}

{% endmacro %}
