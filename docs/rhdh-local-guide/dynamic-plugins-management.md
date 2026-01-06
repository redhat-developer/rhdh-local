The dynamic plugin system in RHDH enables you to add, remove, enable, and disable plugins without rebuilding the container. This provides incredible flexibility for testing different plugin combinations and developing custom plugins locally.

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

```bash
# Clear plugin cache (rebuilds all plugins)
podman compose down --volumes
podman compose up -d

# Reinstall plugins without clearing other data
podman compose run install-dynamic-plugins
podman compose stop rhdh && podman compose start rhdh
```

## Applying Plugin Changes

### Standard Plugin Changes

After modifying the plugin configuration, for example after configuring plugins using the Extensions in the RHDH UI:

```bash
# Reinstall plugins and restart RHDH
podman compose run install-dynamic-plugins
podman compose stop rhdh && podman compose start rhdh
```

### Quick Restart (No Plugin Changes)

For configuration-only changes:

```bash
# Just restart RHDH (if plugins haven't changed)
podman compose stop rhdh && podman compose start rhdh
```
