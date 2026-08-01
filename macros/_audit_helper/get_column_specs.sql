{% macro get_column_specs(a_relation, b_relation, exclude_columns=[], package_name=none) %}
  {{ return(adapter.dispatch('get_column_specs', 'audit_helper_ext')(
      a_relation=a_relation,
      b_relation=b_relation,
      exclude_columns=exclude_columns,
      package_name=package_name
  )) }}
{% endmacro %}

{% macro default__get_column_specs(a_relation, b_relation, exclude_columns, package_name) %}
  {# Get column names from the relation #}
  {% set column_names = dbt_utils.get_filtered_columns_in_relation(from=a_relation, except=exclude_columns) %}

  {# Get column specs with custom expressions applied (if configured) #}
  {% set column_specs = audit_helper_ext.get_columns_with_expressions(
      relation=a_relation,
      model_name=b_relation.identifier,
      column_names=column_names,
      package_name=package_name
  ) %}

  {{ return(column_specs) }}
{% endmacro %}
