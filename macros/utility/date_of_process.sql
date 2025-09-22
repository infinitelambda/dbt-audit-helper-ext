{% macro date_of_process(format=false, use_prev=false) %}
  {{ return(adapter.dispatch('date_of_process', 'audit_helper_ext')(format=format, use_prev=use_prev)) }}
{% endmacro %}


{% macro default__date_of_process(format, use_prev) %}

  {% set dt = modules.datetime.datetime %}
  {% set re = modules.re %}

  {% set date_str = var('audit_helper__date_of_process', '') | string %}
  {% if not date_str %}
    {% set date_str = dt.utcnow().strftime('%Y-%m-%d') %}
  {% endif %}

  {% set allowed_dates = var('audit_helper__allowed_date_of_processes', []) | list %}
  {% if allowed_dates and date_str not in allowed_dates %}
    {{ exceptions.raise_compiler_error(
      "❌ Invalid `audit_helper__allowed_date_of_processes`.
      Expected `audit_helper__date_of_process` in " ~ allowed_dates ~ ", but got: " ~ date_str
    ) }}
  {% endif %}

  {% if use_prev %}
    {% set prev_index = allowed_dates.index(date_str) - 1 %}
    {% if not prev_index or prev_index < 0 %}
      {{ exceptions.raise_compiler_error(
        "❌ Cannot find previous date for '" ~ date_str 
          ~ "' in `audit_helper__allowed_date_of_processes` = " ~ allowed_dates
      ) }}
    {% endif %}

    {% set date_str = allowed_dates[prev_index] %}
    {{ log("📆 Looking at previous date: " ~ date_str, info=True) if execute }}
    
  {% endif %}

  {% if format and re.match('^\\d{4}-\\d{2}-\\d{2}$', date_str) %}
    {% set date_str = dt.strptime(date_str, "%Y-%m-%d").strftime('%Y%m%d') | string %}
  {% endif %}

  {{ return(date_str) }}

{% endmacro %}
