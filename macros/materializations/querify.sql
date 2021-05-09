{# This macro ensures a model includes a non-commented query #}
{# Otherwise, it adds a dummy query in order to avoid this empty model error: #}
  {# Compilation Error in macro statement (macros/core.sql) #}
  {# cannot unpack non-iterable NoneType object #}
{# array.append() is used to circumvent block scoping in jinja #}
{%- macro querify(sql) -%}
  {%- set hasQuery = [false] -%}
  {%- set blockComment = [false] -%}
  {# Look for lines that are not commented #}
  {%- for line in sql.split('\n') -%}
    {%- if hasQuery[-1] is false -%}
      {# Detect block comments that start at the beginning of the line #}
      {# Otherwise, we assume that a valid query is present before the block #}
      {%- if (line|trim)[0:2] == '/*' -%}
        {%- do blockComment.append(true) -%}
      {%- endif -%}

      {# If the block comment ends before the end of the line, we assume there is a valid query afterwards #}
      {%- if blockComment[-1] and '*/' in line and (line|trim)[-2:] != '*/' -%}
        {%- do blockComment.append(false) -%}
      {%- endif -%}

      {# If not a block comment, empty line, or line comment, there should be a query #}
      {%- if blockComment[-1] is false
          and (line|trim)
          and not (line|trim)[0:2] == '--' -%}
        {%- do hasQuery.append(true) -%}
      {%- endif -%}

      {# But the block comments can end anywhere on the line (although usually at the end) #}
      {%- if blockComment[-1] and '*/' in line -%}
        {%- do blockComment.append(false) -%}
      {%- endif -%}
    {%- endif -%}
  {%- endfor -%}

  {# If no uncommented query was found, add a dummy query #}
  {{ return(
      sql if hasQuery[-1]
      else sql + '\nSELECT 1; -- A query is required to prevent DBT from crashing'
  ) }}
{%- endmacro -%}
