{% macro log_validation_result(type, result, dbt_identifier, dbt_relation, old_relation) %}
  {{ return(adapter.dispatch('log_validation_result', 'audit_helper_ext')(
    type=type,
    result=result,
    dbt_identifier=dbt_identifier,
    dbt_relation=dbt_relation,
    old_relation=old_relation
  )) }}
{% endmacro %}


{% macro default__log_validation_result(type, result, dbt_identifier, dbt_relation, old_relation) %}

  {% set mart_path =
      ( graph.nodes.values()
      | selectattr("name", "equalto", dbt_identifier)
      | first)
      ['path']
  %}

  {% set log_relation = ref('validation_log') %}
  {% set insert_query -%}
    insert into {{ log_relation }} (
        mart_table,
        job_url,
        job_run_url,
        date_of_process,
        job_started_at,
        old_relation,
        dbt_relation,
        mart_path,
        validation_type,
        validation_result_json
    )
    select
        '{{ dbt_identifier }}',
        '{{ audit_helper_ext.job_url() }}',
        '{{ audit_helper_ext.job_run_url() }}',
        '{{ audit_helper_ext.date_of_process() }}',
        {{ audit_helper_ext.job_started_at() }},
        '{{ old_relation }}',
        '{{ dbt_relation }}',
        '{{ mart_path }}',
        '{{ type }}',
        --escape double-quote in old_relation so that json is parsable
        replace(
          {{ audit_helper_ext.unicode_prefix() }}'{{ tojson(audit_helper_ext.convert_query_result_to_list(result)) | replace("'", "''") }}', 
          {{ audit_helper_ext.unicode_prefix() }}'{{ old_relation }}',
          replace(
            {{ audit_helper_ext.unicode_prefix() }}'{{ old_relation }}', 
            {{ audit_helper_ext.unicode_prefix() }}'"', 
            {{ audit_helper_ext.unicode_prefix() }}'\\"'
          )
        )
    ;
  {%- endset %}

  {% if execute %}
    {% do run_query(insert_query) %}
    {{ log("ℹ️  Validation result of " ~ dbt_identifier ~ " " ~ type ~ " was inserted at " ~ log_relation, info=True) }}

    {# Apply data quality checks based on validation type #}
    {{ audit_helper_ext.print_validation_result_status(
        result=result,
        validation_type=type
    ) }}
  {% endif %}

{% endmacro %}
