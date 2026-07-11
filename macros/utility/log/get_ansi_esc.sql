{% macro get_ansi_esc() %}
  {{ return(adapter.dispatch('get_ansi_esc', 'audit_helper_ext')()) }}
{% endmacro %}

{% macro default__get_ansi_esc() %}
  {#-
    Returns the ANSI escape byte (ESC, 0x1B) as a real control character.

    Why a literal byte and not "\x1b" or ""?
    dbt Fusion's Jinja engine (minijinja) does NOT support \x hex or \u{..}
    unicode string escapes and rejects them with "bad string escape". Both
    dbt-core and Fusion, however, pass a raw ESC byte through untouched, so a
    literal control character is the only portable way to emit ANSI colors.

    The single quotes below contain one invisible ESC character. Keep this the
    ONLY place that byte lives so edits elsewhere can't accidentally corrupt it.
  -#}
  {{ return('') }}
{% endmacro %}
