#!/bin/sh

set -euo pipefail

# Terminal colors
NC='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'

log_info()    { echo "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo "${RED}[ERROR]${NC} $1"; }
log_step()    { echo "${BOLD}${CYAN}==> $1${NC}"; }

log_step "Checking RHIDP-3939 workaround prerequisites"

# Fix for RHIDP-3939
if [ -d "dynamic-plugins-root" ]; then
    log_info "'dynamic-plugins-root' directory exists"
    if [ ! -f "dynamic-plugins-root/app-config.dynamic-plugins.yaml" ]; then
        log_warn "'app-config.dynamic-plugins.yaml' is missing"
        log_info "Removing 'dynamic-plugins-root' to fix RHIDP-3939"
        rm -rf ./dynamic-plugins-root
    else
        log_info "'app-config.dynamic-plugins.yaml' exists — no action needed"
    fi
else
    log_info "'dynamic-plugins-root' does not exist — nothing to do"
fi

log_step "Applying RHIDP-4410 workaround"

# Fix for RHIDP-4410
if [ -f "$HOME/.npmrc" ]; then
    log_info "Removing user .npmrc to avoid build issues (RHIDP-4410)"
    rm -f "$HOME/.npmrc"
else
    log_info "No user .npmrc found — skipping"
fi

log_step "Configuring dynamic-plugins.yaml symlink"

# Handle dynamic plugins override
DYNAMIC_PLUGINS_DEFAULT="/opt/app-root/src/configs/dynamic-plugins/dynamic-plugins.yaml"
DYNAMIC_PLUGINS_OVERRIDE="/opt/app-root/src/configs/dynamic-plugins/dynamic-plugins.override.yaml"
LINK_TARGET="/opt/app-root/src/dynamic-plugins.yaml"

if [ -f "$DYNAMIC_PLUGINS_OVERRIDE" ]; then
    log_info "Using override: dynamic-plugins.override.yaml"
    ln -sf "$DYNAMIC_PLUGINS_OVERRIDE" "$LINK_TARGET"
elif [ -f "/opt/app-root/src/configs/dynamic-plugins.yaml" ]; then
    log_warn "Using legacy dynamic-plugins.yaml (deprecated)"
    log_warn "Rename it to dynamic-plugins.override.yaml for clarity"
    ln -sf "/opt/app-root/src/configs/dynamic-plugins.yaml" "$LINK_TARGET"
else
    log_info "Falling back to default dynamic-plugins.yaml"
    ln -sf "$DYNAMIC_PLUGINS_DEFAULT" "$LINK_TARGET"
fi

log_step "Checking for mounted .npmrc"

# Handle mounted .npmrc
NPMRC_PATH="/opt/app-root/src/configs/.npmrc"
if [ -f "$NPMRC_PATH" ]; then
    log_info "Found mounted .npmrc — exporting NPM_CONFIG_USERCONFIG"
    export NPM_CONFIG_USERCONFIG="$NPMRC_PATH"
else
    log_info "No .npmrc found — skipping NPM_CONFIG_USERCONFIG"
fi

log_step "Running plugin installer script"

if [ -x ./install-dynamic-plugins.sh ]; then
    ./install-dynamic-plugins.sh /dynamic-plugins-root
    log_info "Dynamic plugins installed successfully"
else
    log_error "'install-dynamic-plugins.sh' not found or not executable"
    exit 1
fi
