{% macro get_model_node(identifier) %}
  {{ return(adapter.dispatch('get_model_node', 'audit_helper_ext')(identifier=identifier)) }}
{% endmacro %}


{% macro default__get_model_node(identifier) %}

    {% set ns = namespace() %}
    {% set ns.node = [] %}
    {% for node in graph.nodes.values()
        | selectattr("resource_type", "equalto", "model")
        | selectattr("package_name", "equalto", project_name)
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
