{# Quote a list of column names so identifiers survive case-sensitive lookups. #}
{# Columns such as `MixedCase` or `Total Amount` are folded (or rejected) by the warehouse #}
{# when referenced bare, so callers that build SQL from raw column names route them here. #}

{% macro get_quoted_columns(column_names) %}
  {{ return(adapter.dispatch('get_quoted_columns', 'audit_helper_ext')(
      column_names=column_names
  )) }}
{% endmacro %}

{% macro default__get_quoted_columns(column_names) %}
  {%- set quoted_columns = [] -%}

  {% for column_name in column_names %}
    {% do quoted_columns.append(adapter.quote(column_name)) %}
  {% endfor %}

  {{ return(quoted_columns) }}
{% endmacro %}
