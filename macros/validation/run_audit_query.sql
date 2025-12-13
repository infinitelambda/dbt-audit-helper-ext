{% macro run_audit_query(query, summarize=true, filter=none) %}
  {{ return(adapter.dispatch('run_audit_query', 'audit_helper_ext')(query=query, summarize=summarize, filter=filter)) }}
{% endmacro %}


{% macro default__run_audit_query(query, summarize, filter) %}

    {% set query_pre_hooks = audit_helper_ext.get_audit_query_pre_hooks() %}
    {% set statement_separator = audit_helper_ext.get_audit_query_statement_separator() %}
    {% set audit_query -%}
      {% if query_pre_hooks | length > 0 -%}
        {{ audit_helper_ext.log_debug("Pre-hooking with:\n- " ~ (query_pre_hooks | join("\n- "))) }}
        {% set query_hooks = query_pre_hooks | join(statement_separator ~ '\n') %}
        {% if target.type not in ["sqlserver", "databricks"] -%}
          /* pre-hooks statements */
          {{ query_hooks }}{{ statement_separator }}
        {%- else %}
          {% do run_query(query_hooks) %}
        {%- endif %}
      {%- endif %}
      /* main query */
      {{ query }}
    {%- endset %}

    {% set audit_results = run_query(audit_query) %}
    {% if filter %}
      {% set audit_results = audit_results.where(filter) %}
    {% endif %}
    {{ audit_helper_ext.print_audit_result(audit_results) }}
    {%- if not summarize -%}
        {{ log('ℹ️  Only print first 100 rows in csv format. Please check the output in the Query History of your DataWarehouse to not swamp the logs.', true) }}
    {% endif %}

    {{ return(audit_results) }}

{% endmacro %}
