{% macro get_relation(identifier, identifier_database=none, identifier_schema=none, node_name=none, source_name=none) %}
  {% set node_name = node_name or identifier %}
  {{ return(adapter.dispatch('get_relation', 'audit_helper_ext')(
      identifier=identifier,
      identifier_database=identifier_database,
      identifier_schema=identifier_schema,
      node_name=node_name,
      source_name=source_name
  )) }}
{% endmacro %}


{% macro default__get_relation(identifier, identifier_database, identifier_schema, node_name, source_name) %}

    {% set node = audit_helper_ext.get_model_node(node_name) %}
    {% if node.name == 'undefined' and source_name %}
        {% set node = audit_helper_ext.get_source_node(source_name=source_name, identifier=node_name) %}
    {% endif %}

    {% set database = identifier_database or node.database %}
    {% set schema = identifier_schema or node.schema %}
    {% set relation_exists, relation = dbt.get_or_create_relation(
        database=database,
        schema=schema,
        identifier=identifier,
        type='table'
    ) %}

    {{ return((relation_exists, relation, node.config)) }}

{% endmacro %}
