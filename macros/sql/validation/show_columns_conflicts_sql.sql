{% macro show_columns_conflicts_sql(a_relation, b_relation, primary_keys, columns_to_compare, summarize=true,limit=None) %}
  {{ return(adapter.dispatch('show_columns_conflicts_sql', 'audit_helper_ext')(
    a_relation=a_relation,
    b_relation=b_relation,
    primary_keys=primary_keys,
    columns_to_compare=columns_to_compare,
    summarize=summarize,
    limit=limit
  )) }}
{% endmacro %}



{% macro default__show_columns_conflicts_sql(a_relation, b_relation, primary_keys, columns_to_compare, summarize, limit) %}

  {% set primary_keys_csv, primary_keys = audit_helper_ext.convert_to_str_and_list(primary_keys) %}

  {% set columns_to_compare_csv, columns_to_compare = audit_helper_ext.convert_to_str_and_list(columns_to_compare) %}

  {% set include_columns_csv = (primary_keys + columns_to_compare) | join(',') %}


  {% set a_query %}
    select

    {{ include_columns_csv }}

    from {{ a_relation }}
  {% endset %}

  {% set b_query %}
    select

    {{ include_columns_csv }}

    from {{ b_relation }}
  {% endset %}

  {% set audit_query = audit_helper.compare_queries(
    a_query=a_query,
    b_query=b_query,
    summarize=false
  ) %}


  with audit_query as (
    {{ audit_query }}
  ),

  calculate_exp as (
    select
      *,
      count(*) over (partition by {{ primary_keys_csv }}) as __count_by_pk,
    from audit_query
  ),

  keep_conflicts as (
    select *
    from calculate_exp
    where
      __count_by_pk > 1
  ),

  {% if summarize -%}

  compare_conflicts as (
    select
      {{ primary_keys_csv }},

      {% for column in columns_to_compare -%}

      max(case when in_a is true then {{ column }} end) as {{ column ~ '__a' }},
      max(case when in_b is true then {{ column }} end) as {{ column ~ '__b' }}

      {{- "," if not loop.last else "" }}

      {% endfor %}

    from keep_conflicts
    group by {{ primary_keys_csv }}
  ),

  final as (
    {% set columns_to_compare_pivoted -%}

      {% for column in columns_to_compare -%}

      {{ column ~ '__a' }},
      {{ column ~ '__b' }}

      {{- "," if not loop.last else "" }}

      {% endfor %}

    {%- endset %}

    select
      {{ columns_to_compare_pivoted }},
      count(*) as count_conflicts,
    from compare_conflicts
    group by
      {{ columns_to_compare_pivoted }}
    order by
      count(*) desc

  )

  {% else -%}

  final as (
    select * except (__count_by_pk)
    from keep_conflicts
    order by
      {{ primary_keys_csv }},
      in_a
  )

  {%- endif %}


  select *
  from final

  {%- if limit %}
  limit {{ limit }}
  {%- endif %}

{% endmacro %}


{% macro sqlserver__show_columns_conflicts_sql(a_relation, b_relation, primary_keys, columns_to_compare, summarize, limit) %}

  {% set primary_keys_csv, primary_keys = audit_helper_ext.convert_to_str_and_list(primary_keys) %}

  {% set columns_to_compare_csv, columns_to_compare = audit_helper_ext.convert_to_str_and_list(columns_to_compare) %}

  {% set include_columns_csv = (primary_keys + columns_to_compare) | join(',') %}


  {% set a_query %}
    select
      {{ include_columns_csv }}
    from {{ a_relation }}
  {% endset %}

  {% set b_query %}
    select
      {{ include_columns_csv }}
    from {{ b_relation }}
  {% endset %}

  {% set audit_query = audit_helper.compare_queries(
    a_query=a_query,
    b_query=b_query,
    summarize=false
  ) %}

  with audit_query as (
    {{ audit_query }}
  ),

  calculate_exp as (
    select
      *,
      count(*) over (partition by {{ primary_keys_csv }}) as __count_by_pk
    from audit_query
  ),

  keep_conflicts as (
    select *
    from calculate_exp
    where
      __count_by_pk > 1
  ),

  {% if summarize -%}

  compare_conflicts as (
    select
      {{ primary_keys_csv }},

      {% for column in columns_to_compare -%}

      max(case when in_a = 1 then {{ column }} end) as {{ column ~ '__a' }},
      max(case when in_b = 1 then {{ column }} end) as {{ column ~ '__b' }}

      {{- "," if not loop.last else "" }}

      {% endfor %}

    from keep_conflicts
    group by {{ primary_keys_csv }}
  ),

  final_x as (
    {% set columns_to_compare_pivoted -%}

      {% for column in columns_to_compare -%}

      {{ column ~ '__a' }},
      {{ column ~ '__b' }}

      {{- "," if not loop.last else "" }}

      {% endfor %}

    {%- endset %}

    select
      {{ columns_to_compare_pivoted }},
      count(*) as count_conflicts
    from compare_conflicts
    group by
      {{ columns_to_compare_pivoted }}

  )

  {% else -%}

  final_x as (
    select *
    from keep_conflicts
  )

  {%- endif %}


  select 
    {%- if limit %}
    top {{ limit }}
    {%- endif %} *
  from final_x

{% endmacro %}