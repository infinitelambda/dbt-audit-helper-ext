{# Snowflake-only override of audit_helper.compare_relation_columns to surface #}
{# column-order, text length, numeric precision/scale, and nullability drift #}
{# in addition to data-type and presence diffs. #}

{% macro snowflake__compare_relation_columns(a_relation, b_relation) %}

with a_cols as (
    {{ audit_helper.get_columns_in_relation_sql(a_relation) }}
),

b_cols as (
    {{ audit_helper.get_columns_in_relation_sql(b_relation) }}
)

select
    coalesce(a_cols.column_name, b_cols.column_name) as column_name,
    a_cols.ordinal_position as a_ordinal_position,
    b_cols.ordinal_position as b_ordinal_position,
    a_cols.data_type as a_data_type,
    b_cols.data_type as b_data_type,
    a_cols.character_maximum_length as a_character_maximum_length,
    b_cols.character_maximum_length as b_character_maximum_length,
    a_cols.numeric_precision as a_numeric_precision,
    b_cols.numeric_precision as b_numeric_precision,
    a_cols.numeric_scale as a_numeric_scale,
    b_cols.numeric_scale as b_numeric_scale,
    a_cols.is_nullable as a_is_nullable,
    b_cols.is_nullable as b_is_nullable,
    coalesce(a_cols.ordinal_position = b_cols.ordinal_position, false) as has_ordinal_position_match,
    coalesce(a_cols.data_type = b_cols.data_type, false) as has_data_type_match,
    coalesce(a_cols.character_maximum_length is not distinct from b_cols.character_maximum_length, false) as has_character_maximum_length_match,
    coalesce(a_cols.numeric_precision is not distinct from b_cols.numeric_precision, false) as has_numeric_precision_match,
    coalesce(a_cols.numeric_scale is not distinct from b_cols.numeric_scale, false) as has_numeric_scale_match,
    coalesce(a_cols.is_nullable = b_cols.is_nullable, false) as has_is_nullable_match,
    a_cols.data_type is not null and b_cols.data_type is null as in_a_only,
    b_cols.data_type is not null and a_cols.data_type is null as in_b_only,
    b_cols.data_type is not null and a_cols.data_type is not null as in_both
from a_cols
full outer join b_cols using (column_name)
order by coalesce(a_cols.ordinal_position, b_cols.ordinal_position)

{% endmacro %}


{% macro snowflake__get_columns_in_relation_sql(relation) %}
  select
      ordinal_position,
      column_name,
      data_type,
      character_maximum_length,
      numeric_precision,
      numeric_scale,
      is_nullable
  from {{ relation.information_schema('columns') }}
  where table_name ilike '{{ relation.identifier }}'
    {% if relation.schema %}
    and table_schema ilike '{{ relation.schema }}'
    {% endif %}
    {% if relation.database %}
    and table_catalog ilike '{{ relation.database }}'
    {% endif %}
  order by ordinal_position
{% endmacro %}
