# Test locally with Red Hat Developer Hub (RHDH)

Welcome to RHDH Local - the fastest and simplest way for platform engineers to test their software catalogs, techdocs, plugins, templates, homepage customizations, configurations and more with RHDH!

RHDH Local is ideal for trying out the basic features of RHDH (like Software Catalogs or TechDocs) without the need for a Kubernetes cluster. RHDH Local is also great for testing dynamic plugins and their configuration settings. To use RHDH Local, all you really need is basic knowledge of Podman (or Docker), a PC, and a web browser. You can run it on your laptop, desktop, or on your homelab. Better still, when you're done working it's easy to remove.

>**RHDH Local is NOT a substitute for Red Hat Developer Hub**. Do not attempt to use RHDH Local as a production system. RHDH Local is designed to help individual developers test various RHDH features. It's not designed to scale and it's not suitable for use by teams (there is no RBAC for example). 

NOTE: There is no official, commercial support for RHDH Local. Use RHDH Local at your own risk. With all that being said, we think it's incredibly useful and any contributions you might have that could improve RHDH Local are welcome!

## What you'll need before you get started

To use RHDH Local you'll need a few things:

1. A PC based on an x86_64 (amd64) or arm64 (aarch64) architecture
1. An installation of Podman (or Docker) (with adequate resources available)
1. An internet connection (for downloading container images, plugins, etc.)
1. (Optional) The `git` command line client for cloning this repository (or you can download and extract the zip from GitHub)
1. (Optional) A GitHub account (if you want to integrate GitHub features into RHDH)
1. (Optional) The node `npx` tool (if you intend to use GitHub authentication in RHDH)
1. (Optional) A [Red Hat account](https://access.redhat.com/RegistryAuthentication#getting-a-red-hat-login-2) (if you want to use a PostgreSQL database or the commercially supported official RHDH images)

## Getting Started With RHDH Local

1. Clone this repository to a location on your PC

   ```sh
   git clone https://github.com/redhat-developer/rhdh-local.git
   ```

1. Move to the `rhdh-local` folder.

   ```sh
   cd rhdh-local
   ```

1. (Optional) You can create a local `.env` file and override any of the default variables defined in the [`default.env`](./default.env) file provided. You can also add additional variables.
   In most cases, when you don't need GitHub Auth or testing different releases, you can skip this step, and it should work.

1. (Optional) Create local configuration overrides.

   RHDH Local supports user-specific configuration overrides using a structured `configs/` directory. You do not need to modify default files. However, if you want to customize your setup:

   - Add your app config overrides to: `configs/app-config/app-config.local.yaml`
      > You can use the included `.example.yaml` files to get started quickly:
      >
      > ```sh
      > cp configs/app-config/app-config.local.example.yaml configs/app-config/app-config.local.yaml
      > cp configs/dynamic-plugins/dynamic-plugins.override.example.yaml configs/dynamic-plugins/dynamic-plugins.override.yaml
      > ```

   - Add your plugin config overrides to:
     `configs/dynamic-plugins/dynamic-plugins.override.yaml`
     > The override file must start with:
     > ```yaml
     > includes:
     >   - dynamic-plugins.default.yaml
     > ```
     > This ensures the base plugin list is preserved and extended, rather than replaced.

   - Add any extra files (like GitHub credentials) to: `configs/extra-files/`

   If present, these files will be automatically loaded by the system on startup.

   If you need features that fetch files from GitHub you should configure `integrations.github`.
   The recommended way is to use GitHub Apps. You can find hints on how to configure it in [github-app-credentials.example.yaml](configs/github-app-credentials.example.yaml) or a more detailed instruction in [Backstage documentation](https://backstage.io/docs/integrations/github/github-apps).

2. Start RHDH Local.
   This repository should work with either `docker compose` using Docker Engine or `podman-compose` using Podman. When using Podman there are some exceptions. Check [Known Issues when using Podman Compose](#known-issues-when-using-podman-compose) for more info.

   ```sh
   podman-compose up -d
   ```

   If you prefer `docker compose` you can just replace `podman-compose` with `docker compose`

   ```sh
   docker compose up -d
   ```

3. Open [http://localhost:7007](http://localhost:7007) in your browser to access RHDH.

## Changing your configuration

When you change `app-config.local.yaml` you must restart the `rhdh` container to load RHDH your updated configuration.

```sh
podman-compose stop rhdh && podman-compose start rhdh
```

When you change `dynamic-plugins.yaml` you need to re-run the `install-dynamic-plugins` container and then restart RHDH instance.

```sh
podman-compose run install-dynamic-plugins
podman-compose stop rhdh && podman-compose start rhdh
```

## Loading dynamic plugins from a local directory

During boot, the `install-dynamic-plugins` container reads the contents of the plugin configuration file and activates, configures, or downloads any plugins listed. RHDH Local supports two ways of specifying dynamic plugin configuration:

1. Default path: `configs/dynamic-plugins/dynamic-plugins.yaml`

1. User override path: `configs/dynamic-plugins/dynamic-plugins.override.yaml` or `configs/dynamic-plugins.yaml` If present, this file will automatically override the default and be used by the `install-dynamic-plugins` container. `configs/dynamic-plugins/dynamic-plugins.override.yaml` takes precedence over `configs/dynamic-plugins.yaml`.

In addition, the `local-plugins` directory is mounted into the `install-dynamic-plugins` container at `/opt/app-root/src/local-plugins`. Any plugins placed there can be activated/configured the same way (without downloading).

To load dynamic plugins from your local machine:

1. Copy the dynamic plugin binary file into the `local-plugins` directory.
2. Make sure permissions allow the container to read the files (e.g. `chmod -R 777 local-plugins` for quick testing).
3. Configure your plugin in one of the supported config files:
    - Prefer `configs/dynamic-plugins/dynamic-plugins.override.yaml` for local user overrides.
    - If no override file is present, `configs/dynamic-plugins/dynamic-plugins.yaml` will be used.
4. See [Changing Your Configuration](#changing-your-configuration) for more on updating and reloading configs.

## Optional: Customize `.npmrc` for plugin installation

If you're installing dynamic plugins from a private registry or using a proxy, you can customize your own `.npmrc` file. A `.npmrc.example` file is provided in the `configs/` directory as a template.

1. Copy the example file to create your own `.npmrc`:

    ```sh
    cp configs/.npmrc.example configs/.npmrc
    ```

2. Open the newly created `.npmrc` file and add your configuration, such as private registry URLs or authentication tokens:

    ```sh
    //registry.npmjs.org/:_authToken=YOUR_TOKEN
    registry=https://your-private-registry.example.com/
    ```

When present, this `.npmrc` file will be automatically mounted into the `install-dynamic-plugins` container, and the `NPM_CONFIG_USERCONFIG` environment variable will be set to point to it.

If you don't create a `.npmrc`, plugin installation will still work using the default public registry settings.

> For more information on configuring `.npmrc`, see the [npm configuration docs](https://docs.npmjs.com/cli/v10/configuring-npm/npmrc).

## Changing the container image

By default, the [compose.yaml](./compose.yaml) points to the latest, stable **community build of RHDH** at [quay.io/rhdh-community/rhdh:1.6](https://quay.io/rhdh-community/rhdh:1.6), which includes both `linux-amd64` and `linux-arm64` images.

Community builds are [built with Github Actions](https://github.com/redhat-developer/rhdh/blob/main/.github/workflows/next-build-image.yaml#L46-L47) and [docker buildx](https://github.com/redhat-developer/rhdh/blob/main/.github/actions/docker-build/action.yaml).

Commercially supported Red Hat images are built with [Konflux](https://konflux-ci.dev/) and [buildah](https://buildah.io/) using a [RHEL 9 container image](https://github.com/redhat-developer/rhdh/blob/main/.rhdh/docker/Dockerfile). Additionally, [Hermeto](https://github.com/hermetoproject/hermeto/tree/main) is used to pre-fetch dependencies for a more declarative, reproduceable and predictable build experience. CI builds are pushed to quay.io, then later official releases are pushed to registry.redhat.io. 

You can switch between these different images by changing the container image name held by the `RHDH_IMAGE` environment variable in your `.env` file, or editing the [compose.yaml](./compose.yaml) file.

### Using nightly community builds

Looking for the bleeding edge? To use the most recent nightly community build of RHDH from the main branch, set the variable as follows.

```sh
RHDH_IMAGE=quay.io/rhdh-community/rhdh:next
```

### Using unsupported pre-release CI builds

Continuous Integration (CI) builds on from [quay.io/rhdh/rhdh-hub-rhel9](https://quay.io/rhdh/rhdh-hub-rhel9), while unsupported, provide early access to commercially supported builds and bug fixes.

NOTE: Only `linux-amd64` builds are currently commercially supported.

To use the most recent nightly CI build of RHDH 1.y (for example, 1.7), set the variable as follows.

```sh
RHDH_IMAGE=quay.io/rhdh/rhdh-hub-rhel9:1.7
```

### Using commercially supported official images

To use the [official release of RHDH](https://catalog.redhat.com/software/containers/rhdh/rhdh-hub-rhel9/645bd4c15c00598369c31aba?gs&q=developer%20hub) 1.y (for example, 1.6), which includes only `linux-amd64`, set the variable as follows. 

NOTE: Using official builds also [requires authentication with the registry](https://access.redhat.com/articles/RegistryAuthentication). See also the section below `Configuring registry credentials` to make this authentication pervasive.

```sh
RHDH_IMAGE=registry.redhat.io/rhdh/rhdh-hub-rhel9:1.6
```

#### Using image digests

If you prefer to use digests to floating tags, [browse for the tag you want to use](https://catalog.redhat.com/software/containers/rhdh/rhdh-hub-rhel9/645bd4c15c00598369c31aba/history), and click though to find the digest of the image you want to use. For example, from the [Get this image](https://catalog.redhat.com/software/containers/rhdh/rhdh-hub-rhel9/645bd4c15c00598369c31aba?image=68360c12177ad86df31947d8&architecture=amd64&container-tabs=gti) tab for 1.6.1 provides this image:

```sh
RHDH_IMAGE=registry.redhat.io/rhdh/rhdh-hub-rhel9@sha256:8729c21dc4b6e1339ed29bf87e2e2054c8802f401a029ebb1f397408f3656664
```

## Testing RHDH in a simulated corporate proxy setup

If you want to test how RHDH would behave if deployed in a corporate proxy environment,
you can run `podman-compose` or `docker-compose` by merging both the [`compose.yaml`](./compose.yaml) and [`compose-with-corporate-proxy.yaml`](./compose-with-corporate-proxy.yaml) files.

Example with `podman-compose` (note that the order of the YAML files is important):

```sh
podman-compose \
   -f compose.yaml \
   -f compose-with-corporate-proxy.yaml \
   up -d
```

The [`compose-with-corporate-proxy.yaml`](compose-with-corporate-proxy.yaml) file includes a specific [Squid](https://www.squid-cache.org/)-based proxy container as well as an isolated network, such that:

1. only the proxy container has access to the outside
2. all containers part of the internal network need to communicate through the proxy container to reach the outside. This can be done with the `HTTP(S)_PROXY` and `NO_PROXY` environment variables.

## Cleanup

To reset RHDH Local you can use the following command. This will clean up any container attached volumes, but configuration changes made to your `rhdh-local` YAML files will remain.

```sh
podman-compose down --volumes
```

To reset everything in the cloned `rhdh-local` repository, including any configuration changes you've made to your YAML files try:

```sh
git reset --hard
```

To remove the RHDH containers completely from your system (after you have run a `compose down`):

```sh
docker system prune --volumes # For rhdh-local running on docker
podman system prune --volumes # For rhdh-local running on podman
```

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

2. Uncomment the `db` service block in [compose.yaml](compose.yaml) file

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

3. Uncomment the `db` section in the `depends_on` section of `rhdh` service in [compose.yaml](compose.yaml)

   ```yaml
   depends_on:
     install-dynamic-plugins:
       condition: service_completed_successfully
     db:
       condition: service_healthy
   ```

4. Comment out the SQLite in-memory configuration in [`app-config.local.yaml`](configs/app-config.local.yaml)

   ```yaml
   # database:
   #   client: better-sqlite3
   #   connection: ':memory:'
   ```

## Developers: Using VSCode to debug backend plugins

You can use RHDH-local with a debugger to to debug your backend plugins in VSCode. The Node.js debugger is exposed on port 9229. Here is how:

1. Start RHDH-local

   ```sh
   # in rhdh-local directory
   podman-compose up -d
   ```

2. Open your plugin source code in VSCode
3. Export plugin an RHDH "dynamic" plugin

   ```sh
   # in plugin source code directory
   npx @janus-idp/cli@latest package export-dynamic-plugin
   ```

4. Copy exported derived plugin package to `dynamic-plugins-root` directory in the `rhdh` container.

   ```sh
   # in plugin source code directory
   podman cp dist-dynamic rhdh:/opt/app-root/src/dynamic-plugins-root/<your-plugin-name>
   ```

5. If your plugin requires configuration, add it to the `app-config.local.yaml` file in your cloned `rhdh-local` directory.

6. Restart the `rhdh` container

   ```sh
   # in rhdh-local directory
   podman-compose stop rhdh
   podman-compose start rhdh
   ```

7. Configure VSCode debugger to attach to the `rhdh` container.

   `.vscode/launch.json` example:

   ```json
   {
      "version": "0.2.0",
      "configurations": [
         {
            "name": "Attach to Process",
            "type": "node",
            "request": "attach",
            "port": 9229,
            "localRoot": "${workspaceFolder}",
            "remoteRoot": "/opt/app-root/src/dynamic-plugins-root/<your-plugin-name>",
         }
      ]
   }
   ```

8. Now, you can start debugging your plugin using VSCode debugger.
   Source mapping should work, and you should be able to put breakpoints to your TypeScript files.
   If it doesn't work, most likely you need to adjust `localRoot` and `remoteRoot` paths in `launch.json`.

   Every time you make changes to your plugin source code, you need to repeat steps 3-6.

## Frontend plugin development

Follow these steps to preview and test development changes for your frontend plugin in RHDH local:

1. Ensure a clean start by running the following command:

   ```shell
   podman compose down -v
   ```

2. Create the dynamic plugins root directory where you will place your exported plugins:

   ```shell
   mkdir dynamic-plugins-root
   ```

3. Inside your plugin directory, run the following command to export your plugin:

   ```shell
   npx @janus-idp/cli@latest package export-dynamic-plugin --dev --dynamic-plugins-root <path_to_dynamic-plugins-root_in_rhdh-local_folder>
   ```

4. Add the plugin configuration for the plugin you want to develop into the `app-config.local.yaml` file under the `dynamicPlugins` key. Avoid adding this configuration to the `dynamic-plugins.override.yaml` file. You can add additional plugins into the `dynamic-plugins.override.yaml` file, but the one you are developing should be in the `app-config.local.yaml` file.

5. Use the `compose-dynamic-plugins-root.yaml` override file to start RHDH local:

   ```shell
   podman compose -f compose.yaml -f compose-dynamic-plugins-root.yaml up
   ```

6. Verify that your plugin appears in RHDH.

7. To apply code changes to your plugin, rerun the command in step 3 and refresh your browser. No need to restart any containers.

## Configuring registry credentials

Place your registry credentials in `./configs/extra-files`, then reference the auth file in your `.env`:

```bash
REGISTRY_AUTH_FILE=/opt/app-root/src/configs/extra-files/auth.json
```

This allows RHDH-local to pull OCI artifacts from registries like registry.redhat.io without authentication errors.

## Contributing and reporting issues

To report issues against this repository, please use [JIRA](https://issues.redhat.com/browse/RHIDP) with Component: **RHDH Local**

To browse the existing issues, you can use this [Query](https://issues.redhat.com/issues/?filter=-4&jql=project%20%3D%20%22Red%20Hat%20Internal%20Developer%20Platform%22%20%20AND%20component%20%3D%20%22RHDH%20Local%22%20AND%20resolution%20%3D%20Unresolved%20ORDER%20BY%20status%2C%20priority%2C%20updated%20%20%20%20DESC).

Contributions are welcome!

## License

```txt
Copyright Red Hat

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
