{% macro filter_source_exclusions(source_nodes, identifiers=none, exclude_identifiers=none) %}
    {{ return(adapter.dispatch('filter_source_exclusions', 'audit_helper_ext')(
        source_nodes=source_nodes,
        identifiers=identifiers,
        exclude_identifiers=exclude_identifiers
    )) }}
{% endmacro %}


{% macro default__filter_source_exclusions(source_nodes, identifiers, exclude_identifiers) %}

    {% set filtered_sources = [] %}

    {# -- Exclude target models themselves from dependent relations (cyclic-dep check) -- #}
    {% if identifiers is not none %}
        {% set identifier_upper_list = identifiers.split(',') | map('trim') | select | map('upper') | list %}
        {% for source_node in source_nodes %}
            {% if (source_node.name | upper in identifier_upper_list)
                and (source_node.config.get(meta, {}).get("audit_helper_ext__ignore_cyclic_deps", 0) == 0) %}
                {{ log(
                    "⚠️  Excluding dependent relation '" ~ source_node.source_name ~ ":" ~ source_node.name ~ "' (potential cyclic dependencies)."
                    " Add <source>.config.meta.audit_helper_ext__ignore_cyclic_deps = 1 to bypass this exclusion.", info=true)
                }}
            {% else %}
                {% do filtered_sources.append(source_node) %}
            {% endif %}
        {% endfor %}
    {% else %}
        {% set filtered_sources = source_nodes | list %}
    {% endif %}

    {# -- Exclude sources by user-supplied identifier list -- #}
    {% if exclude_identifiers is not none %}
        {% set exclude_upper_list = exclude_identifiers.split(',') | map('trim') | select | map('upper') | list %}
        {% set user_filtered_sources = [] %}
        {% for source_node in filtered_sources %}
            {% if source_node.name | upper in exclude_upper_list %}
                {{ log(
                    "⚠️  Excluding dependent relation '" ~ source_node.source_name ~ ":" ~ source_node.name ~ "' (matched exclude_identifiers).", info=true)
                }}
            {% else %}
                {% do user_filtered_sources.append(source_node) %}
            {% endif %}
        {% endfor %}
        {% set filtered_sources = user_filtered_sources %}
    {% endif %}

    {# -- Exclude sources by database/schema patterns (user-defined hook) -- #}
    {% set call__source_exclusions = context.get('audit_helper_ext__source_exclusions', none) %}
    {% if call__source_exclusions is none %}
        {{ return(filtered_sources) }}
    {% endif %}
    {% set exclude_config = call__source_exclusions() %}
    {% set exclude_database = exclude_config.get('exclude_database', none) %}
    {% set exclude_schema = exclude_config.get('exclude_schema', none) %}
    {% set final_sources = [] %}
    {% for source_node in filtered_sources %}
        {% set db_match = exclude_database is not none and (exclude_database | upper) in (source_node.database | upper) %}
        {% set schema_match = exclude_schema is not none and (exclude_schema | upper) in (source_node.schema | upper) %}
        {% if not (db_match or schema_match) %}
            {% do final_sources.append(source_node) %}
        {% endif %}
    {% endfor %}

    {{ return(final_sources) }}

{% endmacro %}
