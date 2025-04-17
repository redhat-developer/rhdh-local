#!/usr/bin/env bash
set -euo pipefail

NPMRC_SOURCE="${1:-$HOME/.npmrc}"
NPMRC_TARGET="./user-npmrc"

if [[ -f "$NPMRC_SOURCE" ]]; then
  echo "[INFO] Using .npmrc from $NPMRC_SOURCE"
  cp "$NPMRC_SOURCE" "$NPMRC_TARGET"
  export NPMRC_ENV_LINE="NPM_CONFIG_USERCONFIG=/opt/app-root/src/.npmrc"
else
  echo "[INFO] No .npmrc found at $NPMRC_SOURCE, skipping"
  rm -f "$NPMRC_TARGET" || true
  unset NPMRC_ENV_LINE
fi

echo "[INFO] Starting RHDH Local"
podman-compose up -d
