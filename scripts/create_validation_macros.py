## Usage:
##  If all source tables are in the same location:
##      export SOURCE_SCHEMA=?
##      export SOURCE_DATABASE=?
##  If any specific, go to that model config and add:
##      {{
##        config(
##          ...
##          audit_helper__source_database = 'DB',
##          audit_helper__source_schema = 'SC'
##        )
##      }}
##  Run:
##      python dbt_packages/audit_helper_ext/scripts/create_validation_macros.py models/03_mart
##      python dbt_packages/audit_helper_ext/scripts/create_validation_macros.py models/03_mart sample_target_1
import os
import re
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.dirname(SCRIPT_DIR))

from scripts.common import get_args, get_models


def create_validation_config(model_name, model_dir, schema_name, database_name, old_identifier):
    """Template of `get_validation_config__model` macro"""
    output_str = f"""
{{# Validation config #}}
{{%- macro get_validation_config__{model_name}() -%}}

    {{% set dbt_identifier = '{model_name}' %}}

    {{% set old_database = {database_name} %}}
    {{% set old_schema = {schema_name} %}}
    {{% set old_identifier = {old_identifier} %}}

    {{%- set primary_keys = [{get_model_config(f"{model_dir}/{model_name}", "unique_key")}] -%}}
    {{%- set exclude_columns = [{get_model_config(f"{model_dir}/{model_name}", "audit_helper__exclude_columns")}] -%}}

    {{{{ log('👀  ' ~ old_database ~ '.' ~ old_schema ~ '.' ~ old_identifier ~ ' vs. ' ~ ref(dbt_identifier), true) if execute }}}}
    {{{{ return(namespace(
            dbt_identifier=dbt_identifier,
            old_database=old_database,
            old_schema=old_schema,
            old_identifier=old_identifier,
            primary_keys=primary_keys,
            exclude_columns=exclude_columns,
    )) }}}}

{{% endmacro %}}"""

    return output_str


def create_validation_count(model_name, schema_name, database_name):
    """Template of `validation_count__model` macro"""
    output_str = f"""
{{# Row count #}}
{{%- macro validation_count__{model_name}() %}}

    {{% set validation_config = get_validation_config__{model_name}() %}}
    {{% if execute %}}

        {{{{ audit_helper_ext.get_validation_count(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier
        ) }}}}

    {{% endif %}}

{{% endmacro %}}"""

    return output_str


def create_validation_full(model_name, model_dir, schema_name, database_name):
    """Template of `validation__model` macro"""
    output_str = f"""
{{# Row-by-row validation #}}
{{%- macro validation_full__{model_name}(summarize=true) -%}}

    {{% set validation_config = get_validation_config__{model_name}() %}}
    {{% if execute %}}

        {{{{ audit_helper_ext.get_validation_full(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier,
            primary_keys=validation_config.primary_keys,
            exclude_columns=validation_config.exclude_columns,
            summarize=summarize
        ) }}}}

    {{% endif %}}

{{% endmacro %}}"""

    return output_str


def create_validation_all_col(model_name, model_dir, schema_name, database_name):
    """Template of `validation_all_col__model` macro"""
    output_str = f"""
{{# Column comparison #}}
{{%- macro validation_all_col__{model_name}(summarize=true) -%}}

    {{% set validation_config = get_validation_config__{model_name}() %}}
    {{% if execute %}}

        {{{{ audit_helper_ext.get_validation_all_col(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier,
            primary_keys=validation_config.primary_keys,
            exclude_columns=validation_config.exclude_columns,
            summarize=summarize
        ) }}}}

    {{% endif %}}

{{% endmacro %}}"""

    return output_str


def create_validations(model_name, model_dir, schema_name, database_name):
    """
    Template of the macro for running all validation at once
    Useful to shorten the dbt cloud job steps
    """
    output_str = f"""
{{# Validations for All #}}
{{%- macro validations__{model_name}(summarize=true) -%}}

    {{% set validation_config = get_validation_config__{model_name}() %}}
    {{% if execute %}}

        {{{{ audit_helper_ext.get_upstream_row_count(
            dbt_identifier=validation_config.dbt_identifier
        ) }}}}

        {{{{ audit_helper_ext.get_validation_schema(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier
        ) }}}}

        {{{{ audit_helper_ext.get_validation_full(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier,
            primary_keys=validation_config.primary_keys,
            exclude_columns=validation_config.exclude_columns,
            summarize=summarize
        ) }}}}

        {{{{ audit_helper_ext.get_validation_count(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier
        ) }}}}

    {{% endif %}}

{{% endmacro %}}"""

    return output_str


def create_validation_count_by_group(model_name, schema_name, database_name):
    """Template of `validation_count_by_group__model` macro"""
    output_str = f"""
{{# Row count by group #}}
{{%- macro validation_count_by_group__{model_name}(group_by) %}}

    {{% set validation_config = get_validation_config__{model_name}() %}}
    {{% if execute %}}

        {{{{ audit_helper_ext.get_validation_count_by_group(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier,
            group_by=group_by
        ) }}}}

    {{% endif %}}

{{% endmacro %}}"""

    return output_str


def create_validation_col(model_name, model_dir, schema_name, database_name):
    """Template of `validation_col__model` macro"""
    output_str = f"""
{{# Show column conflicts #}}
{{%- macro validation_col__{model_name}(columns_to_compare, summarize=true, limit=100) -%}}

    {{% set validation_config = get_validation_config__{model_name}() %}}
    {{% if execute %}}

        {{{{ audit_helper_ext.show_validation_columns_conflicts(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier,
            primary_keys=validation_config.primary_keys,
            columns_to_compare=columns_to_compare,
            summarize=summarize,
            limit=limit
        ) }}}}

    {{% endif %}}

{{% endmacro %}}"""

    return output_str


def create_validation_schema(model_name, schema_name, database_name):
    """Template of `validation_schema__model` macro"""
    output_str = f"""
{{# Schema diff validation #}}
{{%- macro validation_schema__{model_name}() -%}}

    {{% set validation_config = get_validation_config__{model_name}() %}}
    {{% if execute %}}

        {{{{ audit_helper_ext.get_validation_schema(
            dbt_identifier=validation_config.dbt_identifier,
            old_database=validation_config.old_database,
            old_schema=validation_config.old_schema,
            old_identifier=validation_config.old_identifier
        ) }}}}

    {{% endif %}}

{{% endmacro %}}"""

    return output_str


def get_model_config(model_path, config_attr="unique_key", config_attr_type="list"):
    """Extract model config if exists"""
    with open(f"{model_path}.sql", "r") as f:
        content = f.read()

    result = ""
    pattern = f"\\b{config_attr}\\s*=\\s*\\[(.*?)\\]"
    if config_attr_type != "list":
        pattern = f"\\b{config_attr}\\s*=\\s*'(.*?)'"
    match = re.search(pattern, content)
    if match:
        result = match.group(1)

    return result


def create_validation_file(model: dict):
    """Create the model's validation file contains all macos"""
    model_name, model_dir = model.get("model_name"), model.get("model_dir")
    model_path = f"{model_dir}/{model_name}"
    schema_name = f"""'{get_model_config(
        model_path,
        config_attr="audit_helper__source_schema",
        config_attr_type="string",
    ) or os.environ.get("SOURCE_SCHEMA", "") }'"""
    if schema_name == "''":
        schema_name = "audit_helper_ext.get_versioned_name(name=var('audit_helper__source_schema', target.schema))"
    database_name = f"""'{get_model_config(
        model_path,
        config_attr="audit_helper__source_database",
        config_attr_type="string",
    ) or os.environ.get("SOURCE_DATABASE", "")}'"""
    if database_name == "''":
        database_name =  "var('audit_helper__source_database', target.database)"

    # Extract old_identifier configuration
    old_identifier_config = get_model_config(
        model_path,
        config_attr="audit_helper__old_identifier",
        config_attr_type="string",
    )
    if old_identifier_config:
        old_identifier = f"'{old_identifier_config}'"
    else:
        old_identifier = f"audit_helper_ext.get_old_identifier_name('{model_name}')"

    macro_config = create_validation_config(model_name, model_dir, schema_name, database_name, old_identifier)
    macro_count = create_validation_count(model_name, schema_name, database_name)
    macro_schema = create_validation_schema(model_name, schema_name, database_name)
    macro_all_col = create_validation_all_col(
        model_name, model_dir, schema_name, database_name
    )
    macro_full = create_validation_full(model_name, model_dir, schema_name, database_name)
    macro_all = create_validations(model_name, model_dir, schema_name, database_name)
    macro_count_by_group = create_validation_count_by_group(model_name, schema_name, database_name)
    macro_col = create_validation_col(model_name, model_dir, schema_name, database_name)

    output_str = (
        macro_config
        + "\n\n"
        + macro_count
        + "\n\n"
        + macro_schema
        + "\n\n"
        + macro_all_col
        + "\n\n"
        + macro_full
        + "\n\n"
        + macro_all
        + "\n\n"
        + macro_count_by_group
        + "\n\n"
        + macro_col
        + "\n"
    ).lstrip()

    base_dir = "macros/validation"
    validation_dir = f"{base_dir}/{model_dir[6:]}"
    if not os.path.isdir(validation_dir):
        os.makedirs(validation_dir)
    validation_file = f"{validation_dir}/validation__{model_name}.sql"
    with open(validation_file, "w", encoding="utf-8") as f:
        f.write(output_str)
    print(f"    ✅ {validation_file} created or updated!")


if __name__ == "__main__":
    mart_dir, model_name = get_args()

    models = get_models(directory=mart_dir, name=model_name)
    for m in models:
        print(f"🏃 Working on the model: {m.get('model_name')} ...")
        create_validation_file(model=m)
        print("◾◾◾")
    print("🚏🚏🚏")
