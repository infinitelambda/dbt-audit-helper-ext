{% macro get_old_identifier_name(model_name, convention=none) %}
  {{ return(adapter.dispatch('get_old_identifier_name', 'audit_helper_ext')(
      model_name=model_name,
      convention=convention
  )) }}
{% endmacro %}


{% macro default__get_old_identifier_name(model_name, convention) %}
  {#
    Find order:
    1. config.meta.audit_helper__old_identifier (NEW preferred format)
    2. config.audit_helper__old_identifier (EXISTING format)
    3. Apply naming convention from variable
    4. Fallback: Return model name as-is
  #}
  {% if execute %}
    {% set model_config = audit_helper_ext.get_model_config_from_graph(model_name) %}

    {# Priority 1: Check meta.audit_helper__old_identifier #}
    {% set meta_config = model_config.get('meta', {}) %}
    {% set model_config_old_id = meta_config.get('audit_helper__old_identifier', none) %}

    {# Priority 2: Check direct config.audit_helper__old_identifier #}
    {% if model_config_old_id is none %}
      {% set model_config_old_id = model_config.get('audit_helper__old_identifier', none) %}
    {% endif %}

    {% if model_config_old_id is not none %}
      {{ return(model_config_old_id) }}
    {% endif %}
  {% endif %}

  {# Priority 3: Apply naming convention from variable #}
  {% set convention = convention or var('audit_helper__old_identifier_naming_convention', none) %}
  {% if convention is not none %}
    {# Apply regex pattern replacement #}
    {{ return(modules.re.sub(convention.get('pattern'), convention.get('replacement'), model_name)) }}
  {% endif %}

  {# Priority 4: Fallback: Return model name as-is #}
  {{ return(model_name) }}
{% endmacro %}
