{# Extended compare_and_classify_relation_rows adding source (A) / dbt (B) WHERE filters, so #}
{# the persisted row-level detail table matches the filtered comparison. `a_filter` bounds #}
{# the source (A) side; `b_filter` bounds the dbt (B) side. Lives in the audit_helper_ext #}
{# namespace and is called directly by log_validation_detail_result. #}

{% macro compare_and_classify_relation_rows(a_relation, b_relation, primary_key_columns=[], columns=None, event_time=None, sample_limit=20, a_filter=none, b_filter=none) %}
  {{ return(adapter.dispatch('compare_and_classify_relation_rows', 'audit_helper_ext')(
    a_relation=a_relation,
    b_relation=b_relation,
    primary_key_columns=primary_key_columns,
    columns=columns,
    event_time=event_time,
    sample_limit=sample_limit,
    a_filter=a_filter,
    b_filter=b_filter
  )) }}
{% endmacro %}


{% macro default__compare_and_classify_relation_rows(a_relation, b_relation, primary_key_columns=[], columns=None, event_time=None, sample_limit=20, a_filter=none, b_filter=none) %}
    {%- if not columns -%}
        {%- set columns = audit_helper._get_intersecting_columns_from_relations(a_relation, b_relation) -%}
    {%- endif -%}

    {%- set a_query = "select * from " ~ a_relation ~ (" where " ~ a_filter if a_filter else "") -%}
    {%- set b_query = "select * from " ~ b_relation ~ (" where " ~ b_filter if b_filter else "") -%}

    {{
        audit_helper.compare_and_classify_query_results(
            a_query,
            b_query,
            primary_key_columns,
            columns,
            event_time,
            sample_limit
        )
    }}
{% endmacro %}
