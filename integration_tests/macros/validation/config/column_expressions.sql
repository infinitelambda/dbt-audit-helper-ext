{# Test fixtures: user-defined column-expression macros, i.e. the kind a consumer writes in #}
{# their own project rather than the audit_helper__* built-ins the package ships. Wired onto #}
{# models via meta.audit_helper__custom_column_expressions. #}

{# The column name arrives already quoted for the adapter, so it is used verbatim. Note the #}
{# plain macro: expression macros are resolved by name and called directly, so wrapping this #}
{# in adapter.dispatch would look it up against the root project and fail to resolve. #}
{% macro round_1dp_expr(column_name) %}
  {{ return('round(' ~ column_name ~ ', 1)') }}
{% endmacro %}
