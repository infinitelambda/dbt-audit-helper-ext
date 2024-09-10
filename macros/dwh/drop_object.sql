{% macro drop_object(object_name, object_type='table', cascade=false, dry_run=false) %}
  {{ return(adapter.dispatch('drop_object', 'audit_helper_ext')(
    object_name=object_name,
    object_type=object_type,
    cascade=cascade,
    dry_run=dry_run
  )) }}
{% endmacro %}


{% macro default__drop_object(object_name, object_type, cascade, dry_run) %}

    {% set drop_statement %}
      drop {{ object_type }} if exists {{ object_name }} {% if cascade %} cascade {% endif %};
    {% endset %}

    {% if dry_run == false %}
      {% do run_query(drop_statement) %}
    {% endif %}

    {{ return(drop_statement) }}

{% endmacro %}
