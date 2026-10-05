#!/bin/bash
# Validates the running default Intelligent Assistant configuration.
#
# Environment:
#   TOOL     - Container tool to use (default: podman)
#   CLI_ARGS - Compose arguments for the running configuration
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

max=30
i=0
echo "Waiting for Lightspeed Core readiness..."
# CLI_ARGS intentionally contains the selected Compose file arguments.
# shellcheck disable=SC2086
until $TOOL compose $CLI_ARGS exec -T rhdh \
    curl -fsS http://localhost:8080/readiness | jq -e '.ready == true' > /dev/null; do
    i=$((i + 1))
    if [[ "$i" -ge "$max" ]]; then
        echo "ERROR: Lightspeed Core did not become ready." >&2
        exit 1
    fi
    echo "($i/$max) Waiting for Lightspeed Core readiness..."
    sleep 5
done

# shellcheck disable=SC2086
if $TOOL compose $CLI_ARGS ps --all --services | grep -qx okp; then
    echo "ERROR: An OKP container is running in the default configuration." >&2
    exit 1
fi

# shellcheck disable=SC2086
if $TOOL compose $CLI_ARGS exec -T lightspeed-core env | grep -q '^OKP_SERVICE_URL='; then
    echo "ERROR: OKP_SERVICE_URL is set in the default configuration." >&2
    exit 1
fi

if command -v sha256sum &>/dev/null; then
    expected_config_sha=$(sha256sum configs/extra-files/lightspeed-stack-no-okp.yaml | awk '{print $1}')
else
    expected_config_sha=$(shasum -a 256 configs/extra-files/lightspeed-stack-no-okp.yaml | awk '{print $1}')
fi

# The LCORE image is Linux-based and provides sha256sum.
# shellcheck disable=SC2086
mounted_config_sha=$($TOOL compose $CLI_ARGS exec -T lightspeed-core \
    sha256sum /app-root/lightspeed-stack.yaml | awk '{print $1}')

if [[ "$mounted_config_sha" != "$expected_config_sha" ]]; then
    echo "ERROR: Lightspeed Core is not using the expected no-OKP configuration." >&2
    exit 1
fi

echo "Intelligent Assistant runtime validation passed."
