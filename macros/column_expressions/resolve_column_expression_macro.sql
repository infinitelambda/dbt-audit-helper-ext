{% macro resolve_column_expression_macro(column_name, macro_name) %}
  {{ return(adapter.dispatch('resolve_column_expression_macro', 'audit_helper_ext')(column_name, macro_name)) }}
{% endmacro %}

{% macro default__resolve_column_expression_macro(column_name, macro_name) %}

  {% set quoted_column = adapter.quote(column_name) %}

  {#
    Built-ins are called through the package namespace directly. Fetching them as macro objects
    (context.get / audit_helper_ext.get) yields a shim that re-enters adapter.dispatch against the
    ROOT project namespace and fails, so resolve them by name here instead.
  #}
  {% if macro_name == 'audit_helper__trim_upper' %}
    {% set expression = audit_helper_ext.audit_helper__trim_upper(quoted_column) %}
  {% elif macro_name == 'audit_helper__trim_lower' %}
    {% set expression = audit_helper_ext.audit_helper__trim_lower(quoted_column) %}
  {% elif macro_name == 'audit_helper__round_2dp' %}
    {% set expression = audit_helper_ext.audit_helper__round_2dp(quoted_column) %}
  {% elif macro_name == 'audit_helper__round_4dp' %}
    {% set expression = audit_helper_ext.audit_helper__round_4dp(quoted_column) %}
  {% elif macro_name == 'audit_helper__cast_to_int' %}
    {% set expression = audit_helper_ext.audit_helper__cast_to_int(quoted_column) %}

  {#
    Otherwise the reference is a user-defined macro in the root project. There is no reliable
    pre-flight existence check: `context` hands back a callable dispatch shim for ANY name, so an
    unknown macro can only surface as dbt's own "No macro named ... found within namespace" error
    when it is invoked below.
  #}
  {% else %}
    {% set expression = context[macro_name](quoted_column) %}
  {% endif %}

  {{ audit_helper_ext.log_debug("🎯 Applying custom expression '" ~ macro_name ~ "' to column '" ~ column_name ~ "'") }}

  {{ return(expression | trim) }}
{% endmacro %}
