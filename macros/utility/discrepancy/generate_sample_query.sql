{% macro generate_sample_query(
    old_relation,
    dbt_relation,
    primary_keys,
    exclude_columns=[],
    audit_results=none
) %}
  {{ return(adapter.dispatch('generate_sample_query', 'audit_helper_ext')(
      old_relation=old_relation,
      dbt_relation=dbt_relation,
      primary_keys=primary_keys,
      exclude_columns=exclude_columns,
      audit_results=audit_results
  )) }}
{% endmacro %}


{% macro default__generate_sample_query(
    old_relation,
    dbt_relation,
    primary_keys,
    exclude_columns,
    audit_results
) %}

  {% if not audit_results or audit_results | length == 0 %}
    {{ return(none) }}
  {% endif %}

  {% set first_row = audit_results[0] %}

  {# Build WHERE conditions #}
  {% set pk_conditions = ["1=1"] %}
  {% for pk_col in primary_keys %}
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

  {% set column_list = column_names | join(', ') %}

  {# Generate the investigation query #}
  {% set query %}
    select 'In A' as _source, {{ column_list }}
    from {{ old_relation }}
    where {{ where_clause }}

    union all

    select 'In B' as _source, {{ column_list }}
    from {{ dbt_relation }}
    where {{ where_clause }}

    order by _source;
  {%- endset %}

  {{ return(query) }}

{% endmacro %}
