{% macro create_or_replace_table_as(relation, sql, config=none, dry_run=false) %}
  {{ return(adapter.dispatch('create_or_replace_table_as', 'audit_helper_ext')(
    relation=relation,
    sql=sql,
    config=config,
    dry_run=dry_run
  )) }}
{% endmacro %}


{% macro default__create_or_replace_table_as(relation, sql, config, dry_run) -%}

  {% set create_statement -%}

    {{ sql_header if sql_header is not none }}
    create or replace table {{ relation }}
    {% if config.get("kms_key_name") is not none -%}
    options (
      kms_key_name='{{ config.get("kms_key_name") }}'
    )
    {% endif -%}
    as (
      {{ sql }}
    )

  {%- endset %}

  {{ log_debug("\n" ~ create_statement, info=True) if dry_run }}
  {% if dry_run == false %}
    {% do run_query(create_statement) %}
  {% endif %}

  {{ return(create_statement) }}

{% endmacro %}
