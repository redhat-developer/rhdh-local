RHDH Local uses a structured configuration approach with override files:

```bash
.env                                   # local .env file to override the default.env env vars or add new ones
configs/
├── .npmrc                             # npmrc configuration file
├── app-config/
│   ├── app-config.local.yaml          # Your app configuration overrides
├── dynamic-plugins/
│   ├── dynamic-plugins.override.yaml  # Your plugin overrides
├── catalog-entities/
│   ├── users.override.yaml            # Custom user entities
│   └── components.override.yaml       # Custom component entities
└── extra-files/
    └── github-app-credentials.yaml    # GitHub App credentials
    └── any-extra-file                 # Any custom extra file
```

## Creating Configuration Files

Copy the example files to get started quickly:

```bash
# App configuration
cp configs/app-config/app-config.local.example.yaml \
   configs/app-config/app-config.local.yaml

# Plugin configuration  
cp configs/dynamic-plugins/dynamic-plugins.override.example.yaml \
   configs/dynamic-plugins/dynamic-plugins.override.yaml

# Catalog entities
cp configs/catalog-entities/users.override.example.yaml \
   configs/catalog-entities/users.override.yaml
cp configs/catalog-entities/components.override.example.yaml \
   configs/catalog-entities/components.override.yaml
```

## Environment Variables

Customize your setup using the `.env` file. Override any variable from `default.env` or add new ones to be injected into the RHDH containers:

```bash
# Create custom environment file
touch .env

# Edit your preferences (either redefine an env var from default.env or add new ones)
# Examples:
echo "RHDH_IMAGE=quay.io/rhdh-community/rhdh:latest" >> .env
echo "LOG_LEVEL=debug" >> .env

# Recreate the RHDH Local containers. See the "Applying configuration changes" section below
```

Common variables to customize:

- `RHDH_IMAGE`: RHDH container image version
- `LOG_LEVEL`: RHDH application log level
- GitHub authentication variables (see the [GitHub auth guide](github-auth.md))

## Applying Configuration Changes

After making configuration changes:

```bash
# For app-config changes
podman compose stop rhdh && podman compose start rhdh

# For plugin changes  
podman compose run install-dynamic-plugins
podman compose stop rhdh && podman compose start rhdh
```
