{{ config(tags=['source_filter']) }}
-- Unit-tests resolve_relation_filter purely in Jinja (no warehouse data): each case resolves
-- a filter and is compared to its expected string. Returns one failing row per mismatch, so a
-- passing test yields zero rows. The 'a' cases exercise the var fallback and its precedence, so
-- run with --vars '{audit_helper__source_filter: source_upper_bound_expr}'.

{% set cases = [
    ('none disables the filter',
        audit_helper_ext.resolve_relation_filter(none), none),
    ('macro name resolves and parenthesises',
        audit_helper_ext.resolve_relation_filter('source_upper_bound_expr'), '(age <= 40)'),
    ("side 'a' falls back to the source_filter var",
        audit_helper_ext.resolve_relation_filter(none, side='a'), '(age <= 40)'),
    ("explicit ref wins over the var for side 'a'",
        audit_helper_ext.resolve_relation_filter('dbt_lower_bound_expr', side='a'), '(age >= 25)'),
] %}

{% set failures = [] %}
{% for what, actual, expected in cases %}
  {% set actual_norm = (actual | string).split() | join(' ') if actual is not none else 'NONE' %}
  {% set expected_norm = (expected | string).split() | join(' ') if expected is not none else 'NONE' %}
  {% if actual_norm != expected_norm %}
    {% do failures.append((what, actual_norm, expected_norm)) %}
  {% endif %}
{% endfor %}

{% if failures %}
{% for what, actual_norm, expected_norm in failures %}
select
    '{{ what | replace("'", "''") }}' as case_name,
    '{{ expected_norm | replace("'", "''") }}' as expected,
    '{{ actual_norm | replace("'", "''") }}' as actual
{{ 'union all' if not loop.last }}
{% endfor %}
{% else %}
-- all cases passed → no rows
select 'x' as case_name, 'x' as expected, 'x' as actual where 1 = 0
{% endif %}
