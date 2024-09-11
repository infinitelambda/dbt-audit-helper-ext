{% macro get_upstream_row_count(dbt_identifier) %}
  {{ return(adapter.dispatch('get_upstream_row_count', 'audit_helper_ext')(dbt_identifier=dbt_identifier)) }}
{% endmacro %}

{% macro default__get_upstream_row_count(dbt_identifier) %}

  {% if execute %}
      {% set dbt_node = graph.nodes.values() | selectattr("name", "equalto", dbt_identifier) | first %}
      {% set dbt_depends_on_nodes = dbt_node.get('depends_on', {}).get('nodes', []) %}

      {% set count_query %}
        {% for depends_on_node in dbt_depends_on_nodes %}
          {% set name = (
              graph.nodes.values()
              | selectattr("unique_id", "equalto", depends_on_node)
              | first) ["name"]
          %}
          select '{{ name }}' as model_name, count(*) as row_count
          from {{ ref(name) }}

          {% if not loop.last -%} union all {% endif %}
        {% endfor %}
      {% endset %}

      {% set audit_results = audit_helper_ext.run_audit_query(count_query) %}

      {{ audit_helper_ext.log_validation_result(
          type='upstream_row_count',
          result=audit_results,
          dbt_identifier=dbt_identifier,
          dbt_relation=ref(dbt_identifier)
      ) }}

    {% endif %}

{% endmacro %}
