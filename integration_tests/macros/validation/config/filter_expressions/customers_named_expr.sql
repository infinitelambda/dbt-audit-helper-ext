{# Source (A) side on `customers`: every customer carries a name, so this bound exercises the #}
{# A-side filter path end-to-end without desyncing counts against the dbt side. #}
{% macro customers_named_expr() %}
  name is not null
{% endmacro %}
