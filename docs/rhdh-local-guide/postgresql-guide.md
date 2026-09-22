## Using a PostgreSQL database

RHDH Local uses PostgreSQL by default. The `db` service in [`compose.yaml`](https://github.com/redhat-developer/rhdh-local/blob/HEAD/compose.yaml) starts with:

=== "Podman"
    ```bash
    podman compose up -d
    ```

=== "Docker"
    ```bash
    docker compose up -d
    ```

Default [`app-config.yaml`](https://github.com/redhat-developer/rhdh-local/blob/HEAD/configs/app-config/app-config.yaml) uses `client: pg` and the `POSTGRES_*` values from `default.env`. 
You do not need a separate db overlay or a `WITH_POSTGRES` flag.

The examples below use `podman` and `podman compose`. If you use Docker, replace `podman` with `docker` (for example `docker login`, `docker compose`, `docker exec`).

> **NOTE**: The default image is [`quay.io/fedora/postgresql-18:latest`](https://quay.io/repository/fedora/postgresql-18). No registry login is required for a normal start. To use the commercially supported image, set `POSTGRES_IMAGE=registry.redhat.io/rhel10/postgresql-18:latest` in `.env` and [log in to `registry.redhat.io`](https://access.redhat.com/RegistryAuthentication#getting-a-red-hat-login-2) (`podman login registry.redhat.io`).

`default.env` already supplies the `POSTGRES_*` defaults via `env_file` (`POSTGRES_HOST=db`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`). Put only the values you want to change in your project `.env` (or export them). You do not need to copy every `POSTGRES_*` key. Pin the image with `POSTGRES_IMAGE` in `.env`.

Data is stored under `/var/lib/pgsql/data` in the `db` container (Compose anonymous volume). RHDH does not support database downgrades, so this volume is ephemeral.

- `podman compose stop` / `start` (or `restart`) keep the volume and catalog data.
- `podman compose down` then `podman compose up` creates a new empty volume. Use this when switching RHDH versions.
- `podman compose down --volumes` also deletes other Compose volumes (plugins, RAG, and so on).

> **Warning:** If you already have a persisted `/var/lib/pgsql/data` volume from an **older major** image, do **not** only bump `POSTGRES_IMAGE` (or the default image major). Follow [Upgrading PostgreSQL](#upgrading-postgresql) first so the volume is upgraded safely.

### Optional database overrides

Put database overrides in [`app-config.local.yaml`](https://github.com/redhat-developer/rhdh-local/blob/HEAD/configs/app-config/app-config.local.example.yaml) - overriding the default `client: pg` settings in [`app-config.yaml`](https://github.com/redhat-developer/rhdh-local/blob/HEAD/configs/app-config/app-config.yaml).
Below switches back to in-memory SQLite:

```yaml
backend:
  database:
    client: better-sqlite3
    connection: ':memory:'
```

If you need `pluginDivisionMode: schema` (one database, one schema per plugin — useful when the DB user cannot create multiple databases), add this to `app-config.local.yaml`. 
Deep merge keeps `client` and `connection` from the default [`app-config.yaml`](https://github.com/redhat-developer/rhdh-local/blob/HEAD/configs/app-config/app-config.yaml):

```yaml
backend:
  database:
    pluginDivisionMode: schema
```

## Upgrading PostgreSQL

To move the Postgres `db` service to a newer major version of the [sclorg PostgreSQL container](https://github.com/sclorg/postgresql-container), use the image’s built-in upgrade by setting `POSTGRESQL_UPGRADE=copy` for a single boot. That runs `pg_upgrade` inside the container and keeps the existing data volume; do not delete the Postgres data directory for this path.

The new image must support upgrading from your current major version (its `POSTGRESQL_PREV_VERSION` must match). See [Upgrading Database](https://github.com/sclorg/postgresql-container/blob/master/src/root/usr/share/container-scripts/postgresql/README.md) for `POSTGRESQL_UPGRADE=copy` vs `hardlink` (prefer `copy`).

> **Warning:** Back up the Postgres data volume (or take a host-level snapshot) before upgrading. Stop RHDH first so nothing writes to the database during the upgrade. The `copy` mode needs roughly as much free space as the current data directory.

Do not edit tracked [`compose.yaml`](https://github.com/redhat-developer/rhdh-local/blob/HEAD/compose.yaml) for the upgrade. Put temporary settings in gitignored `compose.override.yaml` instead. Pulling a newer default image major in `compose.yaml` is not a silent safe upgrade for an existing data volume — follow the steps below when the image major changes.

Plain `podman compose` / `docker compose` loads `compose.yaml` and `compose.override.yaml` automatically. If you pass extra `-f` overlays (for example [`compose-with-corporate-proxy.yaml`](corporate-proxy-setup-sim.md)), include `compose.override.yaml` on those commands as well.

The `psql` examples below use `POSTGRES_USER` from the container environment (`default.env` / `.env`). `sh -c` is required so the variable expands inside the container.

### Steps

1. Note your current Postgres version and image:

   ```sh
   podman exec db sh -c 'psql -U "${POSTGRES_USER:-postgres}" -c "SHOW server_version;"'
   podman inspect db --format '{{.Config.Image}}'
   ```

2. Stop RHDH so it does not write during the upgrade:

   ```sh
   podman compose stop rhdh
   ```

3. Point at the target major image and enable a one-time upgrade boot:

   - In your project `.env`, set `POSTGRES_IMAGE` to the newer image (for example `registry.redhat.io/rhel10/postgresql-18:latest`).
   - Copy the temporary override example:

   ```sh
   cp compose.postgres-upgrade.override.example.yaml compose.override.yaml
   ```

   That override only adds `POSTGRESQL_UPGRADE=copy` for this boot.

4. Recreate and start the `db` **container** so it boots the new image against the **existing** data volume (do **not** run `podman compose down --volumes` / `docker compose down --volumes`):

   ```sh
   podman compose up -d db
   ```

   Wait until `db` is healthy (`podman compose ps`), then confirm the new major version:

   ```sh
   podman exec db sh -c 'psql -U "${POSTGRES_USER:-postgres}" -c "SHOW server_version;"'
   ```

   The first start can take a minute while `pg_upgrade` runs. Your databases and rows stay on the mounted volume under `/var/lib/pgsql/data`; only the container/image changes.

5. Refresh collation versions if PostgreSQL warns about a collation mismatch (common when the image base OS changes). Run for `postgres`, `template1`, and each user database:

   ```sh
   podman exec db sh -c 'psql -U "${POSTGRES_USER:-postgres}" -c "ALTER DATABASE postgres REFRESH COLLATION VERSION;"'
   podman exec db sh -c 'psql -U "${POSTGRES_USER:-postgres}" -c "ALTER DATABASE template1 REFRESH COLLATION VERSION;"'
   # Repeat for each application database, for example:
   # podman exec db sh -c 'psql -U "${POSTGRES_USER:-postgres}" -c "ALTER DATABASE \"<dbname>\" REFRESH COLLATION VERSION;"'
   ```

6. Remove `POSTGRESQL_UPGRADE` by deleting `compose.override.yaml` (or stripping that env from it), then force-recreate only the `db` **container** so the updated environment takes effect:

   ```sh
   rm compose.override.yaml
   podman compose up -d --force-recreate db
   ```

   Keep `POSTGRES_IMAGE` in `.env` if you want to pin the major; otherwise the default from `compose.yaml` applies.

   `--force-recreate` replaces the container; it does **not** create a fresh database or wipe `/var/lib/pgsql/data`. Compose keeps the existing volume as long as you do not pass `--volumes` / `-v` to `podman compose down` / `docker compose down` or otherwise remove that volume.

7. Start RHDH again and verify the instance:

   ```sh
   podman compose up -d rhdh
   ```

   Open [http://localhost:7007](http://localhost:7007) and confirm your catalog (or other persisted data) is still present.

### What not to do

- Do not edit `compose.yaml` for upgrades (use `.env` + temporary `compose.override.yaml`).
- Do not delete the Postgres data volume as part of this upgrade (`podman compose down --volumes` / `docker compose down --volumes`, `volume rm`, pruning volumes, etc.).
- Do not treat `--force-recreate db` as a data reset — it only recreates the container.
- Do not leave `POSTGRESQL_UPGRADE` set after the upgrade succeeds.
- Prefer `copy` over `hardlink` unless you understand the [sclorg hardlink trade-offs](https://github.com/sclorg/postgresql-container/blob/master/src/root/usr/share/container-scripts/postgresql/README.md).
- Do not wipe Lightspeed/RAG or other non-Postgres compose volumes when recycling the stack.
- Do not skip a major version unless the target image documents that hop (`POSTGRESQL_PREV_VERSION`).
