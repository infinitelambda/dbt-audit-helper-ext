{% macro get_model_config_from_graph(model_name) %}
  {{ return(adapter.dispatch('get_model_config_from_graph', 'audit_helper_ext')(model_name)) }}
{% endmacro %}

{% macro default__get_model_config_from_graph(model_name) %}
  {% set node = audit_helper_ext.get_model_node(model_name) %}

  {% if node.name == 'undefined' %}
    {{ return({}) }}
  {% endif %}

  {{ return(node.config) }}
{% endmacro %}
