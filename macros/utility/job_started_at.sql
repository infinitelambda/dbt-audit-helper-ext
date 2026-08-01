{% macro job_started_at() %}
  {{ return(adapter.dispatch('job_started_at', 'audit_helper_ext')()) }}
{% endmacro %}


{% macro default__job_started_at() %}
  {{ return("cast('" ~ run_started_at ~ "' as " ~ dbt.type_timestamp() ~ ")") }}
{% endmacro %}
