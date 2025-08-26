{% macro sqlserver__type_string() %}
    {{ return("nvarchar(max)") }}
{% endmacro %}