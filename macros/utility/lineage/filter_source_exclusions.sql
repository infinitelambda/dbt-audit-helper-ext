{% macro filter_source_exclusions(source_nodes) %}
    {{ return(adapter.dispatch('filter_source_exclusions', 'audit_helper_ext')(
        source_nodes=source_nodes
    )) }}
{% endmacro %}


{% macro default__filter_source_exclusions(source_nodes) %}

    {% set audit_helper_ext__source_exclusions = context.get('audit_helper_ext__source_exclusions', none) %}
    {% if audit_helper_ext__source_exclusions is none %}
        {{ return(source_nodes) }}
    {% endif %}

    {% set exclude_database, exclude_schema = audit_helper_ext__source_exclusions() %}
    {% set filtered_sources = [] %}
    {% for source_node in source_nodes %}
        {% set db_match = exclude_database is not none and (exclude_database | upper) in (source_node.database | upper) %}
        {% set schema_match = exclude_schema is not none and (exclude_schema | upper) in (source_node.schema | upper) %}
        {% if db_match or schema_match %}
            {{ log("ℹ️ ⏭️  Excluding source " ~ source_node.source_name ~ "." ~ source_node.name ~ " (matched source_exclusions: database='" ~ source_node.database ~ "', schema='" ~ source_node.schema ~ "').", info=true) }}
        {% else %}
            {% do filtered_sources.append(source_node) %}
        {% endif %}
    {% endfor %}

    {{ return(filtered_sources) }}

{% endmacro %}
