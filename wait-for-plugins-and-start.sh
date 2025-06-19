#!/bin/sh

# This script is a workaround for podman-compose absence of support for depends_on

# Entrypoint for the main RHDH container.
# Waits for the dynamic plugins config to be generated,
# then starts the Backstage backend with optional local overrides.


DYNAMIC_PLUGINS_CONFIG="dynamic-plugins-root/app-config.dynamic-plugins.yaml"
USER_APP_CONFIG="configs/app-config/app-config.local.yaml"
DEFAULT_APP_CONFIG="configs/app-config/app-config.yaml"
PATCHED_APP_CONFIG="generated/app-config.patched.yaml"

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

COMPONENTS_DEFAULT="configs/catalog-entities/components.yaml"
COMPONENTS_OVERRIDE="configs/catalog-entities/components.override.yaml"

# Select sources (prioritize overrides)
USERS_SOURCE="$USERS_DEFAULT"
[ -f "$USERS_OVERRIDE" ] && USERS_SOURCE="$USERS_OVERRIDE"

COMPONENTS_SOURCE="$COMPONENTS_DEFAULT"
[ -f "$COMPONENTS_OVERRIDE" ] && COMPONENTS_SOURCE="$COMPONENTS_OVERRIDE"

# Create patched app-config.yaml with updated catalog.locations
mkdir -p generated
cp "$DEFAULT_APP_CONFIG" "$PATCHED_APP_CONFIG"

yq eval "
  .catalog.locations = [
    {
      type: \"file\",
      target: \"$USERS_SOURCE\",
      rules: { allow: [\"User\", \"Group\"] }
    },
    {
      type: \"file\",
      target: \"$COMPONENTS_SOURCE\",
      rules: { allow: [\"Component\", \"System\"] }
    }
  ]
" -i "$PATCHED_APP_CONFIG"

# Run Backstage with default + optional config overrides
node packages/backend --no-node-snapshot \
    --config "app-config.yaml" \
    --config app-config.example.yaml \
    --config app-config.example.production.yaml \
    --config "$DYNAMIC_PLUGINS_CONFIG" \
    --config "$PATCHED_APP_CONFIG" $EXTRA_CLI_ARGS
