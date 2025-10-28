{% macro print_table(result, max_rows=100, max_columns=10, max_column_width=none) %}
  {{ return(adapter.dispatch('print_table', 'audit_helper_ext')(
    result=result,
    max_rows=max_rows,
    max_columns=max_columns,
    max_column_width=max_column_width
  )) }}
{% endmacro %}


{% macro default__print_table(result, max_rows, max_columns, max_column_width) %}
  {% if execute %}
    {# For security reason, we might want NOT to print data table in log #}
    {% set print_enabled = true %}
    {% set is_dbt_cloud = env_var('DBT_CLOUD_PROJECT_ID', '') != '' %}
    {% if is_dbt_cloud and var('audit_helper__print_table_enabled') %}
      {% set print_enabled = var('audit_helper__print_table_enabled') in ["yes", "true", "1"] %}
    {% endif %}

    {# Get column information #}
    {% set all_col_items = result.columns.items() | list %}
    {% set col_items = all_col_items[:max_columns] if max_columns else all_col_items %}

    {# Extract column names and data #}
    {% set col_names = [] %}
    {% set col_data = [] %}
    {% for col_name, col in col_items %}
      {% do col_names.append(col_name) %}
      {% set all_values = [] %}
      {% for val in col.values() %}
        {% do all_values.append(val) %}
      {% endfor %}
      {% set limited_values = all_values[:max_rows] if max_rows else all_values %}
      {% do col_data.append(limited_values) %}
    {% endfor %}

    {# Calculate column widths #}
    {% set col_widths = [] %}
    {% for i in range(col_names | length) %}
      {% set col_name = col_names[i] %}
      {% set widths = [col_name | length] %}
      {% for value in col_data[i] %}
        {% set value_str = value | string %}
        {% set value_len = value_str | length %}
        {# Apply max_column_width limit if specified #}
        {% if max_column_width is not none and value_len > max_column_width %}
          {% set value_len = max_column_width %}
        {% endif %}
        {% do widths.append(value_len) %}
      {% endfor %}
      {% set max_width = widths | max %}
      {% do col_widths.append(max_width) %}
    {% endfor %}

    {# Build separator line #}
    {% set separator_parts = [] %}
    {% for width in col_widths %}
      {% do separator_parts.append('-' * (width + 2)) %}
    {% endfor %}
    {% set separator = '+' ~ separator_parts | join('+') ~ '+' %}

    {# Build header row #}
    {% set header_parts = [] %}
    {% for col_name, width in zip(col_names, col_widths) %}
      {% set col_len = col_name | length %}
      {% set padding = ' ' * (width - col_len) %}
      {% do header_parts.append(' ' ~ col_name ~ padding ~ ' ') %}
    {% endfor %}
    {% set header = '|' ~ header_parts | join('|') ~ '|' %}

    {# Log table header #}
    {% do audit_helper_ext.log_data(separator) %}
    {% do audit_helper_ext.log_data(header) %}
    {% do audit_helper_ext.log_data(separator) %}

    {# If printing is disabled, log message and skip rows #}
    {% if not print_enabled or is_dbt_cloud %}
      {% set reason = 'disabled by dbt variable' if not print_enabled else 'disabled on dbt Cloud' %}
      {% do audit_helper_ext.log_data('✋  Table data printing is ' ~ reason) %}
    {% else %}
      {# Log rows #}
      {% set num_rows = col_data[0] | length if col_data else 0 %}
      {% for row_idx in range(num_rows) %}
        {% set row_parts = [] %}
        {% for col_idx in range(col_names | length) %}
          {% set width = col_widths[col_idx] %}
          {% set value = col_data[col_idx][row_idx] | string %}
          {% if max_column_width is not none and value | length > max_column_width %}
            {% set value = value[:(max_column_width-3)] ~ "..." %}
          {% endif %}
          {% set value_len = value | length %}
          {% set padding = ' ' * (width - value_len) %}
          {% do row_parts.append(' ' ~ value ~ padding ~ ' ') %}
        {% endfor %}
        {% set row_str = '|' ~ row_parts | join('|') ~ '|' %}
        {% do audit_helper_ext.log_data(row_str) %}
      {% endfor %}

      {% do audit_helper_ext.log_data(separator) %}

      {# Log summary if rows were truncated #}
      {% if max_rows and col_data and col_data[0] | length < (all_col_items | first | last).values() | length %}
        {% set first_col = all_col_items | first | last %}
        {% set total_rows = 0 %}
        {% for val in first_col.values() %}
          {% set total_rows = total_rows + 1 %}
        {% endfor %}
        {% do audit_helper_ext.log_data('... (' ~ (total_rows - max_rows) ~ ' more rows)') %}
      {% endif %}
      {% if max_columns and all_col_items | length > max_columns %}
        {% do audit_helper_ext.log_data('... (' ~ (all_col_items | length - max_columns) ~ ' more columns)') %}
      {% endif %}
    {% endif %}
  {% endif %}
{% endmacro %}
