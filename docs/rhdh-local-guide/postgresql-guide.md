## Using a PostgreSQL database

By default, in-memory db is used.
If you want to use PostgreSQL with RHDH, here are the steps:

> **NOTE**: You must have [Red Hat Login](https://access.redhat.com/RegistryAuthentication#getting-a-red-hat-login-2) to use the PostgreSQL image from `registry.redhat.io` (for example [rhel10/postgresql-18](https://catalog.redhat.com/en/software/containers/rhel10/postgresql-18/6942a60aab9edd836017e3d0)).

The examples below use `podman` and `podman compose`. If you use Docker, replace `podman` with `docker` (for example `docker login`, `docker compose`, `docker exec`).

`POSTGRES_PASSWORD` is defined in `default.env`. Also set it in your project `.env` (for example `POSTGRES_PASSWORD=postgres`) so Compose can substitute `${POSTGRES_PASSWORD}` in `compose.yaml`.

1. Login to container registry with *Red Hat Login* credentials to use `postgresql` image

   ```sh
   podman login registry.redhat.io
   ```

2. Uncomment the `db` service block in [https://github.com/redhat-developer/rhdh-local/blob/main/compose.yaml](https://github.com/redhat-developer/rhdh-local/blob/main/compose.yaml) file

   ```yaml
   db:
     image: "registry.redhat.io/rhel10/postgresql-18:latest"
     volumes:
       - "/var/lib/pgsql/data"
     env_file:
       - path: "./default.env"
         required: true
       - path: "./.env"
         required: false
     environment:
       - POSTGRESQL_ADMIN_PASSWORD=${POSTGRES_PASSWORD}
     healthcheck:
       test: ["CMD", "pg_isready", "-U", "postgres"]
       interval: 5s
       timeout: 5s
       retries: 5
   ```

3. Uncomment the `db` section in the `depends_on` section of `rhdh` service in [https://github.com/redhat-developer/rhdh-local/blob/main/compose.yaml](https://github.com/redhat-developer/rhdh-local/blob/main/compose.yaml)

   ```yaml
   depends_on:
     install-dynamic-plugins:
       condition: service_completed_successfully
     db:
       condition: service_healthy
   ```

4. Comment out the SQLite in-memory configuration in [`app-config.local.yaml`](https://github.com/redhat-developer/rhdh-local/blob/main/configs/app-config/app-config.local.example.yaml)

   ```yaml
   # database:
   #   client: better-sqlite3
   #   connection: ':memory:'
   ```

5. Add Postgres configuration in [`app-config.local.yaml`](https://github.com/redhat-developer/rhdh-local/blob/main/configs/app-config/app-config.local.example.yaml)

   ```yaml
   database:
    client: pg
    connection:
      host: ${POSTGRES_HOST}
      port: ${POSTGRES_PORT}
      user: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}
   ```

   If you need `pluginDivisionMode: schema` (one database, one schema per plugin — useful when the DB user cannot create multiple databases), use this `backend.database` block in `app-config.local.yaml` instead of the snippet above:

   ```yaml
   backend:
     database:
       client: pg
       pluginDivisionMode: schema
       connection:
         host: ${POSTGRES_HOST}
         port: ${POSTGRES_PORT}
         user: ${POSTGRES_USER}
         password: ${POSTGRES_PASSWORD}
   ```

## Upgrading PostgreSQL

To move the optional Postgres service to a newer major version of the [sclorg PostgreSQL container](https://github.com/sclorg/postgresql-container), use the image’s built-in upgrade by setting `POSTGRESQL_UPGRADE=copy` for a single boot. That runs `pg_upgrade` inside the container and keeps the existing data volume; do not delete the Postgres data directory for this path.

The new image must support upgrading from your current major version (its `POSTGRESQL_PREV_VERSION` must match). See [Upgrading Database](https://github.com/sclorg/postgresql-container/blob/master/src/root/usr/share/container-scripts/postgresql/README.md) for `POSTGRESQL_UPGRADE=copy` vs `hardlink` (prefer `copy`).

> **Warning:** Schedule downtime. Back up the Postgres data volume (or take a host-level snapshot) before upgrading. The `copy` mode needs roughly as much free space as the current data directory.

### Steps

1. Note your current Postgres version and image:

   ```sh
   podman exec db psql -U postgres -c "SHOW server_version;"
   podman inspect db --format '{{.Config.Image}}'
   ```

2. Stop RHDH so it does not write during the upgrade:

   ```sh
   podman compose stop rhdh
   ```

3. In `compose.yaml`, set `db.image` to the newer Postgres image and add `POSTGRESQL_UPGRADE=copy` for this boot only:

   ```yaml
   db:
     image: "registry.redhat.io/<newer-postgresql-image>:latest"
     # ...existing volumes, env_file, healthcheck...
     environment:
       - POSTGRESQL_ADMIN_PASSWORD=${POSTGRES_PASSWORD}
       - POSTGRESQL_UPGRADE=copy
   ```

4. Recreate and start the `db` service (keep the same data volume; do not run `compose down --volumes`):

   ```sh
   podman compose up -d db
   ```

   Wait until `db` is healthy (`podman compose ps`), then confirm the new major version:

   ```sh
   podman exec db psql -U postgres -c "SHOW server_version;"
   ```

   The first start can take a minute while `pg_upgrade` runs.

5. Refresh collation versions if PostgreSQL warns about a collation mismatch (common when the image base OS changes). Run for `postgres`, `template1`, and each user database:

   ```sh
   podman exec db psql -U postgres -c 'ALTER DATABASE postgres REFRESH COLLATION VERSION;'
   podman exec db psql -U postgres -c 'ALTER DATABASE template1 REFRESH COLLATION VERSION;'
   # Repeat for each application database, for example:
   # podman exec db psql -U postgres -c 'ALTER DATABASE "<dbname>" REFRESH COLLATION VERSION;'
   ```

6. Remove `POSTGRESQL_UPGRADE=copy` from `compose.yaml`, then recreate `db` so the new env applies (data volume is kept):

   ```sh
   podman compose up -d --force-recreate db
   ```

7. Start RHDH again and verify the instance:

   ```sh
   podman compose up -d rhdh
   ```

   Open [http://localhost:7007](http://localhost:7007) and confirm your catalog (or other persisted data) is still present.

### What not to do

- Do not delete the Postgres data volume as part of this upgrade.
- Do not leave `POSTGRESQL_UPGRADE` set after the upgrade succeeds.
- Prefer `copy` over `hardlink` unless you understand the [sclorg hardlink trade-offs](https://github.com/sclorg/postgresql-container/blob/master/src/root/usr/share/container-scripts/postgresql/README.md).
- Do not wipe Lightspeed/RAG or other non-Postgres compose volumes when recycling the stack.
- Do not skip a major version unless the target image documents that hop (`POSTGRESQL_PREV_VERSION`).
