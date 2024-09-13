## Usage:
##  Run:
##      export DBT_CLOUD_ACCOUNT_ID=?
##      export DBT_CLOUD_PROJECT_ID=?
##      export DBT_CLOUD_ENVIRONMENT_ID=?
##      python dbt_packages/audit_helper_ext/scripts/create_dbt_jobs_as_code.py models/03_mart
##      python dbt_packages/audit_helper_ext/scripts/create_dbt_jobs_as_code.py models/03_mart sample_target_1
import os
import sys
import yaml

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.dirname(SCRIPT_DIR))

from scripts.common import get_args, get_models


deactivate_models = []
CRON_BASE = "0 17 * * 1-5"  # At 17:00 on every day-of-week from Monday through Friday.
MINUTES_BETWEEN_RUNS = 15   # We don't run all jobs at once to avoid OOM issue
BASE_JOB_CONFIG = f"""\
  compile: &val_job # Using this as the job template
    name: "👀 Compile 📍 "
    account_id: {os.environ.get("DBT_CLOUD_ACCOUNT_ID", 0)} # ❗ Mandatory
    execute_steps:
      - "dbt compile"
    execution:
      timeout_seconds: 0
    generate_docs: false
    run_generate_sources: false
    schedule:
      cron: "0 4 * * 1-5" # At 04:00 on every day-of-week from Monday through Friday.
    settings:
      target_name: default
      threads: 6
    triggers:
      custom_branch_only: false
      git_provider_webhook: false
      github_webhook: false
      schedule: false
    job_type: other
"""


def generate_yaml_string(models) -> str:
    """Generates a YAML string based on the given the model list

    Args:
        models (list): A list of models

    Returns:
        str: The generated YAML string.
    """

    yaml_string = f"""\
# Usage:
# - Plan: dbt-jobs-as-code plan dataops/dbt_cloud_jobs.yml -p {os.environ.get("DBT_CLOUD_PROJECT_ID", "PROJECT_ID")} -e {os.environ.get("DBT_CLOUD_ENVIRONMENT_ID", "ENVIRONMENT_ID")}
# - Sync: dbt-jobs-as-code sync dataops/dbt_cloud_jobs.yml -p {os.environ.get("DBT_CLOUD_PROJECT_ID", "PROJECT_ID")} -e {os.environ.get("DBT_CLOUD_ENVIRONMENT_ID", "ENVIRONMENT_ID")}
jobs:
{BASE_JOB_CONFIG}
"""
    minutes = int(CRON_BASE.split()[0])  # Extract initial minutes
    hours = int(CRON_BASE.split()[1])  # Extract initial hours

    for i, item in enumerate(models):
        job_id = f"validation_{i:05d}"
        model = item.get("model_name")

        # Calculate the next cron expression
        if i != 1:
            minutes = (minutes + MINUTES_BETWEEN_RUNS) % 60
            if minutes == 0:
                hours = (hours + 1) % 24
        cron_expression = f"{minutes} {hours} * * 1-5"

        # Don't schedule the jobs of the deactivated models
        if model in deactivate_models:
            scheduled = False
            job_type = 'other'
        else:
            scheduled = True
            job_type = 'scheduled'

        job_config = f"""\

  {job_id}: # { model }
    <<: *val_job
    name: "👀 {model} 📍 "
    execute_steps:
      - "dbt run -s validation_log"
      - "dbt run-operation clone_relation --args 'identifier: {model}"
      - "dbt build -s +{model} --exclude {model} --full-refresh"
      - "dbt build -s {model}"
      - "dbt run-operation validations__{model.lower()}"
    schedule:
      cron: "{cron_expression}"
    triggers:
      schedule: {scheduled}
    job_type: {job_type}
"""
        yaml_string += job_config

    return yaml_string


if __name__ == "__main__":
    mart_dir, model_name = get_args()

    models = get_models(directory=mart_dir, name=model_name)
    print(f"ℹ️  {len(models)} job(s) will be proceeded")
    yaml_string = generate_yaml_string(models)
    data = yaml.load(yaml_string, Loader=yaml.Loader)

    dataops_dir = "dataops"
    dbt_cloud_jobs_file_path = f"{dataops_dir}/dbt_cloud_jobs.yml"
    if not os.path.isdir(dataops_dir):
        os.makedirs(dataops_dir)
    with open(dbt_cloud_jobs_file_path, "w") as f:
        f.write(yaml_string)
    print(f"✅ File: {dbt_cloud_jobs_file_path} created or updated!")
