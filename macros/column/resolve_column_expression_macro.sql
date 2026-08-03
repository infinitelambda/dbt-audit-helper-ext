{% macro resolve_column_expression_macro(column_name, macro_name) %}
  {{ return(adapter.dispatch('resolve_column_expression_macro', 'audit_helper_ext')(column_name, macro_name)) }}
{% endmacro %}

{% macro default__resolve_column_expression_macro(column_name, macro_name) %}

  {% set quoted_column = adapter.quote(column_name) %}
  {% set expression_macro = context.get(macro_name) %}

  {% if expression_macro is none %}
    {{ exceptions.raise_compiler_error(
      "Column expression macro '" ~ macro_name ~ "' was not found in your project "
      ~ "(configured for column '" ~ column_name ~ "'). Point audit_helper__custom_column_expressions at a "
      ~ "macro that takes a column name and returns a SQL expression."
    ) }}
  {% endif %}

  {{ return(expression_macro(quoted_column) | trim) }}
{% endmacro %}
