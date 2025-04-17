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

# If mounted .npmrc is present, symlink to expected npm path
if [ -f "/opt/app-root/src/.npmrc" ]; then
    echo "Using mounted .npmrc file"
    cp /opt/app-root/src/.npmrc ~/.npmrc
fi

echo "Running install-dynamic-plugins.sh"
/opt/app-root/src/install-dynamic-plugins.sh /dynamic-plugins-root
