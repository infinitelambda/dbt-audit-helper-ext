{% macro run_audit_query(query, summarize=true) %}
  {{ return(adapter.dispatch('run_audit_query', 'audit_helper_ext')(query=query, summarize=summarize)) }}
{% endmacro %}


{% macro default__run_audit_query(query, summarize) %}

    {% set audit_results = run_query(query) %}
    {{ audit_helper_ext.print_audit_result(audit_results) }}
    {%- if not summarize -%}
        {{ log('ℹ️  Only print first 100 rows in csv format. Please check the output in the Query History of your DataWarehouse to not swamp the logs.', true) }}
    {% endif %}

    {{ return(audit_results) }}

{% endmacro %}
