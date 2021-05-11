{# This DBT override macro runs second, after the database & before the alias #}
{% macro generate_schema_name(custom_schema_name, node) -%}
  {%- if custom_schema_name is none -%}
    {# Get the schema name from the FQN #}
    {{ node.fqn[2] }}
  {%- else -%}
    {{ custom_schema_name | trim }}
  {%- endif -%}
{%- endmacro %}
