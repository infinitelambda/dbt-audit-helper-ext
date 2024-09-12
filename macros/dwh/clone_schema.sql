{% macro clone_schema(
    source_schema,
    target_database=none,
    target_database_versioned=false,
    target_schema=none,
    target_schema_versioned=true
) %}
    {{ return(adapter.dispatch('clone_schema', 'audit_helper_ext')(
        source_schema=source_schema,
        target_database=target_database,
        target_database_versioned=target_database_versioned,
        target_schema=target_schema,
        target_schema_versioned=target_schema_versioned
    )) }}
{% endmacro %}


{% macro default__clone_schema(
    source_schema,
    target_database,
    target_database_versioned,
    target_schema,
    target_schema_versioned
) %}

    {# get target location #}
    {% set target_database = target_database or target.database %}
    {% set target_schema = target_schema or source_schema or target.schema %}
    {% if target_database_versioned %}
        {% set target_database = audit_helper_ext.get_versioned_name(name=target_database) %}
    {% endif %}
    {% if target_schema_versioned %}
        {% set target_schema = audit_helper_ext.get_versioned_name(name=target_schema) %}
    {% endif %}

    {# clone #}
    {% set target_schema -%}
      {{ target_database }}.{{ target_schema }}
    {%- endset %}
    {% do audit_helper_ext.clone_object(object_name=target_schema, source_object_name=source_schema, object_type="schema", replace=true) %}

{% endmacro %}
