{# Renders a Jinja value as a single-quoted SQL string literal (or `null`). #}
{# Values we persist for audit purposes — filter expressions, formatted column-expression #}
{# summaries — can legitimately contain newlines. Most adapters accept a raw newline inside #}
{# '...', so they keep the original behaviour; BigQuery's standard quoted literals must not #}
{# span lines and fail with "Unclosed string literal", so newlines are escaped there. #}

{% macro quote_sql_literal(value) %}
  {{ return(adapter.dispatch('quote_sql_literal', 'audit_helper_ext')(value=value)) }}
{% endmacro %}


{# Kept identical to the expression this replaced, falsy guard included: a falsy value #}
{# (none, empty string) persists as SQL null rather than an empty literal. #}
{% macro default__quote_sql_literal(value) %}

  {{ return(("'" ~ (value | replace("'", "''")) ~ "'") if value else 'null') }}

{% endmacro %}


{% macro bigquery__quote_sql_literal(value) %}

  {% if not value %}
    {{ return('null') }}
  {% endif %}

  {# Backslash first, so the escapes introduced below aren't themselves re-escaped. #}
  {% set escaped = value | string
      | replace('\\', '\\\\')
      | replace("'", "''")
      | replace('\r\n', '\\n')
      | replace('\n', '\\n')
      | replace('\r', '\\n') %}

  {{ return("'" ~ escaped ~ "'") }}

{% endmacro %}
