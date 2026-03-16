{% macro clone_schema_day0(schemas) %}
    {{ return(adapter.dispatch('clone_schema_day0', 'audit_helper_ext')(
        schemas=schemas
    )) }}
{% endmacro %}


{% macro default__clone_schema_day0(schemas) %}

    {# Split comma-separated schemas and trim whitespace #}
    {% set schema_list = schemas.split(',') %}

    {% for schema_name in schema_list %}

        {% set schema_name = schema_name | trim %}
        {% if schema_name %}

            {% set source_schema = audit_helper_ext.get_versioned_name(name=schema_name) %}

            {{ log("ℹ️ 🔄 Cloning `" ~ source_schema ~ "` → `" ~ schema_name ~ "`", info=True) }}

            {% do audit_helper_ext.clone_schema(
                source_schema=source_schema,
                target_schema=schema_name
            ) %}

        {% endif %}

    {% endfor %}

{% endmacro %}
