{% macro get_source_node(source_name, identifier) %}
  {{ return(adapter.dispatch('get_source_node', 'audit_helper_ext')(source_name=source_name, identifier=identifier)) }}
{% endmacro %}


{% macro default__get_source_node(source_name, identifier) %}

    {% set ns = namespace() %}
    {% set ns.node = [] %}
    {% for node in graph.sources.values()
        | selectattr("source_name", "equalto", source_name | trim)
        | selectattr("name", "equalto", identifier | trim)
    %}
        {% do ns.node.append(node) %}
    {% endfor -%}
    {% if ns.node | length > 0 %}
        {% set first_node = ns.node[0] %}
    {% else %}
        {% set first_node = {'name': 'undefined'} %}
    {% endif %}

    {{ return(first_node) }}

{% endmacro %}
