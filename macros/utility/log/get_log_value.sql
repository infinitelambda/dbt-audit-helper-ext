{% macro get_log_value(value) %}

  {% set esc = audit_helper_ext.get_ansi_esc() %}
  {% set orange = esc ~ "[38;2;255;165;0m" %}
  {% set reset = esc ~ "[0m" %}

  {% if value is string and '\n' in value %}
    {% set colored = [] %}
    {% for line in value.split('\n') %}
      {% do colored.append(orange ~ line ~ reset if line else line) %}
    {% endfor %}
    {{ return(colored | join('\n')) }}
  {% endif %}

  {{ return(orange ~ value ~ reset) }}

{% endmacro %}
