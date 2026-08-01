{# Extended compare_row_counts adding source (A) / dbt (B) WHERE filters, so the row-count #}
{# validation stays consistent with the filtered row-by-row comparison. Lives in the #}
{# audit_helper_ext namespace and is called directly by the validation entry macros. #}

{% macro compare_row_counts(a_relation, b_relation, a_filter=none, b_filter=none) %}
  {{ return(adapter.dispatch('compare_row_counts', 'audit_helper_ext')(
    a_relation=a_relation,
    b_relation=b_relation,
    a_filter=a_filter,
    b_filter=b_filter
  )) }}
{% endmacro %}


{% macro default__compare_row_counts(a_relation, b_relation, a_filter=none, b_filter=none) %}

        select
            '{{ a_relation }}' as relation_name,
            count(*) as total_records
        from {{ a_relation }}
        {% if a_filter %}where {{ a_filter }}{% endif %}

        union all

        select
            '{{ b_relation }}' as relation_name,
            count(*) as total_records
        from {{ b_relation }}
        {% if b_filter %}where {{ b_filter }}{% endif %}

{% endmacro %}
