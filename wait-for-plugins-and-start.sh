#!/bin/sh

# This script is a workaround for podman-compose absence of support for depends_on

# Entrypoint for the main RHDH container.
# Waits for the dynamic plugins config to be generated,
# then starts the Backstage backend with optional local overrides.


DYNAMIC_PLUGINS_CONFIG="dynamic-plugins-root/app-config.dynamic-plugins.yaml"
USER_APP_CONFIG="configs/app-config/app-config.local.yaml"
DEFAULT_APP_CONFIG="configs/app-config/app-config.yaml"
PATCHED_APP_CONFIG="generated/app-config.patched.yaml"

USERS_DEFAULT="configs/catalog-entities/users.yaml"
USERS_OVERRIDE="configs/catalog-entities/users.override.yaml"
USERS_SOURCE="${USERS_OVERRIDE:-$USERS_DEFAULT}"

COMPONENTS_DEFAULT="configs/catalog-entities/components.yaml"
COMPONENTS_OVERRIDE="configs/catalog-entities/components.override.yaml"
COMPONENTS_SOURCE="${COMPONENTS_OVERRIDE:-$COMPONENTS_DEFAULT}"

mkdir -p generated

# Wait for dynamic plugins config to be generated
while [ ! -f "$DYNAMIC_PLUGINS_CONFIG" ]; do
  echo "Waiting for $DYNAMIC_PLUGINS_CONFIG to be created ..."
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

# Start patched config
echo "catalog:" > "$PATCHED_APP_CONFIG"
echo "  locations:" >> "$PATCHED_APP_CONFIG"

# Extract upstream locations except users/components
awk '
  $0 ~ /^catalog:/      { in_catalog=1; next }
  in_catalog && $0 ~ /^  locations:/ { in_locations=1; next }
  in_locations && $0 ~ /^  [^ ]/     { in_locations=0 }

  in_locations {
    if ($0 ~ /^    - /) {
      if (entry && target !~ /users\.yaml/ && target !~ /components\.yaml/) {
        print entry
      }
      entry = $0
      target = ""
    } else if ($0 ~ /^      /) {
      entry = entry "\n" $0
      if ($0 ~ /target:/) target = $0
    }
  }

  END {
    if (entry && target !~ /users\.yaml/ && target !~ /components\.yaml/) {
      print entry
    }
  }
' "$DEFAULT_APP_CONFIG" >> "$PATCHED_APP_CONFIG"

# Append override entries
cat <<EOF >> "$PATCHED_APP_CONFIG"
    - type: file
      target: $USERS_SOURCE
      rules:
        - allow: [User, Group]
    - type: file
      target: $COMPONENTS_SOURCE
      rules:
        - allow: [Component, System]
EOF

echo "Generated patched catalog config:"
echo "  Users: $USERS_SOURCE"
echo "  Components: $COMPONENTS_SOURCE"

# Start Backstage
exec node packages/backend --no-node-snapshot \
  --config "app-config.yaml" \
  --config app-config.example.yaml \
  --config app-config.example.production.yaml \
  --config "$DYNAMIC_PLUGINS_CONFIG" \
  --config "$DEFAULT_APP_CONFIG" \
  --config "$PATCHED_APP_CONFIG" $EXTRA_CLI_ARGS
