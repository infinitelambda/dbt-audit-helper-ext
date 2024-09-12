{% macro clone_schema(source_schema, target_database=none, target_schema=none) %}
    {{ return(adapter.dispatch('clone_schema', 'audit_helper_ext')(
        source_schema=source_schema,
        target_database=target_database,
        target_schema=target_schema
    )) }}
{% endmacro %}


{% macro default__clone_schema(source_schema, target_database, target_schema) %}

    {# get target location #}
    {% set target_database = target_database or target.database  %}
    {% set target_schema = target_schema or audit_helper_ext.get_versioned_name(name=source_schema or target.schema) %}

    {# clone #}
    {% set target_schema -%}
      {{ target_database }}.{{ target_schema }}
    {%- endset %}
    {% do audit_helper_ext.clone_object(object_name=target_schema, source_object_name=source_schema, object_type="schema", replace=true) %}

{% endmacro %}
