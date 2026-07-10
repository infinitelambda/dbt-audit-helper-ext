{% macro assert_source_filter_equal(actual, expected, what) %}
    {% set actual_norm = (actual | string).split() | join(' ') if actual is not none else none %}
    {% set expected_norm = (expected | string).split() | join(' ') if expected is not none else none %}
    {% if actual_norm != expected_norm %}
        {% do exceptions.raise_compiler_error(
            "❌ " ~ what ~ ": expected '" ~ expected_norm ~ "' but got '" ~ actual_norm ~ "'."
        ) %}
    {% endif %}
    {{ log("✅ " ~ what ~ " == '" ~ expected_norm ~ "'", info=true) }}
{% endmacro %}


{% macro test__resolve_source_filter() %}

    {% if not execute %}{{ return(none) }}{% endif %}

    {{ assert_source_filter_equal(
        audit_helper_ext.resolve_source_filter(none), none,
        "none disables the filter") }}
    {{ assert_source_filter_equal(
        audit_helper_ext.resolve_source_filter('source_upper_bound_expr'),
        "(age <= 40)",
        "macro name resolves and parenthesises") }}

    {{ log("🎉 resolve_source_filter tests passed", info=true) }}

{% endmacro %}
