{% macro clone_object(object_name, source_object_name, object_type="table", replace=true, dry_run=false) %}
  {{ return(adapter.dispatch('clone_object', 'audit_helper_ext')(
    object_name=object_name,
    source_object_name=source_object_name,
    object_type=object_type,
    replace=replace,
    dry_run=dry_run
  )) }}
{% endmacro %}


{% macro default__clone_object(object_name, source_object_name, object_type, replace, dry_run) %}

    {% set clone_statement -%}

      create {% if replace %} or replace {% endif %} {{ object_type }} {% if not replace %} if not exists {% endif %} {{ object_name }}
      clone {{ source_object_name }};

    {%- endset %}

    {% if dry_run == false %}
      {% do run_query(clone_statement) %}
    {% else %}
      {{ log("sql: \n" ~ clone_statement, info=True) }}
    {% endif %}

    {{ return(clone_statement) }}

{% endmacro %}
