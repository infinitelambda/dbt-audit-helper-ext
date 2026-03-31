{% macro get_dependent_source_nodes(identifiers, dependant_table_names=none, tag=none) %}
    {{ return(adapter.dispatch('get_dependent_source_nodes', 'audit_helper_ext')(
        identifiers=identifiers,
        dependant_table_names=dependant_table_names,
        tag=tag
    )) }}
{% endmacro %}


{% macro default__get_dependent_source_nodes(identifiers, dependant_table_names, tag) %}

    {# -- Parse comma-separated inputs into lists -- #}
    {% set identifier_list = identifiers.split(',') | map('trim') | select | list %}
    {% set source_table_name_list = dependant_table_names.split(',') | map('trim') | select | list
        if dependant_table_names is not none else [] %}

    {% set upstream_model_ids = [] %}
    {% for identifier in identifier_list %}

        {# -- Get target model node -- #}
        {% set target_node = audit_helper_ext.get_model_node(identifier) %}
        {% if target_node.name == 'undefined' %}
            {% do exceptions.raise_compiler_error(
                "❌ Model '" ~ identifier ~ "' not found in the dbt graph."
            ) %}
        {% endif %}

        {# -- Collect upstream models (including target) from lineage paths -- #}
        {% set lineage_paths = audit_helper_ext.get_upstream_lineage(identifier) %}

        {% for path in lineage_paths %}
            {% for node_info in path %}
                {% if node_info.type == 'model' and node_info.unique_id not in upstream_model_ids %}
                    {% do upstream_model_ids.append(node_info.unique_id) %}
                {% endif %}
            {% endfor %}
        {% endfor %}

    {% endfor %}

    {# -- Filter models by tag (if provided) -- #}
    {% set filtered_model_ids = [] %}
    {% if tag is not none %}
        {% for model_id in upstream_model_ids %}
            {% set model_node = graph.nodes.get(model_id) %}
            {% if model_node and tag in model_node.tags %}
                {% do filtered_model_ids.append(model_id) %}
            {% endif %}
        {% endfor %}
    {% else %}
        {% set filtered_model_ids = upstream_model_ids %}
    {% endif %}

    {# -- Collect source dependencies from filtered models -- #}
    {% set source_unique_ids = [] %}
    {% for model_id in filtered_model_ids %}
        {% set model_node = graph.nodes.get(model_id) %}
        {% if model_node %}
            {% set depends_on_nodes = model_node.get('depends_on', {}).get('nodes', []) %}
            {% for dep_id in depends_on_nodes %}
                {% if dep_id.startswith('source.') and dep_id not in source_unique_ids %}
                    {% do source_unique_ids.append(dep_id) %}
                {% endif %}
            {% endfor %}
        {% endif %}
    {% endfor %}

    {# -- Resolve source nodes and filter by dependant_table_names -- #}
    {% set source_nodes = [] %}
    {% for source_id in source_unique_ids %}
        {% set source_node = graph.sources.get(source_id) %}
        {% if source_node %}
            {% if source_table_name_list | length == 0 or source_node.name in source_table_name_list %}
                {% do source_nodes.append(source_node) %}
            {% endif %}
        {% endif %}
    {% endfor %}

    {{ return(source_nodes) }}

{% endmacro %}
