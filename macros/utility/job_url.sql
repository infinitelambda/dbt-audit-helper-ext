{% macro job_url() %}
  {{ return(adapter.dispatch('job_url', 'audit_helper_ext')()) }}
{% endmacro %}


{% macro default__job_url() %}
  {{ return(
    "https://"
    ~ env_var("DBT_CLOUD_HOST_URL", var("audit_helper__dbt_host_url", "emea.dbt.com"))
    ~ "/deploy/"
    ~ env_var("DBT_CLOUD_ACCOUNT_ID", "core")
    ~ "/projects/"
    ~ env_var("DBT_CLOUD_PROJECT_ID", "core")
    ~ "/jobs/"
    ~ env_var("DBT_CLOUD_JOB_ID", "core")
  ) }}
{% endmacro %}
