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


{% macro postgres__create_or_replace_table_as(relation, sql, config, dry_run) -%}

  {% set create_statement -%}

    {{ sql_header if sql_header is not none }}
    drop table if exists {{ relation }};
    create table {{ relation }}
    as (
      {{ sql }}
    );

  {%- endset %}

  {{ log_debug("\n" ~ create_statement, info=True) if dry_run }}
  {% if dry_run == false %}
    {% do run_query(create_statement) %}
  {% endif %}

  {{ return(create_statement) }}

{% endmacro %}


{% macro duckdb__create_or_replace_table_as(relation, sql, config, dry_run) -%}

  {# DuckDB supports `create or replace table`, but when this runs inside a run-operation #}
  {# (e.g. detail persistence) the write can sit in an open transaction that DuckDB rolls #}
  {# back on process exit. Follow the CTAS with an explicit commit + checkpoint so the #}
  {# table is durably flushed to the database file rather than silently discarded. #}
  {% set create_statement -%}

    {{ sql_header if sql_header is not none }}
    create or replace table {{ relation }}
    as (
      {{ sql }}
    )

  {%- endset %}

  {{ log_debug("\n" ~ create_statement, info=True) if dry_run }}
  {% if dry_run == false %}
    {% do run_query(create_statement) %}
    {% do adapter.commit() %}
    {% do run_query('checkpoint') %}
  {% endif %}

  {{ return(create_statement) }}

{% endmacro %}
