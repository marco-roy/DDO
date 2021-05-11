{# This structure macro runs first, before the schema & alias #}
{% macro generate_database_name(custom_database_name=none, node=none) -%}
  {%- if custom_database_name is none -%}
    {%- if node.fqn|length < 4 -%}
      {{ exceptions.raise_compiler_error(
        "Invalid project structure for model '" ~ node.fqn[1:]|join('/') ~ ".sql'.\n"
        ~ "Expected DDO project structure is 'database/schema/model.sql'."
      ) }}
    {%- else -%}
      {# Get the database name from the FQN (prefixed with the environment) #}
      {{ env_prefix() }}{{ node.fqn[1] }}
    {%- endif -%}
  {%- else -%}
    {{ custom_database_name | trim }}
  {%- endif -%}
{%- endmacro %}
