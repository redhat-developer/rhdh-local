#!/bin/sh

# This script is a workaround for podman-compose absence of support for depends_on

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
fi

# Run Backstage with default + optional config overrides
node packages/backend --no-node-snapshot \
    --config "app-config.yaml" \
    --config app-config.example.yaml \
    --config app-config.example.production.yaml \
    --config "$DYNAMIC_PLUGINS_CONFIG" \
    --config "$DEFAULT_APP_CONFIG" "$EXTRA_CLI_ARGS"
