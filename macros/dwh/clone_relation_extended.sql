{% macro clone_relation_extended(identifiers, source_database=none, source_schema=none, dependant_table_names=none, tag=none, use_prev=true, exclude_identifiers=none) %}
    {{ return(adapter.dispatch('clone_relation_extended', 'audit_helper_ext')(
        identifiers=identifiers,
        source_database=source_database,
        source_schema=source_schema,
        dependant_table_names=dependant_table_names,
        tag=tag,
        use_prev=use_prev,
        exclude_identifiers=exclude_identifiers
    )) }}
{% endmacro %}


{% macro default__clone_relation_extended(identifiers, source_database, source_schema, dependant_table_names, tag, use_prev, exclude_identifiers) %}

    {% if execute %}
        {# -- Parse comma-separated identifiers into a list -- #}
        {% set identifier_list = identifiers.split(',') | map('trim') | select | list %}
        {% set excluded_list = (exclude_identifiers or '').split(',') | map('trim') | select | list %}

        {# -- Clone each target model, skipping any listed in exclude_identifiers -- #}
        {% for id in identifier_list %}
            {% if id in excluded_list %}
                {{ log("⏭️  Skipping excluded target model: " ~ id, info=true) }}
            {% else %}
                {{ log("📌 Cloning target model: " ~ id, info=true) }}
                {% do audit_helper_ext.clone_relation(
                    identifier=id,
                    source_database=source_database,
                    source_schema=source_schema,
                    use_prev=use_prev
                ) %}
            {% endif %}
        {% endfor %}

        {# -- Collect dependent relations (JOIN/LOOKUP tables) across all identifiers -- #}
        {% set all_sources = audit_helper_ext.get_dependent_source_nodes(
            identifiers=identifiers,
            dependant_table_names=dependant_table_names,
            tag=tag
        ) %}

        {% set sources_to_clone = audit_helper_ext.filter_source_exclusions(all_sources, identifiers=identifiers, exclude_identifiers=exclude_identifiers) %}
        {% if sources_to_clone | length == 0 %}
            {{ log("ℹ️  No dependent relations found for model(s) '" ~ identifier_list | join("', '") ~ "'.", info=true) }}
            {{ return(none) }}
        {% endif %}

        {{ log("Found " ~ sources_to_clone | length ~ " dependent relation(s) to clone for model(s) '" ~ identifier_list | join("', '") ~ "':", info=true) }}
        {% for source_node in sources_to_clone %}
            {{ log("  " ~ loop.index ~ ". " ~ source_node.source_name ~ ":" ~ source_node.name, info=true) }}
        {% endfor %}

        {% for source_node in sources_to_clone %}
            {{ log("[" ~ loop.index ~ "/" ~ sources_to_clone | length ~ "] Cloning - " ~ source_node.source_name ~ ":" ~ source_node.name, info=true) }}

            {% set versioned_schema = audit_helper_ext.get_versioned_name(
                name=source_node.config.get('meta', {}).get('audit_helper_ext__source_schema'),
                use_prev=false)
            %}
            {% do audit_helper_ext.clone_relation(
                identifier=source_node.name,
                source_database=source_node.database,
                source_schema=versioned_schema,
                source_name=source_node.source_name,
                use_prev=false
            ) %}
        {% endfor %}

    {% endif %}

{% endmacro %}
