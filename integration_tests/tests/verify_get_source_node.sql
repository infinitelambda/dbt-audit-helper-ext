{{ config(tags=['package_scoped_lookup']) }}
-- Verifies package-scoped source resolution via get_source_node. Each assertion emits a
-- row only when it fails, so an empty result set means every lookup resolved correctly.
--
-- Fixtures: source `pkg_shared_source.pkg_dup_table` is declared in both the root project
-- (audit_helper_ext_test) and test_packages/pkg_a to exercise disambiguation.

{% if execute %}

{% set src_ambiguous = audit_helper_ext.get_source_node('pkg_shared_source', 'pkg_dup_table') %}
{% set src_pkg_a = audit_helper_ext.get_source_node('pkg_shared_source', 'pkg_dup_table', package_name='pkg_a') %}
{% set src_root = audit_helper_ext.get_source_node('pkg_shared_source', 'pkg_dup_table', package_name='audit_helper_ext_test') %}
{% set src_missing = audit_helper_ext.get_source_node('pkg_shared_source', 'pkg_dup_table', package_name='does_not_exist') %}

{% set assertions = [
    ('duplicate source resolves to a real node without a hint', src_ambiguous.name, 'pkg_dup_table'),
    ('duplicate source disambiguates to pkg_a', src_pkg_a.package_name, 'pkg_a'),
    ('duplicate source disambiguates to the root project', src_root.package_name, 'audit_helper_ext_test'),
    ('source not found in an unknown package', src_missing.name, 'undefined'),
] %}
{% else %}
{% set assertions = [] %}
{% endif %}

{{ audit_helper_ext_test.emit_assertion_failures(assertions) }}
