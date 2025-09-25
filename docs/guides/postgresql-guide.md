# PostgreSQL Guide

## Using a PostgreSQL database

By default, in-memory db is used.
If you want to use PostgreSQL with RHDH, here are the steps:

> **NOTE**: You must have [Red Hat Login](https://access.redhat.com/RegistryAuthentication#getting-a-red-hat-login-2) to use `postgresql` image.

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
     image: "registry.redhat.io/rhel8/postgresql-16:latest"
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
