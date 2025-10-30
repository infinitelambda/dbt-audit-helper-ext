{% macro format_lineage(lineage_paths) %}
  {{ return(adapter.dispatch('format_lineage', 'audit_helper_ext')(lineage_paths=lineage_paths)) }}
{% endmacro %}


{% macro default__format_lineage(lineage_paths) %}
  {% if not lineage_paths or lineage_paths | length == 0 %}
    {{ return("No upstream dependencies found.") }}
  {% endif %}

  {% set output_lines = ["\n"] %}

  {# Collect all unique tables #}
  {% set all_tables = namespace(list=[]) %}
  {% for path in lineage_paths %}
    {% for node in path %}
      {% set full_path = [
          node.database, 
          node.schema, 
          node.identifier or node.alias or node.name
        ] | join(".") %}
      {% if full_path not in all_tables.list %}
        {% do all_tables.list.append(full_path) %}
      {% endif %}
    {% endfor %}
  {% endfor %}

  {# Display table list #}
  {% for table in all_tables.list %}
    {% do output_lines.append("  • " ~ table) %}
  {% endfor %}

  {{ return(output_lines | join("\n")) }}
{% endmacro %}
