{% macro date_of_process() %}
  {{ return(adapter.dispatch('date_of_process', 'audit_helper_ext')()) }}
{% endmacro %}

{% macro default__date_of_process() %}
  TODO
{% endmacro %}
