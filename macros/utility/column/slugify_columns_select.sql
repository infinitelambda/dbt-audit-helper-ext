{% macro slugify_columns_select(relation) %}
  {{ return(adapter.dispatch('slugify_columns_select', 'audit_helper_ext')(
      relation=relation
  )) }}
{% endmacro %}

{% macro default__slugify_columns_select(relation) %}

  {% if not execute %}
    {{ return('select * from ' ~ relation) }}
  {% endif %}

  {% set column_names = adapter.get_columns_in_relation(relation) | map(attribute='name') | list %}

  {% if not column_names %}
    {% do exceptions.raise_compiler_error(
        "slugify_columns_select: no columns found on " ~ relation
        ~ " — check that the relation exists and has been built"
    ) %}
  {% endif %}

  {# `taken` tracks every alias already claimed, so a generated suffix can never collide with a
     slug that a later column produces on its own. Without it, a relation holding both
     `Total Amount` and a literal `total_amount_2` would emit the alias `total_amount_2` twice —
     and most warehouses accept the duplicate silently, which is a quiet way to lose a column. #}
  {% set taken = [] %}
  {% set projections = [] %}

  {% for column_name in column_names %}
    {% set slug = audit_helper_ext.slugify_column_name(column_name) %}

    {# Deduplicate in column order: the first winner keeps the bare slug, later collisions
       get _2, _3, ... appended, skipping any suffix that is itself already claimed #}
    {% set candidate = namespace(alias=slug, suffix=1) %}
    {% for _ in range(column_names | length) if candidate.alias in taken %}
      {% set candidate.suffix = candidate.suffix + 1 %}
      {% set candidate.alias = slug ~ '_' ~ candidate.suffix %}
    {% endfor %}

    {% set alias = candidate.alias %}
    {% do taken.append(alias) %}
    {% do projections.append(adapter.quote(column_name) ~ ' as ' ~ alias) %}
  {% endfor %}

  {{ return('select\n    ' ~ projections | join(',\n    ') ~ '\nfrom ' ~ relation) }}

{% endmacro %}
