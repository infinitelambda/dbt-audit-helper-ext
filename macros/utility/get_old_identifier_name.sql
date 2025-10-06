{% macro get_old_identifier_name(model_name, convention=none) %}
  {{ return(adapter.dispatch('get_old_identifier_name', 'audit_helper_ext')(
      model_name=model_name,
      convention=convention
  )) }}
{% endmacro %}


{% macro default__get_old_identifier_name(model_name, convention) %}
  {# 1. First priority: Check model config for audit_helper__old_identifier #}
  {% if execute %}
    {% for node in graph.nodes.values() %}
      {% if node.resource_type == 'model' and node.name == model_name %}
        {% set model_config_old_id = node.config.get('audit_helper__old_identifier', none) %}
        {% if model_config_old_id is not none %}
          {{ return(model_config_old_id) }}
        {% endif %}
      {% endif %}
    {% endfor %}
  {% endif %}

  {# 2. Second priority: Apply naming convention from variable #}
  {% set convention = convention or var('audit_helper__old_identifier_naming_convention', none) %}

  {% if convention is not none %}
    {# Apply regex pattern replacement #}
    {{ return(modules.re.sub(convention.get('pattern'), convention.get('replacement'), model_name)) }}
  {% endif %}

  {# 3. Fallback: Return model name as-is #}
  {{ return(model_name) }}
{% endmacro %}
