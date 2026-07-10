{% macro resolve_source_filter(filter_ref) %}
  {{ return(adapter.dispatch('resolve_source_filter', 'audit_helper_ext')(filter_ref=filter_ref)) }}
{% endmacro %}


{% macro default__resolve_source_filter(filter_ref) %}

  {# Feature off for this model when no filter is referenced #}
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

  {{ return('(' ~ expression ~ ')') }}

{% endmacro %}
