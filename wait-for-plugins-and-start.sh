#!/bin/sh

# This script is a workaround for podman-compose absence of support for depends_on

# Entrypoint for the main RHDH container.
# Waits for the dynamic plugins config to be generated,
# then starts the Backstage backend with optional local overrides.


DYNAMIC_PLUGINS_CONFIG="dynamic-plugins-root/app-config.dynamic-plugins.yaml"
USER_APP_CONFIG="configs/app-config/app-config.local.yaml"
DEFAULT_APP_CONFIG="configs/app-config/app-config.yaml"

# Wait for dynamic plugins config to be generated
while [ ! -f "$DYNAMIC_PLUGINS_CONFIG" ]; do
    echo "Waiting for $DYNAMIC_PLUGINS_CONFIG to be created by install-dynamic-plugins container ..."
    sleep 2
done

# Optionally include user app-config.local.yaml if it exists
EXTRA_CLI_ARGS=""
if [ -f "$USER_APP_CONFIG" ]; then
    echo "Using user app-config.local.yaml"
    EXTRA_CLI_ARGS="--config $USER_APP_CONFIG"
elif [ -f "configs/app-config.local.yaml" ]; then
    echo "[warn] Using legacy app-config.local.yaml. This method is deprecated. You should move your local app-config file under configs/app-config/app-config.local.yaml and extra files under configs/extra-files."
    EXTRA_CLI_ARGS="--config configs/app-config.local.yaml"
fi

# Handle catalog entity overrides
USERS_DEFAULT="configs/catalog-entities/users.yaml"
USERS_OVERRIDE="configs/catalog-entities/users.override.yaml"
USERS_TARGET="generated/users.merged.yaml"

COMPONENTS_DEFAULT="configs/catalog-entities/components.yaml"
COMPONENTS_OVERRIDE="configs/catalog-entities/components.override.yaml"
COMPONENTS_TARGET="generated/components.merged.yaml"

mkdir -p generated

# Users
if [ -f "$USERS_OVERRIDE" ]; then
    echo "[catalog] Using users.override.yaml"
    cp "$USERS_OVERRIDE" "$USERS_TARGET"
elif [ -f "$USERS_DEFAULT" ]; then
    echo "[catalog] Using default users.yaml"
    cp "$USERS_DEFAULT" "$USERS_TARGET"
else
    echo "[catalog] No users.yaml or override found. Creating empty file."
    touch "$USERS_TARGET"
fi

# Components
if [ -f "$COMPONENTS_OVERRIDE" ]; then
    echo "[catalog] Using components.override.yaml"
    cp "$COMPONENTS_OVERRIDE" "$COMPONENTS_TARGET"
    
    # If docs exist beside the override file, include them for TechDocs
    if [ -f "configs/catalog-entities/mkdocs.yml" ]; then
        cp configs/catalog-entities/mkdocs.yml generated/mkdocs.yml
    fi
    if [ -d "configs/catalog-entities/docs" ]; then
        cp -r configs/catalog-entities/docs generated/docs
    fi
elif [ -f "$COMPONENTS_DEFAULT" ]; then
    echo "[catalog] Using default components.yaml"
    cp "$COMPONENTS_DEFAULT" "$COMPONENTS_TARGET"
else
    echo "[catalog] No components.yaml or override found. Creating empty file."
    touch "$COMPONENTS_TARGET"
fi



# Run Backstage with default + optional config overrides
node packages/backend --no-node-snapshot \
    --config "app-config.yaml" \
    --config app-config.example.yaml \
    --config app-config.example.production.yaml \
    --config "$DYNAMIC_PLUGINS_CONFIG" \
    --config "$DEFAULT_APP_CONFIG" $EXTRA_CLI_ARGS
