{% macro get_upstream_lineage(dbt_identifier) %}
  {{ return(adapter.dispatch('get_upstream_lineage', 'audit_helper_ext')(dbt_identifier=dbt_identifier)) }}
{% endmacro %}


{% macro default__get_upstream_lineage(dbt_identifier) %}
  {% if execute %}

    {# Get the node for this model #}
    {% set dbt_node = graph.nodes.values() | selectattr("name", "equalto", dbt_identifier) | first %}

    {% if not dbt_node %}
      {{ return([]) }}
    {% endif %}

    {# Initialize data structures for traversal #}
    {% set lineage_paths = [] %}

    {# Start recursive traversal #}
    {{ audit_helper_ext._traverse_upstream(dbt_node, [], lineage_paths) }}

    {{ return(lineage_paths) }}

  {% endif %}
  {{ return([]) }}
{% endmacro %}


{% macro _traverse_upstream(node, current_path, lineage_paths) %}

  {% set node_id = node.unique_id %}

  {# Prevent circular dependencies - check if node is already in current path #}
  {% set path_node_ids = current_path | map(attribute='unique_id') | list %}
  {% if node_id in path_node_ids %}
    {{ return(none) }}
  {% endif %}

  {# Add current node to path #}
  {% set node_info = {
      'name': node.name,
      'type': node.resource_type,
      'unique_id': node.unique_id,
      'database': node.database if node.database else none,
      'schema': node.schema if node.schema else none
  } %}

  {% set new_path = current_path + [node_info] %}

  {# Get upstream dependencies #}
  {% set depends_on_nodes = node.get('depends_on', {}).get('nodes', []) %}

  {# Base case: this is a source table (no upstream deps or resource_type is 'source') #}
  {% if depends_on_nodes | length == 0 or node.resource_type == 'source' %}
    {% do lineage_paths.append(new_path) %}
  {% else %}
    {# Recursive case: traverse each upstream node #}
    {% for dep_id in depends_on_nodes %}
      {% set upstream_node = graph.nodes.get(dep_id) or graph.sources.get(dep_id) %}
      {% if upstream_node %}
        {{ audit_helper_ext._traverse_upstream(upstream_node, new_path, lineage_paths) }}
      {% endif %}
    {% endfor %}
  {% endif %}

{% endmacro %}
