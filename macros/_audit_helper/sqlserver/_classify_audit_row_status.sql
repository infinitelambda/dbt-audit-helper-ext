{# Override at v0.14 #}

{%- macro sqlserver___classify_audit_row_status() -%}
    case
        when max(dbt_audit_pk_row_num) over (partition by dbt_audit_surrogate_key) > 1 then 'nonunique_pk'
        when dbt_audit_in_a = 1 and dbt_audit_in_b = 1 then 'identical'
        when max(dbt_audit_in_a) over (partition by dbt_audit_surrogate_key, dbt_audit_pk_row_num) = 1
            and max(dbt_audit_in_b) over (partition by dbt_audit_surrogate_key, dbt_audit_pk_row_num) = 1
            then 'modified'
        when dbt_audit_in_a = 1 then 'removed'
        when dbt_audit_in_b = 1 then 'added'
    end
{% endmacro %}
