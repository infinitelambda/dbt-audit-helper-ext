{% macro clone_relation(identifier=identifier, identifier_database=none, identifier_schema=none, is_target_versioned=false) %}
    {{ return(adapter.dispatch('clone_relation', 'audit_helper_ext')(
        identifier=identifier,
        identifier_database=identifier_database,
        identifier_schema=identifier_schema,
        is_target_versioned=is_target_versioned
    )) }}
{% endmacro %}


{% macro default__clone_relation(identifier, identifier_database, identifier_schema, is_target_versioned) %}

    {% set copy_mode = 'clone' %}
    {# clone from [id_YYYYMMDD] to [id] #}
    {% set source_id, target_id = audit_helper_ext.get_versioned_identifier(identifier), identifier %}
    {% if is_target_versioned %}
        {# clone from [id] to [id_YYYYMMDD] #}
      {% set source_id, target_id = target_id, source_id %}
    {% endif %}

    {# checking source #}
    {% set source_relation_exists, source_relation, _ = audit_helper_ext.get_relation(
        identifier=source_id,
        identifier_database=identifier_database,
        identifier_schema=identifier_schema,
        node_name=identifier
    ) %}
    {% if source_relation_exists == false %}
        {% do exceptions.raise_compiler_error("❌ The table " ~ source_relation.identifier ~ " cannot be found at " ~  source_relation ~ "." ) %}
    {% elif source_relation_exists == true and source_relation.type == 'view' %}
        {{ log("ℹ️ 😮  The source `" ~ source_relation.identifier ~ "` is a view, it cannot be cloned. A select * statement will be used instead.", true) }}
        {% set copy_mode = 'select' %}
    {% endif %}

    {# checking target #}
    {% set target_relation_exists, target_relation, target_config = audit_helper_ext.get_relation(
        identifier=target_id,
        identifier_database=identifier_database,
        identifier_schema=identifier_schema,
        node_name=identifier
    ) %}
    {% if target_relation_exists == true and target_relation.type == 'view' %}
        {{ log("ℹ️ 🗑️  " ~ target_relation.identifier ~ " exists as a view, it needs to be dropped first.", true) }}
        {% do audit_helper_ext.drop_object(object_name=target_relation, object_type="view") %}
    {% elif target_relation_exists == true and target_relation.type == 'table'  %}
        {{ log("ℹ️ ♻️  The table `" ~ target_relation.identifier ~ "` will be replaced with a fresh version, using " ~ source_relation ~ ".", true) }}
    {% else %}
        {{ log("ℹ️ 🐣  The table `" ~ target_relation.identifier ~ "` will be created using " ~ source_relation ~ ".", true) }}
    {% endif %}

    {# perform clone #}
    {% if copy_mode == 'select' %}
        {% set sql = 'select * from ' ~ source_relation %}
        {% do audit_helper_ext.create_or_replace_table_as(relation=target_relation, sql=sql, config=target_config) %}
    {% elif copy_mode == 'clone' %}
        {% do audit_helper_ext.clone_object(object_name=target_relation, source_object_name=source_relation, replace=true) %}
    {% endif %}

{% endmacro %}
