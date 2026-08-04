{% macro generate_sample_query(
    old_relation,
    dbt_relation,
    primary_keys,
    exclude_columns=[],
    audit_results=none,
    a_filter=none,
    b_filter=none,
    column_specs=none
) %}
  {{ return(adapter.dispatch('generate_sample_query', 'audit_helper_ext')(
      old_relation=old_relation,
      dbt_relation=dbt_relation,
      primary_keys=primary_keys,
      exclude_columns=exclude_columns,
      audit_results=audit_results,
      a_filter=a_filter,
      b_filter=b_filter,
      column_specs=column_specs
  )) }}
{% endmacro %}


{% macro default__generate_sample_query(
    old_relation,
    dbt_relation,
    primary_keys,
    exclude_columns,
    audit_results,
    a_filter=none,
    b_filter=none,
    column_specs=none
) %}

  {% if not audit_results or audit_results | length == 0 %}
    {{ return(none) }}
  {% endif %}

  {% set first_row = audit_results[0] %}

  {# Build WHERE conditions #}
  {% set pk_conditions = ["1=1"] %}
  {% for pk_col in primary_keys %}
    {% set pk_col = audit_helper_ext.get_actual_column_name(first_row, pk_col) %}
    {% set pk_value = first_row[pk_col] %}
    {% if pk_value is number %}
      {% do pk_conditions.append(pk_col ~ " = " ~ pk_value) %}
    {% elif pk_value is sameas true or pk_value is sameas false %}
      {% do pk_conditions.append(pk_col ~ " = " ~ pk_value) %}
    {% else %}
      {% set escaped_value = pk_value | string | replace("'", "''") %}
      {% do pk_conditions.append(pk_col ~ " = '" ~ escaped_value ~ "'") %}
    {% endif %}
  {% endfor %}

  {% set where_clause = pk_conditions | join('\n      and ') %}

  {# Get columns filter out excluded columns #}
  {% set column_names = [] %}
  {% for col_name in audit_results.column_names %}
    {% if (col_name | upper) not in (exclude_columns | map('upper') | list)
        and (col_name | upper) not in ['IN_A', 'IN_B'] %}
      {% do column_names.append(col_name) %}
    {% endif %}
  {% endfor %}

  {# Project through the configured expressions so the suggestion reproduces the comparison. #}
  {% set select_by_name = {} %}
  {% for spec in (column_specs or []) %}
    {% do select_by_name.update({spec.name | upper: spec.select}) %}
  {% endfor %}

  {% set projected = [] %}
  {% for col_name in column_names %}
    {% do projected.append(select_by_name.get(col_name | upper, adapter.quote(col_name))) %}
  {% endfor %}

  {% set column_list = projected | join(', ') %}

  {# Mirror the comparison's filters so the suggestion matches what was compared. #}
  {% set a_where = where_clause ~ ('\n      and ' ~ a_filter if a_filter else '') %}
  {% set b_where = where_clause ~ ('\n      and ' ~ b_filter if b_filter else '') %}

  {# Generate the investigation query #}
  {% set query %}
    select 'In A' as _source, {{ column_list }}
    from {{ old_relation }}
    where {{ a_where }}

    union all

    select 'In B' as _source, {{ column_list }}
    from {{ dbt_relation }}
    where {{ b_where }}

    order by _source;
  {%- endset %}

  {{ return(query) }}

{% endmacro %}
