{#
  Postgres only defines two-argument round() for numeric, so a double precision
  column raises "function round(double precision, integer) does not exist".
  Cast there; every other adapter in the suite rounds floats natively.

  Plain macro (not dispatched) to match the sibling expression fixtures, which
  branch on target.type for adapter-specific spelling.
#}
{% macro roundable_numeric(column_name) %}
  {%- if target.type in ('postgres', 'redshift') -%}
    {{ return('cast(' ~ column_name ~ ' as numeric)') }}
  {%- else -%}
    {{ return(column_name) }}
  {%- endif -%}
{% endmacro %}
