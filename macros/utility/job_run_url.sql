{% macro job_run_url() %}
  {{ return(adapter.dispatch('job_run_url', 'audit_helper_ext')()) }}
{% endmacro %}


{% macro default__job_run_url() %}
  {{ return(
    "https://"
    ~ env_var("DBT_CLOUD_HOST_URL", var("audit_helper__dbt_host_url", "emea.dbt.com"))
    ~ "/deploy/"
    ~ env_var("DBT_CLOUD_ACCOUNT_ID", "core")
    ~ "/projects/"
    ~ env_var("DBT_CLOUD_PROJECT_ID", "core")
    ~ "/runs/"
    ~ env_var("DBT_CLOUD_RUN_ID", "core")
  ) }}
{% endmacro %}
