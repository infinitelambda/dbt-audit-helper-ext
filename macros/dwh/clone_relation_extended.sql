{% macro clone_relation_extended(identifier, source_database=none, source_schema=none, source_table_names=none, tag=none, use_prev=true) %}
    {{ return(adapter.dispatch('clone_relation_extended', 'audit_helper_ext')(
        identifier=identifier,
        source_database=source_database,
        source_schema=source_schema,
        source_table_names=source_table_names,
        tag=tag,
        use_prev=use_prev
    )) }}
{% endmacro %}


{% macro default__clone_relation_extended(identifier, source_database, source_schema, source_table_names, tag, use_prev) %}

    {% if execute %}
        {# -- Clone the target model itself -- #}
        {{ log("ℹ️ 📌 Cloning target model: " ~ identifier, info=true) }}
        {% do audit_helper_ext.clone_relation(
            identifier=identifier,
            source_database=source_database,
            source_schema=source_schema,
            use_prev=use_prev
        ) %}

        {# -- Clone dependent relations (JOIN/LOOKUP tables) -- #}
        {% set sources_to_clone = audit_helper_ext.get_dependent_source_nodes(
            identifier=identifier,
            source_table_names=source_table_names,
            tag=tag
        ) %}

        {% set sources_to_clone = audit_helper_ext.filter_source_exclusions(sources_to_clone) %}

        {% if sources_to_clone | length == 0 %}
            {{ log("ℹ️  No dependent relations found for model '" ~ identifier ~ "'.", info=true) }}
            {{ return(none) }}
        {% endif %}

        {{ log("ℹ️ 🔍 Found " ~ sources_to_clone | length ~ " dependent relation(s) to clone for model '" ~ identifier ~ "'.", info=true) }}

        {# -- Use the same versioned schema as the target model -- #}
        {% set versioned_schema = audit_helper_ext.get_versioned_name(
            name=var('audit_helper__source_schema', target.schema),
            use_prev=use_prev
        ) %}

        {% for source_node in sources_to_clone %}
            {{ log("ℹ️ 🔄 [" ~ loop.index ~ "/" ~ sources_to_clone | length ~ "] Cloning: " ~ source_node.source_name ~ "." ~ source_node.name, info=true) }}

            {% do audit_helper_ext.clone_relation(
                identifier=source_node.name,
                source_database=source_node.database,
                source_schema=versioned_schema,
                use_prev=use_prev
            ) %}
        {% endfor %}

    {% endif %}

{% endmacro %}
