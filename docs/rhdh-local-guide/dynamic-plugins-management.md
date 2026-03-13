The dynamic plugin system in RHDH enables you to add, remove, enable, and disable plugins without rebuilding the container. This provides incredible flexibility for testing different plugin combinations and developing custom plugins locally.

## Managing Plugins from the UI

By default, RHDH Local enables the built-in **Extensions** feature that lets you browse, install, and configure plugins directly from the RHDH web interface, without any need to manually edit YAML files for basic plugin management.

!!! warning "Local Development Only"
    The UI-based plugin management feature is enabled by default with RHDH Local for development and testing purposes. **This functionality is not recommended in production environments.** In production, plugin management should be handled through proper configuration management and deployment pipelines.

### Why a Restart is Required

When you install or uninstall a plugin through the UI, you're changing which code RHDH needs to load. The restart ensures that:

- New plugin code is downloaded and made available
- The backend services can load the new functionality
- Configuration changes are properly applied across all services

Without a restart, your changes won't take effect because the running instance is still using the previous set of loaded plugins.

### How to Restart RHDH Local

After making plugin changes through the UI, restart your local instance with these commands:

=== "Podman"
    ```bash
    # Reinstall plugins and restart RHDH
    podman compose run install-dynamic-plugins
    podman compose restart rhdh
    ```

=== "Docker"
    ```bash
    # Reinstall plugins and restart RHDH
    docker compose run install-dynamic-plugins
    docker compose restart rhdh
    ```

This process typically may take a few minutes. You can monitor the startup progress in the container logs:

=== "Podman"
    ```bash
    podman compose logs -f rhdh
    ```

=== "Docker"
    ```bash
    docker compose logs -f rhdh
    ```

### Example: Installing the TODO Plugin

Let's walk through installing a simple plugin to try out the UI-based management feature.

**[TODO](https://github.com/backstage/community-plugins/tree/main/workspaces/todo)** is a plugin that scans your repository code and displays all TODO, FIXME, and similar comments in one place. It's a great plugin to test with because it requires minimal configuration and provides immediate, practical value.

1. **Open the Extensions page**: Navigate to **Administration** → **Extensions** in the RHDH sidebar
2. **Find the TODO plugin**: Use the search bar to find "TODO" or browse the available plugins
3. **Install the plugin**: Click on the TODO plugin and follow the installation prompts. The UI will then warn that a backend restart is required, like so:
   ![Extensions page showing "Backend restart required" warning after installing the TODO plugin](../images/dynamic-plugins-extensions-restart-required.png)
4. **Restart RHDH Local**: Run the restart commands shown above
5. **Verify the installation**: After restart, navigate to a component entity page and you should see a new "TODO" section in the entity Overview that lists any TODO comments found in the related repository, if any.

To uninstall, simply return to the Extensions page, find the installed plugin, and remove it; then restart again.

## Configuration File Location

Plugin configuration is managed through `configs/dynamic-plugins/dynamic-plugins.override.yaml` or `configs/dynamic-plugins/dynamic-plugins.yaml` if the former does not exist.

!!! tip "Quick Start"
    Copy the example file to get started:
    ```bash
    cp configs/dynamic-plugins/dynamic-plugins.override.example.yaml \
       configs/dynamic-plugins/dynamic-plugins.override.yaml
    ```

## How RHDH Local handles dynamic plugins configuration

1. **Override System**: Your override file entirely replaces the default plugin configuration (in `configs/dynamic-plugins/dynamic-plugins.yaml`)
2. **Download Phase**: Plugins are downloaded during the `install-dynamic-plugins` container startup
3. **Storage Location**: Downloaded plugins are cached in `/opt/app-root/src/dynamic-plugins-root/`
4. **Runtime Loading**: RHDH loads enabled plugins at startup

Refer to the [official RHDH documentation](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.7/html/introduction_to_plugins/con-rhdh-plugins) for more details about dynamic plugins.

## Catalog Index Configuration

Starting in 1.9, RHDH supports loading default plugin configurations from an OCI container image called the **catalog index**. This feature allows you to use centralized plugin configurations that can be updated independently of the RHDH container image. For general information about how the catalog index works, see [Using a Catalog Index Image for Default Plugin Configurations](https://github.com/redhat-developer/rhdh/blob/main/docs/dynamic-plugins/installing-plugins.md#using-a-catalog-index-image-for-default-plugin-configurations).

### Default Configuration

The default value of the `CATALOG_INDEX_IMAGE` environment variable is defined in `default.env`. When `[docker|podman] compose up` runs, the `env_file` directive in `compose.yaml` injects this variable into the `install-dynamic-plugins` container. The container's `install-dynamic-plugins.py` script detects the environment variable and uses `skopeo` to download the OCI image. To use a different catalog index version or a mirrored image, [override it in your local `.env` file](./configuration.md#environment-variables):

```bash
CATALOG_INDEX_IMAGE=my-registry.example.com/org/my-rhdh-plugin-catalog-index:1.2-3
```

### Configuration Structure

Your override file must start with:

```yaml
includes:
  - dynamic-plugins.default.yaml
  # you can also include the RHDH Local default
  # to get the plugins enabled for RHDH Local experience.
  # - configs/dynamic-plugins/dynamic-plugins.yaml

plugins:
  # Your plugin configurations here
```

## Plugin Sources

See the official RHDH Documentation for more details on how to [Install and View plugins](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.7/html/installing_and_viewing_plugins_in_red_hat_developer_hub/index).

### Private NPM Registry

If you're installing dynamic plugins from a private registry or using a proxy, you can customize your own `.npmrc` file. A `.npmrc.example` file is provided in the `configs/` directory as a template.

1. Copy the example file to create your own `.npmrc`. This `configs/.npmrc` file is Git-ignored by default:

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

!!! tip "npmrc configuration"
    For more information on configuring `.npmrc`, see the [npm configuration docs](https://docs.npmjs.com/cli/v10/configuring-npm/npmrc).

## Converting Static Plugins to Dynamic Plugins

If you have existing Backstage plugins (also known as "static" plugins) that you'd like to use with Red Hat Developer Hub, you can try converting them to dynamic plugins using the **RHDH Dynamic Plugins Factory**.

!!! success "Automated Conversion Tool 🔧"
    The [RHDH Dynamic Plugins Factory](https://github.com/redhat-developer/rhdh-dynamic-plugin-factory) is a containerized tool that automates the process of converting Backstage plugins into RHDH dynamic plugins. It handles:
    
    * Cloning plugin source repositories
    * Applying patches and custom modifications
    * Building and packaging plugins as dynamic plugins
    * Batch processing multiple plugins at once
    * Publishing to container registries (optional)

### Key Features

**Batch Conversion**

* Convert multiple plugins simultaneously by listing them in a configuration file
* Process entire plugin workspaces or individual plugins
* Apply consistent patches or overlays across multiple plugins

**Customization Support**

* Apply patches to modify plugin source code before conversion
* Use overlays to replace or add files during the build process
* Configure embed packages for plugins that require additional dependencies

**Container-Based Workflow**

* Uses pre-built container images for consistent builds
* Works with Podman (recommended) or Docker
* No need to install Node.js or build tools locally

### Getting Started

The factory uses container images published to `quay.io/rhdh-community/dynamic-plugins-factory`. You'll need:

1. **Configuration files**: Define your source repository and list of plugins to convert
2. **Container runtime**: Podman or Docker
3. **Volume mounts**: Mount your configuration, workspace (source-code), and output directories

A minimal example to convert the TODO plugin:

```bash
podman run --rm -it \
  --device /dev/fuse \
  -v ./config:/config:z \
  quay.io/rhdh-community/dynamic-plugins-factory:latest \
  --workspace-path workspaces/todo
```

!!! note "For Platform Engineers"
    The Dynamic Plugins Factory is primarily a tool for platform engineers who need to convert existing Backstage plugins for use in RHDH without having to resort to traditional coding solutions. For detailed usage instructions, configuration options, and examples, see the [official RHDH Dynamic Plugins Factory repository](https://github.com/redhat-developer/rhdh-dynamic-plugin-factory).

## Plugin Storage and Caching

### Understanding Plugin Storage

- **Cache Location**: `/opt/app-root/src/dynamic-plugins-root/`
- **Persistence**: Plugins persist across container restarts
- **Updates**: Plugins are re-downloaded if package versions change

### Managing Plugin Cache

=== "Podman"
    ```bash
    # Clear plugin cache (rebuilds all plugins)
    podman compose down --volumes
    podman compose up -d

    # Reinstall plugins without clearing other data
    podman compose run install-dynamic-plugins
    podman compose restart rhdh
    ```

=== "Docker"
    ```bash
    # Clear plugin cache (rebuilds all plugins)
    docker compose down --volumes
    docker compose up -d

    # Reinstall plugins without clearing other data
    docker compose run install-dynamic-plugins
    docker compose restart rhdh
    ```

## Applying Plugin Changes

### Standard Plugin Changes

After modifying the plugin configuration, for example after configuring plugins using the Extensions in the RHDH UI:

=== "Podman"
    ```bash
    # Reinstall plugins and restart RHDH
    podman compose run install-dynamic-plugins
    podman compose restart rhdh
    ```

=== "Docker"
    ```bash
    # Reinstall plugins and restart RHDH
    docker compose run install-dynamic-plugins
    docker compose restart rhdh
    ```

### Quick Restart (No Plugin Changes)

For configuration-only changes:

=== "Podman"
    ```bash
    # Just restart RHDH (if plugins haven't changed)
    podman compose restart rhdh
    ```

=== "Docker"
    ```bash
    # Just restart RHDH (if plugins haven't changed)
    docker compose restart rhdh
    ```
