{% macro filter_nodes_by_package(nodes, package_name, identifier) %}
  {{ return(adapter.dispatch('filter_nodes_by_package', 'audit_helper_ext')(
      nodes=nodes,
      package_name=package_name,
      identifier=identifier
  )) }}
{% endmacro %}


{% macro default__filter_nodes_by_package(nodes, package_name, identifier) %}

    {% set matched = [] %}
    {% for node in nodes %}
        {% if package_name is none or node.package_name == package_name %}
            {% do matched.append(node) %}
        {% endif %}
    {% endfor %}

    {% if matched | length > 1 %}
        {% set entity_label = matched[0].unique_id.split('.')[0] | capitalize %}
        {{ log(
            "⚠️  " ~ entity_label ~ " '" ~ identifier ~ "' matched " ~ matched | length
            ~ " nodes across packages [" ~ (matched | map(attribute='package_name') | join(', '))
            ~ "]. Selecting the first ('" ~ matched[0].package_name
            ~ "'). Pass package_name to disambiguate.", info=true)
        }}
    {% endif %}

    {{ return(matched) }}

{% endmacro %}
