{% macro assert_equal(actual, expected, what) %}
    {% if actual != expected %}
        {% do exceptions.raise_compiler_error(
            "❌ " ~ what ~ ": expected '" ~ expected ~ "' but got '" ~ actual ~ "'."
        ) %}
    {% endif %}
    {{ log("✅ " ~ what ~ " == '" ~ expected ~ "'", info=true) }}
{% endmacro %}


{% macro test__package_scoped_lookup() %}

    {% if not execute %}{{ return(none) }}{% endif %}

    {% set unique_node = audit_helper_ext.get_model_node('pkg_unique_model') %}
    {{ assert_equal(
        unique_node.name, 'pkg_unique_model', "unique model resolves by name") }}
    {{ assert_equal(
        unique_node.package_name, 'pkg_a', "unique model resolves to pkg_a") }}

    {% set unique_scoped = audit_helper_ext.get_model_node('pkg_unique_model', package_name='pkg_a') %}
    {{ assert_equal(
        unique_scoped.package_name, 'pkg_a', "unique model resolves with explicit package_name") }}

    {% set unique_wrong = audit_helper_ext.get_model_node('pkg_unique_model', package_name='audit_helper_ext_test') %}
    {{ assert_equal(
        unique_wrong.name, 'undefined', "unique model not found in the wrong package") }}

    {% set dup_node = audit_helper_ext.get_model_node('pkg_dup_model') %}
    {{ assert_equal(
        dup_node.name, 'pkg_dup_model', "duplicate model resolves to a real node without a hint") }}

    {% set dup_pkg_a = audit_helper_ext.get_model_node('pkg_dup_model', package_name='pkg_a') %}
    {{ assert_equal(
        dup_pkg_a.package_name, 'pkg_a', "duplicate model disambiguates to pkg_a") }}

    {% set dup_root = audit_helper_ext.get_model_node('pkg_dup_model', package_name='audit_helper_ext_test') %}
    {{ assert_equal(
        dup_root.package_name, 'audit_helper_ext_test', "duplicate model disambiguates to the root project") }}

    {% set lineage_pkg_a = audit_helper_ext.get_upstream_lineage('pkg_dup_model', package_name='pkg_a') %}
    {{ assert_equal(
        lineage_pkg_a | length > 0, true, "lineage resolves the pkg_a duplicate") }}
    {{ assert_equal(
        lineage_pkg_a[0][0].name, 'pkg_dup_model', "lineage root node is pkg_dup_model") }}

    {% set lineage_root = audit_helper_ext.get_upstream_lineage('pkg_dup_model', package_name='audit_helper_ext_test') %}
    {{ assert_equal(
        lineage_root[0][0].name, 'pkg_dup_model', "lineage resolves the root duplicate") }}

    {% set lineage_ambiguous = audit_helper_ext.get_upstream_lineage('pkg_dup_model') %}
    {{ assert_equal(
        lineage_ambiguous | length > 0, true, "lineage resolves an ambiguous duplicate without a hint") }}

    {% set lineage_missing = audit_helper_ext.get_upstream_lineage('pkg_dup_model', package_name='does_not_exist') %}
    {{ assert_equal(
        lineage_missing | length, 0, "lineage returns empty for an unknown package") }}

    {% set src_ambiguous = audit_helper_ext.get_source_node('pkg_shared_source', 'pkg_dup_table') %}
    {{ assert_equal(
        src_ambiguous.name, 'pkg_dup_table', "duplicate source resolves to a real node without a hint") }}

    {% set src_pkg_a = audit_helper_ext.get_source_node('pkg_shared_source', 'pkg_dup_table', package_name='pkg_a') %}
    {{ assert_equal(
        src_pkg_a.package_name, 'pkg_a', "duplicate source disambiguates to pkg_a") }}

    {% set src_root = audit_helper_ext.get_source_node('pkg_shared_source', 'pkg_dup_table', package_name='audit_helper_ext_test') %}
    {{ assert_equal(
        src_root.package_name, 'audit_helper_ext_test', "duplicate source disambiguates to the root project") }}

    {% set src_missing = audit_helper_ext.get_source_node('pkg_shared_source', 'pkg_dup_table', package_name='does_not_exist') %}
    {{ assert_equal(
        src_missing.name, 'undefined', "source not found in an unknown package") }}

    {% set _, rel_pkg_a, _ = audit_helper_ext.get_relation('pkg_dup_model', package_name='pkg_a') %}
    {{ assert_equal(
        rel_pkg_a.identifier, 'pkg_dup_model', "get_relation resolves the pkg_a duplicate model") }}

    {{ log("🎉 test__package_scoped_lookup: all assertions passed.", info=true) }}

{% endmacro %}
