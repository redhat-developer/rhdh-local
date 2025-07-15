#!/bin/sh

# This script is a workaround for podman-compose absence of support for depends_on

# Entrypoint for the main RHDH container.
# Waits for the dynamic plugin config to be generated,
# then starts the Backstage backend with appropriate config files.
#
# If user-supplied override files for catalog entities (users/components) exist,
# this script replaces their paths in the base config accordingly.


DYNAMIC_PLUGINS_CONFIG="dynamic-plugins-root/app-config.dynamic-plugins.yaml"
DEFAULT_APP_CONFIG="configs/app-config/app-config.yaml"
PATCHED_APP_CONFIG="generated/app-config.patched.yaml"

USER_APP_CONFIG="configs/app-config/app-config.local.yaml"
LEGACY_USER_APP_CONFIG="configs/app-config.local.yaml"

USERS_OVERRIDE="configs/catalog-entities/users.override.yaml"
COMPONENTS_OVERRIDE="configs/catalog-entities/components.override.yaml"

mkdir -p generated
cp -f "$DEFAULT_APP_CONFIG" "$PATCHED_APP_CONFIG"

# Wait until the dynamic plugin config is ready
while [ ! -f "$DYNAMIC_PLUGINS_CONFIG" ]; do
  echo "Waiting for $DYNAMIC_PLUGINS_CONFIG to be created by install-dynamic-plugins container ..."
  sleep 2
done

# Apply overrides by replacing target paths in the patched config
if [ -f "$USERS_OVERRIDE" ]; then
  echo "Applying users override"
  sed -i "s|/opt/app-root/src/configs/catalog-entities/users.yaml|/opt/app-root/src/$USERS_OVERRIDE|" "$PATCHED_APP_CONFIG"
fi

if [ -f "$COMPONENTS_OVERRIDE" ]; then
  echo "Applying components override"
  sed -i "s|/opt/app-root/src/configs/catalog-entities/components.yaml|/opt/app-root/src/$COMPONENTS_OVERRIDE|" "$PATCHED_APP_CONFIG"
fi

# Add local config if available
EXTRA_CLI_ARGS=""
if [ -f "$USER_APP_CONFIG" ]; then
  echo "Using user app-config.local.yaml"
  EXTRA_CLI_ARGS="--config $USER_APP_CONFIG"
elif [ -f "$LEGACY_USER_APP_CONFIG" ]; then
  echo "[warn] Using legacy app-config.local.yaml. This is deprecated. Please migrate to configs/app-config/app-config.local.yaml."
  EXTRA_CLI_ARGS="--config $LEGACY_USER_APP_CONFIG"
fi

# Start Backstage backend
# shellcheck disable=SC2086 
# Allows variable expansion for CLI args
exec node packages/backend --no-node-snapshot \
  --config "app-config.yaml" \
  --config app-config.example.yaml \
  --config app-config.example.production.yaml \
  --config "$DYNAMIC_PLUGINS_CONFIG" \
  --config "$PATCHED_APP_CONFIG" $EXTRA_CLI_ARGS
