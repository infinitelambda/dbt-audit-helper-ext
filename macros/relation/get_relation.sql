{% macro get_relation(identifier, identifier_database=none, identifier_schema=none, node_name=none) %}
  {% set node_name = node_name or identifier %}
  {{ return(adapter.dispatch('get_relation', 'audit_helper_ext')(
      identifier=identifier,
      identifier_database=identifier_database,
      identifier_schema=identifier_schema,
      node_name=node_name
  )) }}
{% endmacro %}


{% macro default__get_relation(identifier, identifier_database, identifier_schema, node_name) %}

    {% set node = audit_helper_ext.get_model_node(node_name) %}

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
