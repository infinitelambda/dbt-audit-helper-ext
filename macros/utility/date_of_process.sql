{% macro date_of_process(format=false) %}
  {{ return(adapter.dispatch('date_of_process', 'audit_helper_ext')(format=format)) }}
{% endmacro %}


{% macro default__date_of_process(format) %}

  {% set date_str = var('audit_helper__date_of_process', '') %}
  {% if not date_str %}
    {% set date_str = modules.datetime.datetime.utcnow().strftime('%Y-%m-%d') %}
  {% endif %}

  {% if not format %}
    {{ return(date_str) }}
  {% endif %}

  {{ return(modules.datetime.datetime.strptime(date_str).strftime('%Y%m%d')) }}

{% endmacro %}
