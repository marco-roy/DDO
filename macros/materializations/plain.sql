{# This materialization sends the compiled SQL from the model directly for execution #}
{%- materialization plain, default -%}
  {%- set target_relation = api.Relation.create(
    identifier=model['alias'],
    schema=schema,
    database=database,
    type=None
  ) -%}

  {{ run_hooks(pre_hooks, inside_transaction=False) }}
  -- `BEGIN` happens here:
  {{ run_hooks(pre_hooks, inside_transaction=True) }}

  {% call statement('main') -%}
    {{ querify(sql) }}
  {%- endcall %}

  {{ run_hooks(post_hooks, inside_transaction=True) }}
  {{ adapter.commit() }}
  {{ run_hooks(post_hooks, inside_transaction=False) }}

  {{ return({'relations': [target_relation]}) }}
{%- endmaterialization -%}
