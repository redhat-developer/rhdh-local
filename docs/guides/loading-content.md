# Loading Content with `app-config.local.yaml`

The `configs/app-config/app-config.local.yaml` file is your primary tool for automatically loading **catalogs**, **software templates**, and **TechDocs** into RHDH Local on startup.

## Configuration File Location

Your configuration overrides should be placed in `configs/app-config/app-config.local.yaml`.

!!! tip "Quick Start"
    Copy the example file to get started quickly:
    ```bash
    cp configs/app-config/app-config.local.example.yaml configs/app-config/app-config.local.yaml
    ```

## How Configuration Loading Works

1. **Merge Process**: RHDH Local places your `app-config.local.yaml` as last in the list of configuration files load at startup, along with the default configuration files (like `configs/app-config/app-config.yaml`). RHDH then handles the merging of the specified configuration files. So your custom `app-config.local.yaml` might override fields defined in the default configuration files.
2. **Volume Mounting**: The entire `configs/` directory is bind-mounted into containers, making local files accessible
3. **Automatic Discovery**: The Catalog plugin automatically discovers and registers all configured locations
4. **Extra Files**: Store additional files (credentials, certificates, etc.) in `configs/extra-files/`

## Loading local files

Note that the following files are automatically added to the Catalog in the default app-config.yaml file (unless you redefined the `catalog.locations` in your own `configs/app-config/app-config.local.yaml`):

- `configs/catalog-entities/components.override.yaml`
- `configs/catalog-entities/users.override.yaml`

As long as you create those files, they will be automatically registered in the Software Catalog.

!!! note
    As a rule of thumb, arrays from app-config files will not be merged by RHDH. This means for example that any `catalog.locations` specified in your `configs/app-config/app-config.local.yaml` will override the default `catalog.locations` defined in the default `configs/app-config/app-config.yaml` file.

## Applying Configuration Changes

After modifying `app-config.local.yaml`:


=== "Podman (Recommended)"
    ```bash
    # Restart RHDH to load new configuration
    podman compose stop rhdh && podman compose start rhdh
    ```

=== "Docker"
    ```bash
    # Restart RHDH to load new configuration
    docker compose stop rhdh && docker compose start rhdh
    ```

## Troubleshooting

### Common Issues

1. **Catalog not loading**: Check URL accessibility and authentication
2. **Local files not found**: Verify paths relative to container mount points
3. **Permission errors**: Ensure your configured GitHub App has appropriate repository access
