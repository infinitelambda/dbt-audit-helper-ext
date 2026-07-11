{% macro resolve_relation_filter(filter_ref, side=none) %}
  {{ return(adapter.dispatch('resolve_relation_filter', 'audit_helper_ext')(filter_ref=filter_ref, side=side)) }}
{% endmacro %}


{% macro default__resolve_relation_filter(filter_ref, side=none) %}

  {# Model config wins; else fall back to the side's project var (a->source, b->dbt). #}
  {% set side_vars = {'a': 'audit_helper__source_filter', 'b': 'audit_helper__dbt_filter'} %}
  {% if not filter_ref and side %}
    {% set filter_ref = var(side_vars[side], none) %}
  {% endif %}

  {# Feature off for this side when neither model config nor var references a filter #}
  {% if not filter_ref %}
    {{ return(none) }}
  {% endif %}

  {# The reference IS the macro name — look it up in the project, then in audit_helper_ext. #}
  {% set filter_macro = context.get(filter_ref) or audit_helper_ext.get(filter_ref) %}

  {% if filter_macro is none %}
    {{ exceptions.raise_compiler_error(
      "Filter macro '" ~ filter_ref ~ "' was not found in your project or in audit_helper_ext. "
      ~ "Point audit_helper__source_filter / audit_helper__dbt_filter at a macro that returns "
      ~ "a SQL boolean expression."
    ) }}
  {% endif %}

  {% set expression = filter_macro() | trim %}
  {% if not expression %}
    {{ return(none) }}
  {% endif %}

  {# Raw SQL, spliced verbatim into comparison WHERE clauses — never quote-escaped here. #}
  {{ return('(' ~ expression ~ ')') }}

{% endmacro %}
