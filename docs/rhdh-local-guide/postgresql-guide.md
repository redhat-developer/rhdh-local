## Using a PostgreSQL database

By default, in-memory db is used.
If you want to use PostgreSQL with RHDH, here are the steps:

> **NOTE**: You must have [Red Hat Login](https://access.redhat.com/RegistryAuthentication#getting-a-red-hat-login-2) to use the [rhel10/postgresql-18](https://catalog.redhat.com/en/software/containers/rhel10/postgresql-18/6942a60aab9edd836017e3d0) image from `registry.redhat.io`.

1. Login to container registry with *Red Hat Login* credentials to use `postgresql` image

   ```sh
   podman login registry.redhat.io
   ```

   If you prefer `docker` you can just replace `podman` with `docker`

   ```sh
   docker login registry.redhat.io
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

4. Comment out the SQLite in-memory configuration in [`app-config.yaml`](https://github.com/redhat-developer/rhdh-local/blob/main/configs/app-config/app-config.yaml) (or override it from `app-config.local.yaml`)

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

   If you need **`pluginDivisionMode: schema`** (one database, one schema per plugin — useful when the DB user cannot create multiple databases), use this **`backend.database`** block in `app-config.local.yaml` **instead** of the snippet above:

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

## Upgrading PostgreSQL 16 to 18

If you already run the optional Postgres service on **`registry.redhat.io/rhel8/postgresql-16`** and want to move to **`registry.redhat.io/rhel10/postgresql-18`**, use the image’s built-in major upgrade (`pg_upgrade`) by setting `POSTGRESQL_UPGRADE=copy` for a single boot. This keeps the existing data volume; do not delete the Postgres data directory for this path.

Background and details (do not restate the full procedures here):

- [sclorg postgresql-container — Upgrading Database](https://github.com/sclorg/postgresql-container/blob/master/src/root/usr/share/container-scripts/postgresql/README.md) (`POSTGRESQL_UPGRADE=copy` or `hardlink`; prefer **`copy`**, and ensure enough free disk for a full data copy)
- [PostgreSQL — Upgrading a PostgreSQL Cluster](https://www.postgresql.org/docs/current/upgrading.html) (general major-upgrade background; rhdh-local uses the container `POSTGRESQL_UPGRADE` / `pg_upgrade` path, not a manual `pg_dumpall` flow)
- Images: [rhel8/postgresql-16](https://catalog.redhat.com/en/software/containers/rhel8/postgresql-16/657c148efd40a94aa696f28e) → [rhel10/postgresql-18](https://catalog.redhat.com/en/software/containers/rhel10/postgresql-18/6942a60aab9edd836017e3d0)

> **Warning:** Schedule downtime. Back up the Postgres data volume (or take a host-level snapshot) before upgrading. The `copy` mode needs roughly as much free space as the current data directory.

### Steps

1. Confirm you are on PostgreSQL 16 and note the version:

   ```sh
   podman exec db psql -U postgres -c "SHOW server_version;"
   ```

   Expect a `16.x` result. If you use `docker`, replace `podman` with `docker` in these commands.

2. Stop RHDH so it does not write during the upgrade:

   ```sh
   podman compose stop rhdh
   ```

3. In `compose.yaml`, change the `db` service image to PostgreSQL 18 and add `POSTGRESQL_UPGRADE=copy` for this boot only:

   ```yaml
   db:
     image: "registry.redhat.io/rhel10/postgresql-18:latest"
     # ...existing volumes, env_file, healthcheck...
     environment:
       - POSTGRESQL_ADMIN_PASSWORD=${POSTGRES_PASSWORD}
       - POSTGRESQL_UPGRADE=copy
   ```

4. Recreate and start the `db` service (keep the same data volume; do not run `compose down --volumes`):

   ```sh
   podman compose up -d db
   ```

   Wait until the container is healthy, then confirm the major version is 18:

   ```sh
   podman exec db psql -U postgres -c "SHOW server_version;"
   ```

5. After a successful upgrade, **remove** `POSTGRESQL_UPGRADE=copy` from `compose.yaml` so the upgrade does not run again on later restarts, then recreate `db`:

   ```yaml
   environment:
     - POSTGRESQL_ADMIN_PASSWORD=${POSTGRES_PASSWORD}
   ```

   ```sh
   podman compose up -d --force-recreate db
   ```

6. Refresh collation versions if PostgreSQL warns about a collation mismatch (common when moving from an older RHEL base to rhel10). Run for `postgres`, `template1`, and each user database:

   ```sh
   podman exec db psql -U postgres -c 'ALTER DATABASE postgres REFRESH COLLATION VERSION;'
   podman exec db psql -U postgres -c 'ALTER DATABASE template1 REFRESH COLLATION VERSION;'
   # Repeat for each application database, for example:
   # podman exec db psql -U postgres -c 'ALTER DATABASE "<dbname>" REFRESH COLLATION VERSION;'
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
