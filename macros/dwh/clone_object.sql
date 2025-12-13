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

    {{ log("ℹ️ 🐣  The " ~ object_type ~ " `" ~ object_name ~ "` will be created using `" ~ source_object_name ~ "`.", true) }}
    {{ log_debug("\n" ~ clone_statement, info=True) if dry_run }}
    {% if dry_run == false %}
      {% do run_query(clone_statement) %}
    {% endif %}

    {{ return(clone_statement) }}

{% endmacro %}


{% macro postgres__clone_object(object_name, source_object_name, object_type, replace, dry_run) %}

    {% set clone_statement -%}
      begin;
      {% if replace -%}
        drop {{ object_type }} if exists {{ object_name }};
      {%- endif %}
      create {{ object_type }} {{ object_name }}
      as select * from {{ source_object_name }};
      commit;
    {%- endset %}

    {{ log("ℹ️ 🐣  The " ~ object_type ~ " `" ~ object_name ~ "` will be created using `" ~ source_object_name ~ "`.", true) }}
    {{ log_debug("\n" ~ clone_statement, info=True) if dry_run }}
    {% if dry_run == false %}
      {% do run_query(clone_statement) %}
    {% endif %}

    {{ return(clone_statement) }}

{% endmacro %}


{% macro sqlserver__clone_object(object_name, source_object_name, object_type, replace, dry_run) %}

    {% set clone_statement -%}
      {% if replace -%}
        drop {{ object_type }} if exists {{ object_name }}
      {%- endif %}
      select *
      into {{ object_name }}
      from {{ source_object_name }}
    {%- endset %}

    {{ log("ℹ️ 🐣  The " ~ object_type ~ " `" ~ object_name ~ "` will be created using `" ~ source_object_name ~ "`.", true) }}
    {{ log_debug("\n" ~ clone_statement, info=True) if dry_run }}
    {% if dry_run == false %}
      {% do run_query(clone_statement) %}
    {% endif %}

    {{ return(clone_statement) }}

{% endmacro %}


{% macro databricks__clone_object(object_name, source_object_name, object_type, replace, dry_run) %}

    {# Use deep clone for complete independent copy with proper schema handling #}
    {% set clone_statement -%}
      create or replace {{ object_type }} {{ object_name }}
      deep clone {{ source_object_name }}
    {%- endset %}

    {{ log("ℹ️ 🐣  The " ~ object_type ~ " `" ~ object_name ~ "` will be created using `" ~ source_object_name ~ "`.", true) }}
    {{ log_debug("\n" ~ clone_statement, info=True) if dry_run }}
    {% if dry_run == false %}
      {% do run_query(clone_statement) %}
    {% endif %}

    {{ return(clone_statement) }}

{% endmacro %}
