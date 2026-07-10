{% macro get_source_node(source_name, identifier, package_name=none) %}
  {{ return(adapter.dispatch('get_source_node', 'audit_helper_ext')(source_name=source_name, identifier=identifier, package_name=package_name)) }}
{% endmacro %}


{% macro default__get_source_node(source_name, identifier, package_name) %}

    {% set candidates = graph.sources.values()
        | selectattr("source_name", "equalto", source_name | trim)
        | selectattr("name", "equalto", identifier | trim)
        | list %}

    {% set ns = namespace() %}
    {% set ns.node = audit_helper_ext.filter_nodes_by_package(
        candidates,
        package_name=package_name,
        identifier=source_name | trim ~ ':' ~ identifier | trim
    ) %}

    {% if ns.node | length > 0 %}
        {% set first_node = ns.node[0] %}
    {% else %}
        {% set first_node = {'name': 'undefined'} %}
    {% endif %}

    {{ return(first_node) }}

{% endmacro %}
