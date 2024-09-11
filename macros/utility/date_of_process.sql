{% macro date_of_process(format=false) %}
  {{ return(adapter.dispatch('date_of_process', 'audit_helper_ext')(format=format)) }}
{% endmacro %}


{% macro default__date_of_process(format) %}

  {% set dt = modules.datetime.datetime %}

  {% set date_str = var('audit_helper__date_of_process', '') | string %}
  {% if not date_str %}
    {% set date_str = dt.utcnow().strftime('%Y-%m-%d') %}
  {% endif %}

  {% if not format %}
    {{ return(date_str) }}
  {% endif %}

  {{ return(dt.strptime(date_str, "%Y-%m-%d").strftime('%Y%m%d')) }}

{% endmacro %}
