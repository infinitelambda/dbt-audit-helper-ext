{% macro get_columns_with_expressions(relation, model_name, column_names, package_name=none) %}
  {{ return(adapter.dispatch('get_columns_with_expressions', 'audit_helper_ext')(
      relation=relation,
      model_name=model_name,
      column_names=column_names,
      package_name=package_name
  )) }}
{% endmacro %}

{% macro default__get_columns_with_expressions(relation, model_name, column_names, package_name) %}
  {%- set ns = namespace(column_specs=[]) -%}

  {# Get model config from graph #}
  {% set model_config = audit_helper_ext.get_model_config_from_graph(model_name, package_name=package_name) %}
  {% set meta_config = model_config.get('meta', {}) %}
  {% set config_name = "audit_helper__custom_column_expressions" %}
  {% set custom_expressions = meta_config.get(config_name, model_config.get(config_name, {})) %}

  {% for column_name in column_names %}

    {% if (column_name | lower) in custom_expressions %}

      {% set macro_name = custom_expressions[column_name | lower] %}
      {% set expression = audit_helper_ext.resolve_column_expression_macro(column_name, macro_name) %}
      {% set select_expr = expression ~ ' as ' ~ adapter.quote(column_name) %}
      {% do ns.column_specs.append(namespace(
        name=column_name,
        expression=expression,
        select=select_expr,
        macro_ref=macro_name
      )) %}

    {% else %}

      {% do ns.column_specs.append(namespace(
        name=column_name,
        expression=column_name,
        select=column_name,
        macro_ref=none
      )) %}

    {% endif %}
  {% endfor %}

  {# Warn about configured columns that are not part of the compared column set #}
  {% set columns_lower = column_names | map('lower') | list %}
  {% for cfg_column, cfg_macro in custom_expressions.items() %}
    {% if cfg_column not in columns_lower %}
      {% do exceptions.warn(
        "[" ~ config_name ~ "] Column '" ~ cfg_column ~ "' (macro: " ~ cfg_macro ~ ") is configured for model '"
        ~ model_name ~ "' but was not found in the compared columns. The custom expression will be ignored."
      ) %}
    {% endif %}
  {% endfor %}

  {{ return(ns.column_specs) }}
{% endmacro %}
