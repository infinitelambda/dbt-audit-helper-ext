{% macro get_model_config_from_graph(model_name, package_name=none) %}
  {{ return(adapter.dispatch('get_model_config_from_graph', 'audit_helper_ext')(
      model_name=model_name,
      package_name=package_name
  )) }}
{% endmacro %}

{% macro default__get_model_config_from_graph(model_name, package_name) %}
  {# package_name disambiguates models that share a name across packages. #}
  {% set node = audit_helper_ext.get_model_node(model_name, package_name=package_name) %}

  {% if node.name == 'undefined' %}
    {{ return({}) }}
  {% endif %}

  {{ return(node.config) }}
{% endmacro %}
