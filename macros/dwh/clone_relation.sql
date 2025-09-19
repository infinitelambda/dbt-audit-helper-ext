{% macro clone_relation(identifier, source_database=none, source_schema=none, use_prev=false) %}
    {{ return(adapter.dispatch('clone_relation', 'audit_helper_ext')(
        identifier=identifier,
        source_database=source_database,
        source_schema=source_schema,
        use_prev=use_prev
    )) }}
{% endmacro %}


{% macro default__clone_relation(identifier, source_database, source_schema, use_prev) %}
    {% set copy_mode = 'clone' %}

    {# get source location #}
    {% set source_database = source_database or target.database %}
    {% set source_schema = source_schema 
                            or audit_helper_ext.get_versioned_name(
                                    name=var('audit_helper__source_schema', target.schema),
                                    use_prev=use_prev
                                )
    %}

    {# checking source table #}
    {% set source_relation_exists, source_relation, _ = audit_helper_ext.get_relation(
        identifier=identifier,
        identifier_database=source_database,
        identifier_schema=source_schema
    ) %}
    {% if source_relation_exists == false %}
        {% do exceptions.raise_compiler_error("❌ The table " ~ source_relation.identifier ~ " cannot be found at " ~  source_relation ~ "." ) %}
    {% elif source_relation_exists == true and source_relation.type == 'view' %}
        {{ log("ℹ️ 😮  The source `" ~ source_relation.identifier ~ "` is a view, it cannot be cloned. A select * statement will be used instead.", true) }}
        {% set copy_mode = 'select' %}
    {% endif %}

    {# checking target table #}
    {% set dbt_relation_exists, dbt_relation, dbt_config = audit_helper_ext.get_relation(identifier=identifier) %}
    {% if dbt_relation_exists == true and dbt_relation.type == 'view' %}
        {{ log("ℹ️ 🗑️  " ~ dbt_relation.identifier ~ " exists as a view, it needs to be dropped first.", true) }}
        {% do audit_helper_ext.drop_object(object_name=dbt_relation, object_type="view") %}
    {% elif dbt_relation_exists == true and dbt_relation.type == 'table'  %}
        {{ log("ℹ️ ♻️  The table `" ~ dbt_relation.identifier ~ "` will be replaced with a fresh version, using " ~ source_relation ~ ".", true) }}
    {% else %}
        {{ log("ℹ️ 🐣  The table `" ~ dbt_relation.identifier ~ "` will be created using " ~ source_relation ~ ".", true) }}
    {% endif %}

    {# perform clone source to target #}
    {% if copy_mode == 'select' %}
        {% set sql = 'select * from ' ~ source_relation %}
        {% do audit_helper_ext.create_or_replace_table_as(relation=dbt_relation, sql=sql, config=dbt_config) %}
    {% elif copy_mode == 'clone' %}
        {% do audit_helper_ext.clone_object(object_name=dbt_relation, source_object_name=source_relation, replace=true) %}
    {% endif %}

{% endmacro %}
