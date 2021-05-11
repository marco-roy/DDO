# DDO
A DBT package to perform DataOps & administrative CI/CD on your data warehouse.

DDO stands for Dbt DataOps and aims to extend DevOps/DataOps philosophy & practices to all aspects of data warehouse management. Whereas DBT handles data transformation (the "T" in "ELT") by materializing models into tables and views, DDO handles all other aspects of data warehouse management by running plain SQL models directly.

***If it can be done using SQL, you can do it with DDO.***

DDO can create & manage any data warehouse object, from tables & views to databases, schemas, users, roles & warehouses, as well as functions/UDFs, procedures, pipes, streams, tasks, etc.

DDO can also be used to work with data directly. Since it can run any SQL, it can be used to run statements like `INSERT`, `UPDATE`, `DELETE`, `MERGE`, etc. If you want to run (and monitor) some SQL commands on a schedule in your data warehouse, you can do it by running a DDO project in DBT Cloud.

#### Features
- Run any SQL command.
- Adapt SQL commands to your environments (`dev` vs `prod`).
- Generate object FQNs based on your project's directory structure & environment.
- Namespacing for your models.

#### Coming soon:
- Automated model aliases & references for databases and schemas.
- Automated model aliases & references for users, roles, warehouses, and other top-level objects.
- Automated model aliases & references for object access roles.
- And more to come!

## Installation
#### ⚠️ Warning ⚠️
While it's possible to run DDO models alongside regular DBT models, it's recommended for beginners to start with a completely separate project, as DDO can alter the way DBT functions.

Namely, DDO will:
- Introduce a new way to materialize models.
- Introduce macros to handle environmental variations.
- Override how database names, schema names, and aliases are generated.
- Introduce the ability to namespace models using the tilde character (`~`).

#### Download
DDO is not available on [DBT Hub](https://hub.getdbt.com/) yet, so you have to get it directly from GitHub. In your packages.yml file, add the following lines, and replace `x.y.z` with a specific version:

```
packages:
  ...

  - git: https://github.com/marco-roy/DDO.git
    revision: x.y.z
```

Running [`dbt deps`](https://docs.getdbt.com/reference/commands/deps/) will then take care of the download & installation.

#### Configuration
It's recommended to enable each DDO feature by loading the macros directly into your DBT project. This allows different sets of features to be enabled for different types of projects.

To do so, simply add the desired macro directories under `macro-paths` in your `dbt_project.yml`:

```
macro-paths:
  - dbt_modules/DDO/macros/materializations
  - dbt_modules/DDO/macros/env
  - dbt_modules/DDO/macros/structure
  - dbt_modules/DDO/macros/namespacing
```

## Features
#### Any SQL
```
macro-paths:
  - dbt_modules/DDO/macros/materializations
```

This feature adds the `plain` materialization. It's the most significant change introduced by DDO, and it's what tells DBT to run models as plain SQL scripts, rather than data models to materialize.

For example, a simple model to create a stream could look like this:
```
-- Create a stream on my_table
CREATE OR REPLACE STREAM my_db.my_schema.my_stream
  ON TABLE my_db.my_schema.my_table;
```

If you want all models in your project use the `plain` materialization, simply configure it at the root of your project with `plain` as the `materialized` configuration. You can also configure it in the same way for specific subdirectories:

```
models:
  my_project:
    +materialized: plain
```

Otherwise, you can configure it for specific models using the inline model configuration block:

```
{{ config(
    materialized="plain"
) }}
```

#### Environments
```
macro-paths:
  - dbt_modules/DDO/macros/env
```

This feature enables models to adapt to the environment they are being executed in (ex: `dev` or `prod`). This is critical in order to test changes before deploying to production, and is a foundational pillar of DevOps/DataOps methodologies.

The environment is simply the name of the target configured in your `profiles.yml`:

```
my_project:
  target: dev
  outputs:
    dev:
      ...
```

This feature adds two macros: `get_env()` & `env_prefix()`.

- `env_prefix()` returns the name of the environment with an added separator (underscore by default, but you can specify something else), ***except for the `prod` or `production` environments***. This is useful to prefix resources with their environment when running outside of production (usually, no prefix is used in production).

- `get_env()` simply returns the name of the environment. This is useful in cases where all environments require a prefix, including production. In this case, the separator can be entered manually in the model.

For example, our simple stream model from earlier could now be adapted to instantiate differently in each environment:

```
-- Create a stream on my_table in {{ get_env() }}
CREATE OR REPLACE STREAM {{ env_prefix() }}my_db.my_schema.my_stream
  ON TABLE {{ env_prefix() }}my_db.my_schema.my_table;
```

#### Structure
```
macro-paths:
  - dbt_modules/DDO/macros/env
  - dbt_modules/DDO/macros/structure
```

This feature overrides how DBT generates the database name and schema name for each model based on the directory structure and the environment. DDO projects with this feature enabled require all models to be placed in a directory structure corresponding to their database and schema. Additionally, all database names will be prefixed with the environment (using `env_prefix()`), unless a custom database name is used.

For example, our simple stream model from earlier should be placed in the following structure:

```
my_db/
  my_schema/
    my_stream.sql
    my_table.sql
```

The model could in turn be greatly simplified and take full advantage of DBT's `ref()` function:

```
-- Create a stream on my_table in {{ get_env() }}
CREATE OR REPLACE STREAM {{ this }}
  ON TABLE {{ ref('my_table') }};
```

- `{{ this }}` will automatically expand to `[env_]my_db.my_schema.my_stream`
- `{{ ref('my_table') }}` will automatically expand to `[env_]my_db.my_schema.my_table`

#### Namespacing
```
macro-paths:
  - dbt_modules/DDO/macros/namespacing
```

This feature introduces the ability to namespace models in order to prevent DBT from crashing due to multiple models with the same name. In DDO projects, different types of models can very often have the same name. For example, the name of a department (like `marketing` or `finance`) can be used to name a database, a schema, a role, and/or a warehouse.

One way to deal with this is to come up with a different name variations for each model, but this can become very tedious, very quickly.

Until DBT adds namespacing ([see issue #1269](https://github.com/fishtown-analytics/dbt/issues/1269)), DDO offers a workaround: simply namespace your models with a prefix in the filename, using the tilde (`~`) as a separator. DDO will simply ignore those prefixes, and load your model names without them. A common technique is to prefix administrative objects with the object type, such as `roles/role~my_role.sql`, `users/user~my_user.sql`, or `warehouses/wh~my_warehouse.sql`.

For databases & schemas, you can use the database & schema name as a prefix instead:

```
databases/
  db1/
    db1.sql
    schema1/
      db1~schema1.sql
    schema2/
      db1~schema2.sql
  db2/
    db2.sql
    schema1/
      db2~schema1.sql
    schema2/
      db2~schema2.sql
```

## Q&A
#### Some of my models have the same name, and DBT produces an error.
This is a very common issue with DDO, and that's exactly why [namespacing](#namespacing) was added.
