{% macro print_audit_result(result, format=var('audit_helper_ext__result_format', 'table')) %}
  {{ return(adapter.dispatch('print_audit_result', 'audit_helper_ext')(result=result, format=format)) }}
{% endmacro %}


{% macro default__print_audit_result(result, format) %}
    {{ log('ℹ️  The result of validation are below:', true) }}

    {% if validation_result_format == 'table' %}
        {{ result.print_table(max_rows=100, max_columns=7, max_column_width=none) }}
    {% elif validation_result_format == 'csv' %}
        {{ result.limit(100).print_csv() }}
    {% endif %}
{% endmacro %}
