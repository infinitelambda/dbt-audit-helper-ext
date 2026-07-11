{#
    Test helper: given a list of (what, actual, expected) tuples, emit one row per
    failed assertion (actual != expected) and no rows when everything passes. Lets a
    singular dbt test express many equality checks while staying a standard "empty
    result set = pass" test.
#}
{% macro emit_assertion_failures(assertions) %}

    {% set failures = [] %}
    {% for what, actual, expected in assertions %}
        {% if actual != expected %}
            {% do failures.append((what, actual | string, expected | string)) %}
        {% endif %}
    {% endfor %}

    {% if failures | length == 0 or not execute %}
select
    cast(null as {{ dbt.type_string() }}) as assertion,
    cast(null as {{ dbt.type_string() }}) as actual,
    cast(null as {{ dbt.type_string() }}) as expected
where 1 = 0
    {% else %}
    {% for what, actual, expected in failures %}
select
    {{ dbt.string_literal(what) }} as assertion,
    {{ dbt.string_literal(actual) }} as actual,
    {{ dbt.string_literal(expected) }} as expected
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
    {% endif %}

{% endmacro %}
