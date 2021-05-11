{# This DBT override macro runs third/last, after the database & schema #}
{% macro generate_alias_name(custom_alias_name=none, node=none) -%}
  {%- if custom_alias_name is none -%}
    {# If there is a namespace, only keep the last part #}
    {{ node.identifier.split('~')[-1] }}
  {%- else -%}
    {{ custom_alias_name | trim }}
  {%- endif -%}
{%- endmacro %}
