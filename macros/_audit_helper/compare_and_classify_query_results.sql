{# Override at v0.12: quote the column list before upstream renders it. #}
{# Upstream builds its projection with a bare `columns | join(", ")`, which produces invalid #}
{# SQL for identifiers that need quoting (spaces, mixed case). #}

{% macro default__compare_and_classify_query_results(a_query, b_query, primary_key_columns, columns, event_time, sample_limit) %}

    {% set quoted_columns = [] %}
    {% for column_name in columns %}
        {% do quoted_columns.append(adapter.quote(column_name)) %}
    {% endfor %}

    {% set quoted_pks = [] %}
    {% for pk in primary_key_columns %}
        {% do quoted_pks.append(adapter.quote(pk)) %}
    {% endfor %}

    {{ audit_helper.default__compare_and_classify_query_results(
        a_query, b_query, quoted_pks, quoted_columns, event_time, sample_limit
    ) }}

{% endmacro %}
