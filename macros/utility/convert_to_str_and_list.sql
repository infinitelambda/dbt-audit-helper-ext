{% macro convert_to_str_and_list(variable) %}
  {{ return(adapter.dispatch('convert_to_str_and_list', 'audit_helper_ext')(variable=variable)) }}
{% endmacro %}


{% macro default__convert_to_str_and_list(variable) %}

    {% if variable is string %}
        {# Trim so `'a, b'` yields `b`, not `' b'`: callers match these names against column specs. #}
        {% set return_list = variable.split(',') | map('trim') | select | list %}
        {% set return_str = return_list | join(',') %}

    {% elif variable is iterable %}
        {% set return_str = variable | join(',') %}
        {% set return_list = variable %}

    {% else %}
        {% set return_str = variable | string %}
        {% set return_list = [variable] %}
    {% endif %}

    {{ return([return_str, return_list]) }}

{% endmacro %}


{#
{% macro test__convert_to_str_and_list() %}
    {% if execute %}
        {{ log(convert_to_str_and_list('var1'), true) }}
        {{ log(convert_to_str_and_list('var1,var2'), true) }}
        {{ log(convert_to_str_and_list(["var1","var2"]), true) }}
        {{ log(convert_to_str_and_list(123), true) }}
    {% endif %}
{% endmacro %}
#}
