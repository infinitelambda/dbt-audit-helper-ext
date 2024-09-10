{% macro get_versioned_name(name) %}
  {{ return(adapter.dispatch('get_versioned_name', 'audit_helper_ext')(name=name)) }}
{% endmacro %}


{% macro default__get_versioned_name(name) %}

    {% set yyyymmdd = audit_helper_ext.date_of_process(format=true) %}
    {{ return(name ~ "__" ~ yyyymmdd) }}

{% endmacro %}
