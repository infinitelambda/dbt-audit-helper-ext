{% macro convert_to_str_and_list(variable) %}
  {{ return(adapter.dispatch('convert_to_str_and_list', 'audit_helper_ext')(variable=variable)) }}
{% endmacro %}


{% macro default__convert_to_str_and_list(variable) %}

    {# Trim and drop blanks in both branches: callers match these names against column specs,
       so `'a, b'` must yield `b`, not `' b'`. #}
    {% if variable is string %}
        {% set return_list = variable.split(',') | map('trim') | select | list %}
        {% set return_str = return_list | join(',') %}

    {% elif variable is iterable %}
        {% set trimmed = [] %}
        {% for item in variable %}
            {% do trimmed.append(item | trim if item is string else item) %}
        {% endfor %}
        {% set return_list = trimmed | select | list %}
        {% set return_str = return_list | join(',') %}

    {% else %}
        {% set return_str = variable | string %}
        {% set return_list = [variable] %}
    {% endif %}

    {{ return([return_str, return_list]) }}

{% endmacro %}
