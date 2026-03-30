{% macro filter_source_exclusions(source_nodes) %}
    {{ return(adapter.dispatch('filter_source_exclusions', 'audit_helper_ext')(
        source_nodes=source_nodes
    )) }}
{% endmacro %}


{% macro default__filter_source_exclusions(source_nodes) %}

    {% set call__source_exclusions = context.get('audit_helper_ext__source_exclusions', none) %}
    {% if call__source_exclusions is none %}
        {{ return(source_nodes) }}
    {% endif %}
    {% set exclude_config = call__source_exclusions() %}
    {% set exclude_database = exclude_config.get('exclude_database', none) %}
    {% set exclude_schema = exclude_config.get('exclude_schema', none) %}
    {% set filtered_sources = [] %}
    {% for source_node in source_nodes %}
        {% set db_match = exclude_database is not none and (exclude_database | upper) in (source_node.database | upper) %}
        {% set schema_match = exclude_schema is not none and (exclude_schema | upper) in (source_node.schema | upper) %}
        {% if not (db_match or schema_match) %}
            {% do filtered_sources.append(source_node) %}
        {% endif %}
    {% endfor %}

    {{ return(filtered_sources) }}

{% endmacro %}
