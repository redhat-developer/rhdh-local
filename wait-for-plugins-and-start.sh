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
USERS_SOURCE="$USERS_DEFAULT"
[ -f "$USERS_OVERRIDE" ] && USERS_SOURCE="$USERS_OVERRIDE"

COMPONENTS_DEFAULT="configs/catalog-entities/components.yaml"
COMPONENTS_OVERRIDE="configs/catalog-entities/components.override.yaml"
COMPONENTS_SOURCE="$COMPONENTS_DEFAULT"
[ -f "$COMPONENTS_OVERRIDE" ] && COMPONENTS_SOURCE="$COMPONENTS_OVERRIDE"

mkdir -p generated

# Extract existing catalog.locations from DEFAULT_APP_CONFIG and filter out users.yaml/components.yaml
# Then append our override entries
if [ -f "$DEFAULT_APP_CONFIG" ]; then
    echo "Merging catalog locations from $DEFAULT_APP_CONFIG with overrides..."
    
    # Start the patched config with catalog.locations header
    echo "catalog:" > "$PATCHED_APP_CONFIG"
    echo "  locations:" >> "$PATCHED_APP_CONFIG"
    
    # Extract existing locations, excluding users.yaml and components.yaml targets
    # This is a simple approach - you might want to use yq for more robust YAML parsing
    if grep -q "catalog:" "$DEFAULT_APP_CONFIG" && grep -q "locations:" "$DEFAULT_APP_CONFIG"; then
        # Extract the locations block, filter out users.yaml and components.yaml entries
        awk '
        /^catalog:/{in_catalog=1; next}
        in_catalog && /^  locations:/{in_locations=1; next}
        in_locations && /^[^ ]/{in_locations=0; in_catalog=0}
        in_locations && /^    - /{
            entry=""
            target_line=""
        }
        in_locations && /^    - /{entry=$0; getline; while(/^      / && NF>0){entry=entry"\n"$0; if(/target:/){target_line=$0}; getline}; 
            if(target_line !~ /users\.yaml/ && target_line !~ /components\.yaml/){
                print entry
                if(NF>0 && /^      /) print $0
            }
        }
        ' "$DEFAULT_APP_CONFIG" >> "$PATCHED_APP_CONFIG"
    fi
    
    # Add our override entries
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

else
    # Fallback if DEFAULT_APP_CONFIG doesn't exist - just create our entries
    cat <<EOF > "$PATCHED_APP_CONFIG"
catalog:
  locations:
    - type: file
      target: $USERS_SOURCE
      rules:
        - allow: [User, Group]
    - type: file
      target: $COMPONENTS_SOURCE
      rules:
        - allow: [Component, System]
EOF
fi

# Run Backstage backend with layered config
exec node packages/backend --no-node-snapshot \
  --config "app-config.yaml" \
  --config app-config.example.yaml \
  --config app-config.example.production.yaml \
  --config "$DYNAMIC_PLUGINS_CONFIG" \
  --config "$DEFAULT_APP_CONFIG" \
  --config "$PATCHED_APP_CONFIG" $EXTRA_CLI_ARGS