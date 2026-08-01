{{ config(tags=['package_scoped_lookup']) }}
-- Verifies package-scoped lineage resolution via get_upstream_lineage. Each assertion
-- emits a row only when it fails, so an empty result set means every lookup resolved
-- correctly. The macro returns a list of upstream paths (each a list of node dicts).
--
-- Fixtures: `pkg_dup_model` exists in both the root project (audit_helper_ext_test) and
-- test_packages/pkg_a to exercise disambiguation.

{% if execute %}

{% set lineage_pkg_a = audit_helper_ext.get_upstream_lineage('pkg_dup_model', package_name='pkg_a') %}
{% set lineage_root = audit_helper_ext.get_upstream_lineage('pkg_dup_model', package_name='audit_helper_ext_test') %}
{% set lineage_ambiguous = audit_helper_ext.get_upstream_lineage('pkg_dup_model') %}
{% set lineage_missing = audit_helper_ext.get_upstream_lineage('pkg_dup_model', package_name='does_not_exist') %}

{% set assertions = [
    ('lineage resolves the pkg_a duplicate', lineage_pkg_a | length > 0, true),
    ('lineage root node is pkg_dup_model', lineage_pkg_a[0][0].name if lineage_pkg_a | length > 0 else none, 'pkg_dup_model'),
    ('lineage resolves the root duplicate', lineage_root[0][0].name if lineage_root | length > 0 else none, 'pkg_dup_model'),
    ('lineage resolves an ambiguous duplicate without a hint', lineage_ambiguous | length > 0, true),
    ('lineage returns empty for an unknown package', lineage_missing | length, 0),
] %}
{% else %}
{% set assertions = [] %}
{% endif %}

{{ audit_helper_ext_test.emit_assertion_failures(assertions) }}
