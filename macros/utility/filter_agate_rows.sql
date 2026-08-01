{% macro filter_agate_rows(result, row_filter) %}
  {{ return(adapter.dispatch('filter_agate_rows', 'audit_helper_ext')(result=result, row_filter=row_filter)) }}
{% endmacro %}

{# dbt-fusion's Agate does not implement Table.where(). Filter rows by invoking the per-row #}
{# filter macro ourselves and return a view mimicking the Agate interface the consumers read: #}
{# .column_names, .rows, and .columns.items() where each column exposes .values(). Each column #}
{# is an ordered index->value dict so its .values() yields the column values in row order. #}
{% macro default__filter_agate_rows(result, row_filter) %}
  {% set matched_rows = [] %}
  {% for row in result.rows %}
    {% if row_filter(row) %}
      {% do matched_rows.append(row) %}
    {% endif %}
  {% endfor %}

  {% set columns = {} %}
  {% for column_name in result.column_names %}
    {% set column_values = {} %}
    {% for row in matched_rows %}
      {% do column_values.update({loop.index0 | string: row[column_name]}) %}
    {% endfor %}
    {% do columns.update({column_name: column_values}) %}
  {% endfor %}

  {{ return(namespace(column_names=result.column_names, rows=matched_rows, columns=columns)) }}
{% endmacro %}
