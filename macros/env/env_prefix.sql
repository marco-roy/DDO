{%- macro env_prefix(separator = '_') -%}
  {{ return(
    (target.name + separator) if target.name not in ('prod', 'production')
  ) }}
{%- endmacro -%}
