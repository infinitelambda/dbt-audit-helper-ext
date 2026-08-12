{% macro convert_to_str_and_list(variable) %}
  {{ return(adapter.dispatch('convert_to_str_and_list', 'audit_helper_ext')(variable=variable)) }}
{% endmacro %}


{% macro default__convert_to_str_and_list(variable) %}

    {# Both branches trim and drop blanks: callers match these names against column specs. #}
    {% if variable is string %}
        {% set return_list = variable.split(',') | map('trim') | reject('eq', '') | list %}
        {% set return_str = return_list | join(',') %}

    {% elif variable is iterable %}
        {% set trimmed = [] %}
        {% for item in variable %}
            {% do trimmed.append(item | trim if item is string else item) %}
        {% endfor %}
        {% set return_list = trimmed | reject('eq', '') | list %}
        {% set return_str = return_list | join(',') %}

    {% else %}
        {% set return_str = variable | string %}
        {% set return_list = [variable] %}
    {% endif %}

    {{ return([return_str, return_list]) }}

{% endmacro %}
