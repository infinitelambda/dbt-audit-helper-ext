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

  {# Build column specs for each column #}
  {% for column_name in column_names %}

    {% if column_name in custom_expressions %}

      {% set macro_name = custom_expressions[column_name] %}
      {# The resolver quotes the column itself, so the expression is ready to alias. #}
      {% set expression = audit_helper_ext.resolve_column_expression_macro(column_name, macro_name) %}
      {% set select_expr = expression ~ ' as ' ~ adapter.quote(column_name) %}
      {% do ns.column_specs.append(namespace(
        name=column_name,
        expression=expression,
        select=select_expr,
        macro_ref=macro_name
      )) %}

    {% else %}

      {% set quoted_col = adapter.quote(column_name) %}
      {% do ns.column_specs.append(namespace(
        name=column_name,
        expression=quoted_col,
        select=quoted_col,
        macro_ref=none
      )) %}

    {% endif %}
  {% endfor %}

  {{ return(ns.column_specs) }}
{% endmacro %}
