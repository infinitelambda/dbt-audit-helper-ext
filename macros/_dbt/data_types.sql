{% macro sqlserver__type_string() %}
    {{ return("nvarchar(4000)") }}
{% endmacro %}