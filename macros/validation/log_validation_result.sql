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

  {% set insert_query -%}
    insert into {{ ref('validation_log') }} (
        mart_table,
        dbt_cloud_job_url,
        dbt_cloud_job_run_url,
        date_of_process,
        dbt_cloud_job_start_at,
        old_relation,
        dbt_relation,
        mart_path,
        validation_type,
        validation_result_json
    )
    select
        '{{ dbt_identifier }}',
        'https://{{ env_var("DBT_CLOUD_HOST_URL", var("audit_helper__dbt_cloud_host_url", "emea.dbt.com")) }}/deploy/{{ env_var("DBT_CLOUD_ACCOUNT_ID", "core") }}/projects/{{ env_var("DBT_CLOUD_PROJECT_ID", "core") }}/jobs/{{ env_var("DBT_CLOUD_JOB_ID", "core") }}',
        'https://{{ env_var("DBT_CLOUD_HOST_URL", var("audit_helper__dbt_cloud_host_url", "emea.dbt.com")) }}/deploy/{{ env_var("DBT_CLOUD_ACCOUNT_ID", "core") }}/projects/{{ env_var("DBT_CLOUD_PROJECT_ID", "core") }}/runs/{{ env_var("DBT_CLOUD_RUN_ID", "core") }}',
        '{{ audit_helper_ext.date_of_process() }}',
        cast('{{ run_started_at }}' as {{ dbt.type_timestamp() }}),
        '{{ old_relation }}',
        '{{ dbt_relation }}',
        '{{ mart_path }}',
        '{{ type }}',
        --escape double-quote in old_relation so that json is parsable
        replace(
          {{ audit_helper_ext.unicode_prefix() }}'{{ tojson(audit_helper_ext.convert_query_result_to_list(result)) }}', 
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
    {{ log("ℹ️  Validation result of " ~ dbt_identifier ~ " " ~ type ~ " was inserted!", info=True) }}
  {% endif %}

{% endmacro %}
