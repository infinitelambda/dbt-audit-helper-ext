{% macro resolve_column_expression_macro(column_name, macro_name) %}
  {{ return(adapter.dispatch('resolve_column_expression_macro', 'audit_helper_ext')(column_name, macro_name)) }}
{% endmacro %}

{% macro default__resolve_column_expression_macro(column_name, macro_name) %}
  {%- set ns = namespace(expression=column_name) -%}

  {% if context.get(macro_name) %}
    {% set ns.expression = context[macro_name](column_name) %}
    {{ audit_helper_ext.log_debug("🎯 Applying custom expression '" ~ macro_name ~ "' to column '" ~ column_name ~ "'") }}
  {% else %}
    {{ audit_helper_ext.log_debug("⚠️  Expression macro '" ~ macro_name ~ "' not found for column '" ~ column_name ~ "'. Using column as-is.") }}
  {% endif %}

  {{ return(ns.expression) }}
{% endmacro %}
