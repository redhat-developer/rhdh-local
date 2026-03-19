# PostgreSQL: `pluginDivisionMode: schema` (single database)

By default, Backstage/RHDH uses **one PostgreSQL database per plugin** (`pluginDivisionMode: database`). That requires the DB user to have **`CREATEDB`**, which many managed databases and restricted local users do not allow.

With **`pluginDivisionMode: schema`**, every plugin uses the **same database** but its own **PostgreSQL schema** (named after the plugin id, e.g. `catalog`, `scaffolder`, `auth`). You only need privileges to create schemas in that database, not to create new databases.

RHDH Local is a convenient way to try this mode on your machine with Podman or Docker Compose.

## Prerequisites

- [Podman](https://podman.io/docs/installation) (recommended) or Docker with Compose
- Access to **`registry.redhat.io`** for the RHEL PostgreSQL image (same as the [PostgreSQL Guide](postgresql-guide.md)):

  ```sh
  podman login registry.redhat.io
  ```

## 1. Enable the `db` service in Compose

In the repository root, edit `compose.yaml`:

1. **Uncomment** the entire `db:` service block (PostgreSQL 16 image, healthcheck, `env_file`, etc.).
2. In the `rhdh` service, **uncomment** `db` under `depends_on` so RHDH starts after the database is healthy:

   ```yaml
   depends_on:
     install-dynamic-plugins:
       condition: service_completed_successfully
     db:
       condition: service_healthy
   ```

Connection settings come from `default.env` / `.env` (`POSTGRES_HOST=db`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`).

## 2. Point the backend at PostgreSQL (schema mode)

Comment out or remove the in-memory SQLite backend database from the merged config. The default lives in `configs/app-config/app-config.yaml` under `backend.database` (`better-sqlite3` / `:memory:`). Override it from **`configs/app-config/app-config.local.yaml`** (create it from the example if needed):

```sh
cp configs/app-config/app-config.local.example.yaml configs/app-config/app-config.local.yaml
```

Add a **`backend.database`** section for PostgreSQL with schema mode. You can copy from the committed example:

**[`configs/app-config/app-config.plugin-division-mode-schema.example.yaml`](https://github.com/redhat-developer/rhdh-local/blob/main/configs/app-config/app-config.plugin-division-mode-schema.example.yaml)**

Minimal shape:

```yaml
backend:
  database:
    client: pg
    pluginDivisionMode: schema
    ensureSchemaExists: true
    connection:
      host: ${POSTGRES_HOST}
      port: ${POSTGRES_PORT}
      user: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}
      database: ${POSTGRES_DB}
```

- **`ensureSchemaExists: true`** — required so Backstage creates each plugin schema on startup when it does not exist.
- **`connection.database`** — must be set (single shared database name, e.g. `postgres`).

## 3. Start the database, then align the postgres password

The RHEL PostgreSQL image may not use the same password as `POSTGRES_PASSWORD` in `default.env` until the data volume is aligned with your expectations. A reliable approach:

1. Start only the DB:

   ```sh
   podman compose up -d db
   ```

2. Wait until it is healthy:

   ```sh
   podman compose ps
   ```

3. Set the `postgres` user password to match `default.env` (example below uses `postgres`; adjust if you changed `POSTGRES_PASSWORD`):

   ```sh
   podman compose exec db psql -U postgres -c "ALTER USER postgres WITH PASSWORD 'postgres';"
   ```

## 4. Start RHDH

```sh
podman compose up -d
```

Watch logs if needed:

```sh
podman compose logs -f rhdh
```

Open [http://localhost:7007](http://localhost:7007) and exercise the app so plugins initialize their schemas.

## 5. Verify schema mode

**List schemas** — you should see many schemas named like plugin ids (`catalog`, `scaffolder`, `auth`, …), not only `public`:

```sh
podman compose exec db psql -U postgres -d postgres -c "\dn"
```

(Use `-d ${POSTGRES_DB}` if your database name is not `postgres`.)

**List databases** — you should **not** see separate databases per plugin (e.g. no `backstage_plugin_catalog`). Only the usual PostgreSQL templates plus your app database:

```sh
podman compose exec db psql -U postgres -d postgres -c "\l"
```

**Inspect tables in a plugin schema** — data is isolated per schema:

```sh
podman compose exec db psql -U postgres -d postgres -c "\dt catalog.*"
podman compose exec db psql -U postgres -d postgres -c "\dt scaffolder.*"
podman compose exec db psql -U postgres -d postgres -c "\dt auth.*"
```

## Returning to the default (SQLite)

1. Comment out the `db` service and `rhdh` → `depends_on` → `db` again in `compose.yaml`.
2. Remove or comment out the `backend.database` PostgreSQL block from `app-config.local.yaml` so the default `better-sqlite3` `:memory:` config from `app-config.yaml` applies.
3. `podman compose down --volumes` if you want a clean DB volume.

## See also

- [PostgreSQL Guide](postgresql-guide.md) — standard PostgreSQL setup without schema mode
- [Backstage: switching to PostgreSQL](https://backstage.io/docs/tutorials/switching-sqlite-postgres/) — `pluginDivisionMode` overview
