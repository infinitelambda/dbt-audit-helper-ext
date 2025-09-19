{% macro get_versioned_name(name, use_prev=false) %}
  {{ return(adapter.dispatch('get_versioned_name', 'audit_helper_ext')(name=name, use_prev=use_prev)) }}
{% endmacro %}


{% macro default__get_versioned_name(name, use_prev) %}

    {% set yyyymmdd = audit_helper_ext.date_of_process(format=true, use_prev=use_prev) %}
    {{ return(name ~ "__" ~ yyyymmdd) }}

{% endmacro %}
