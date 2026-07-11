{{ config(tags=['package_scoped_lookup']) }}
-- Verifies package-scoped model resolution via get_model_node. Each assertion emits a
-- row only when it fails, so an empty result set means every lookup resolved correctly.
--
-- Fixtures: `pkg_unique_model` exists only in test_packages/pkg_a; `pkg_dup_model` exists
-- in both the root project (audit_helper_ext_test) and pkg_a to exercise disambiguation.

{% if execute %}

{% set unique_node = audit_helper_ext.get_model_node('pkg_unique_model') %}
{% set unique_scoped = audit_helper_ext.get_model_node('pkg_unique_model', package_name='pkg_a') %}
{% set unique_wrong = audit_helper_ext.get_model_node('pkg_unique_model', package_name='audit_helper_ext_test') %}
{% set dup_node = audit_helper_ext.get_model_node('pkg_dup_model') %}
{% set dup_pkg_a = audit_helper_ext.get_model_node('pkg_dup_model', package_name='pkg_a') %}
{% set dup_root = audit_helper_ext.get_model_node('pkg_dup_model', package_name='audit_helper_ext_test') %}

{% set assertions = [
    ('unique model resolves by name', unique_node.name, 'pkg_unique_model'),
    ('unique model resolves to pkg_a', unique_node.package_name, 'pkg_a'),
    ('unique model resolves with explicit package_name', unique_scoped.package_name, 'pkg_a'),
    ('unique model not found in the wrong package', unique_wrong.name, 'undefined'),
    ('duplicate model resolves to a real node without a hint', dup_node.name, 'pkg_dup_model'),
    ('duplicate model disambiguates to pkg_a', dup_pkg_a.package_name, 'pkg_a'),
    ('duplicate model disambiguates to the root project', dup_root.package_name, 'audit_helper_ext_test'),
] %}
{% else %}
{% set assertions = [] %}
{% endif %}

{{ audit_helper_ext_test.emit_assertion_failures(assertions) }}
