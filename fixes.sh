#!/bin/sh

# Workaround for various issues

# Fix for https://issues.redhat.com/browse/RHIDP-3939
# needed for < 1.4
# if there is no config than the files in dynamic-plugins-root are from the image, and we need to remove them
if [ -d "dynamic-plugins-root" ]; then
    echo "dynamic-plugins-root exists"
    if [ ! -f "dynamic-plugins-root/app-config.dynamic-plugins.yaml" ]; then
        echo "app-config.dynamic-plugins.yaml does not exist"
        echo "Removing dynamic-plugins-root to fix RHIDP-3939"
        rm -rf ./dynamic-plugins-root
    fi
fi

# Fix for https://issues.redhat.com/browse/RHIDP-4410
# needed for < 1.3.0
echo "Removing ~/.npmrc to fix RHIDP-4410"
rm -rf ~/.npmrc

# handle dynamic-plugins config override
DYNAMIC_PLUGINS_DEFAULT="/opt/app-root/src/configs/dynamic-plugins/dynamic-plugins.yaml"
DYNAMIC_PLUGINS_OVERRIDE="/opt/app-root/src/configs/dynamic-plugins/dynamic-plugins.override.yaml"
LINK_TARGET="/opt/app-root/src/dynamic-plugins.yaml"
NPMRC_PATH="/opt/app-root/src/configs/.npmrc"

if [ -f "$DYNAMIC_PLUGINS_OVERRIDE" ]; then
    echo "Using dynamic-plugins.override.yaml"
    ln -sf "$DYNAMIC_PLUGINS_OVERRIDE" "$LINK_TARGET"
elif [ -f "/opt/app-root/src/configs/dynamic-plugins.yaml" ]; then
    echo "[warn] Using legacy dynamic-plugins.yaml. This method is deprecated. You can override the dynamic plugins configuration by renaming your file into configs/dynamic-plugins/dynamic-plugins.override.yaml"
    ln -sf "/opt/app-root/src/configs/dynamic-plugins.yaml" "$LINK_TARGET"
else
    echo "Using default dynamic-plugins.yaml"
    ln -sf "$DYNAMIC_PLUGINS_DEFAULT" "$LINK_TARGET"
fi

# If a .npmrc was mounted, set the NPM_CONFIG_USERCONFIG env var
if [ -f "$NPMRC_PATH" ]; then
    echo "Found .npmrc, setting NPM_CONFIG_USERCONFIG"
    export NPM_CONFIG_USERCONFIG="$NPMRC_PATH"
else
    echo "No .npmrc found, skipping NPM_CONFIG_USERCONFIG"
fi

echo "Running install-dynamic-plugins.sh"
./install-dynamic-plugins.sh /dynamic-plugins-root