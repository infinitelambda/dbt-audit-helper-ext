{% macro get_versioned_identifier(identifier) %}
  {{ return(adapter.dispatch('get_versioned_identifier', 'audit_helper_ext')(identifier=identifier)) }}
{% endmacro %}


{% macro default__get_versioned_identifier(identifier) %}

    {% set yyyymmdd = audit_helper_ext.date_of_process(format=true) %}
    {{ return(identifier ~ "__" ~ yyyymmdd) }}

{% endmacro %}
