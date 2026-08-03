{# Override at v0.14 #}

{%- macro sqlserver___count_num_rows_in_status() -%}
    dense_rank() over (partition by dbt_audit_row_status order by dbt_audit_surrogate_key, dbt_audit_pk_row_num)
    + dense_rank() over (partition by dbt_audit_row_status order by dbt_audit_surrogate_key desc, dbt_audit_pk_row_num desc)
    - 1
{% endmacro %}
