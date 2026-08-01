{{ config(materialized='ephemeral') }}
select 1 as id, 'audit_helper_ext_test' as owner_package
