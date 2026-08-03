{% macro slugify_column_name(column_name) %}
  {{ return(adapter.dispatch('slugify_column_name', 'audit_helper_ext')(
      column_name=column_name
  )) }}
{% endmacro %}

{% macro default__slugify_column_name(column_name) %}

  {# Split camelCase / PascalCase boundaries before lowercasing, so `MixedCase` becomes
     `mixed_case` rather than `mixedcase`. Acronym runs are kept whole: the boundary is
     inserted before the *last* capital of a run only when a lowercase letter follows it,
     which turns `CustomerID` into `customer_id` and `HTTPStatus` into `http_status`. #}
  {% set chars = column_name | list %}
  {% set spaced = [] %}
  {% for char in chars %}
    {% set prev = chars[loop.index0 - 1] if not loop.first else none %}
    {% set next = chars[loop.index0 + 1] if not loop.last else none %}
    {% set is_upper = char is string and char.isupper() %}
    {% set prev_is_lower_or_digit = prev is not none and (prev.islower() or prev.isdigit()) %}
    {% set prev_is_upper = prev is not none and prev.isupper() %}
    {% set next_is_lower = next is not none and next.islower() %}
    {% if is_upper and (prev_is_lower_or_digit or (prev_is_upper and next_is_lower)) %}
      {% do spaced.append('_') %}
    {% endif %}
    {% do spaced.append(char) %}
  {% endfor %}

  {# Collapse every run of characters outside [a-z0-9] into a single underscore. Deliberately
     ASCII-only: Jinja's `isalnum()` accepts CJK and accented letters, which would then survive
     into an alias that still needs quoting on some warehouses — defeating the point. #}
  {% set safe_chars = 'abcdefghijklmnopqrstuvwxyz0123456789' %}
  {% set lowered = spaced | join('') | lower %}
  {% set cleaned = [] %}
  {% for char in lowered %}
    {% if char in safe_chars %}
      {% do cleaned.append(char) %}
    {% elif cleaned and cleaned[-1] != '_' %}
      {% do cleaned.append('_') %}
    {% endif %}
  {% endfor %}

  {% set slug = cleaned | join('') %}
  {% set slug = slug.rstrip('_') %}

  {% if not slug %}
    {% do exceptions.raise_compiler_error(
        "slugify_column_name: column name '" ~ column_name ~ "' contains no ASCII alphanumeric"
        ~ " characters, so it cannot be slugified. Alias it by hand instead."
    ) %}
  {% endif %}

  {# A leading digit is not a legal identifier start on most warehouses #}
  {% if slug[0].isdigit() %}
    {% set slug = '_' ~ slug %}
  {% endif %}

  {{ return(slug) }}

{% endmacro %}
