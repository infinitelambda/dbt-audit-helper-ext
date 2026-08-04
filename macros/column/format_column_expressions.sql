{% macro format_column_expressions(column_specs) %}
  {{ return(adapter.dispatch('format_column_expressions', 'audit_helper_ext')(column_specs=column_specs)) }}
{% endmacro %}


{% macro default__format_column_expressions(column_specs) %}

  {% if not column_specs %}
    {{ return(none) }}
  {% endif %}

  {% set applied = [] %}
  {% for spec in column_specs %}
    {% if spec.macro_ref %}
      {% do applied.append('• ' ~ spec.name ~ ': ' ~ spec.macro_ref ~ ' -> ' ~ spec.expression) %}
    {% endif %}
  {% endfor %}

  {% if not applied %}
    {{ return(none) }}
  {% endif %}

  {{ return('\n' ~ (applied | join('\n'))) }}

{% endmacro %}
