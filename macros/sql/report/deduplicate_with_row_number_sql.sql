
{% macro deduplicate_with_row_number_sql(
  source_relation,
  partition_by_fields,
  order_by_fields
) %}
  {{ return(adapter.dispatch('deduplicate_with_row_number_sql', 'audit_helper_ext')(
    source_relation,
    partition_by_fields,
    order_by_fields
  )) }}
{% endmacro %}


{% macro sqlserver__deduplicate_with_row_number_sql(
  source_relation,
  partition_by_fields,
  order_by_fields
) %}

  {% set sql -%}
    select *
    from (
      select
          *,
          row_number() over (
            partition by {{ partition_by_fields | join(', ') }}
            order by {{ order_by_fields | join(', ') }}
          ) rn
      from {{ source_relation }}
    ) as T
    where T.rn = 1
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro postgres__deduplicate_with_row_number_sql(
  source_relation,
  partition_by_fields,
  order_by_fields
) %}

  {% set sql -%}
    select *
    from (
      select
          *,
          row_number() over (
            partition by {{ partition_by_fields | join(', ') }}
            order by {{ order_by_fields | join(', ') }}
          ) rn
      from {{ source_relation }}
    ) as T
    where T.rn = 1
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}


{% macro default__deduplicate_with_row_number_sql(
  source_relation,
  partition_by_fields,
  order_by_fields
) %}

  {% set sql -%}
    select *
    from {{ source_relation }}
    where 1=1
    qualify row_number() over (
      partition by {{ partition_by_fields | join(', ') }}
      order by {{ order_by_fields | join(', ') }}
    ) = 1
  {%- endset %}

  {{ return(sql) }}

{% endmacro %}
