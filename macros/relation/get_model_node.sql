{% macro get_model_node(identifier, package_name=none) %}
  {{ return(adapter.dispatch('get_model_node', 'audit_helper_ext')(identifier=identifier, package_name=package_name)) }}
{% endmacro %}


{% macro default__get_model_node(identifier, package_name) %}

    {% set candidates = graph.nodes.values()
        | selectattr("resource_type", "equalto", "model")
        | selectattr("name", "equalto", identifier | trim)
        | list %}

    {% set ns = namespace() %}
    {% set ns.node = audit_helper_ext.filter_nodes_by_package(
        candidates,
        package_name=package_name,
        identifier=identifier | trim
    ) %}

    {% if ns.node | length > 0 %}
        {% set first_node = ns.node[0] %}
    {% else %}
        {% set first_node = {'name': 'undefined'} %}
    {% endif %}

    {{ return(first_node) }}

{% endmacro %}
