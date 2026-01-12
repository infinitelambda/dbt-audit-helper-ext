{% macro get_column_specs(a_relation, b_relation, exclude_columns=[]) %}
  {{ return(adapter.dispatch('get_column_specs', 'audit_helper')(a_relation, b_relation, exclude_columns)) }}
{% endmacro %}

{% macro default__get_column_specs(a_relation, b_relation, exclude_columns=[]) %}
  {# Get column names from the relation #}
  {% set column_names = dbt_utils.get_filtered_columns_in_relation(from=a_relation, except=exclude_columns) %}

  {# Get column specs with custom expressions applied (if configured) #}
  {% set column_specs = audit_helper_ext.get_columns_with_expressions(
      relation=a_relation,
      model_name=b_relation.identifier,
      column_names=column_names
  ) %}

  {{ return(column_specs) }}
{% endmacro %}
