#!/bin/bash
# Validates the default no-OKP Compose configuration and statically renders
# the OKP opt-in overlay without pulling or starting the OKP image.
#
# Environment:
#   TOOL     - Container tool to use (default: podman)
#   CLI_ARGS - Compose arguments for the configuration under test
#
# Assumes CWD is the repository root.

set -euo pipefail

TOOL="${TOOL:-podman}"
CLI_ARGS="${CLI_ARGS:-}"

for cmd in "$TOOL" jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: Required command '$cmd' not found." >&2
        exit 1
    fi
done

current_config=$(mktemp)
okp_config=$(mktemp)
trap 'rm -f "$current_config" "$okp_config"' EXIT

# CLI_ARGS intentionally contains the selected Compose file arguments.
# shellcheck disable=SC2086
$TOOL compose $CLI_ARGS config --format json > "$current_config"

jq -e '.services | has("lightspeed-core")' "$current_config" > /dev/null

if jq -e '.services | has("okp")' "$current_config" > /dev/null; then
    echo "ERROR: OKP must not be part of the default Intelligent Assistant configuration." >&2
    exit 1
fi

if jq -e '(.services["lightspeed-core"].environment // {}) | has("OKP_SERVICE_URL")' "$current_config" > /dev/null; then
    echo "ERROR: OKP_SERVICE_URL must not be set by default." >&2
    exit 1
fi

jq -e '
  any(
    .services["lightspeed-core"].volumes[];
    .target == "/app-root/lightspeed-stack.yaml"
    and (.source | endswith("/configs/extra-files/lightspeed-stack-no-okp.yaml"))
  )
' "$current_config" > /dev/null

# Render the opt-in configuration without pulling or starting OKP.
$TOOL compose \
    -f compose.yaml \
    -f intelligent-assistant/compose-with-okp.yaml \
    config --format json > "$okp_config"

jq -e '.services | has("okp")' "$okp_config" > /dev/null
jq -e '(.services["lightspeed-core"].environment // {}) | has("OKP_SERVICE_URL")' "$okp_config" > /dev/null
jq -e '
  any(
    .services["lightspeed-core"].volumes[];
    .target == "/app-root/lightspeed-stack.yaml"
    and (.source | endswith("/configs/extra-files/lightspeed-stack.yaml"))
  )
' "$okp_config" > /dev/null

echo "Intelligent Assistant Compose configuration validation passed."
