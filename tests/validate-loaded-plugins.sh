#!/bin/bash
# Validates that explicitly configured dynamic plugins are actually loaded
# in the running RHDH instance by querying /api/extensions/loaded-plugins.
#
# Usage: ./tests/validate-loaded-plugins.sh [additional-config-files...]
# Environment:
#   RHDH_URL - Base URL of the RHDH instance (default: http://localhost:7007)
#
# Authenticates via guest auth (GET /api/auth/guest/refresh) to obtain
# a Backstage identity token, then queries /api/extensions/loaded-plugins.
#
# The script determines the effective dynamic-plugins config
# (override if it exists, else default) and parses it using yq.
# Any extra config files (e.g., orchestrator) can be passed as arguments.
# Assumes CWD is the repository root.

set -euo pipefail

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

for cmd in yq jq curl; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: Required command '$cmd' not found." >&2
        exit 1
    fi
done

RHDH_URL="${RHDH_URL:-http://localhost:7007}"
DYN_PLUGINS_DIR="configs/dynamic-plugins"

primary_config="$DYN_PLUGINS_DIR/dynamic-plugins.yaml"
if [[ -f "$DYN_PLUGINS_DIR/dynamic-plugins.override.yaml" ]]; then
    primary_config="$DYN_PLUGINS_DIR/dynamic-plugins.override.yaml"
fi

config_files=("$primary_config")
for extra in "$@"; do
    if [[ -f "$extra" ]]; then
        config_files+=("$extra")
    else
        echo "WARNING: Extra config file not found, skipping: $extra"
    fi
done

echo "Config files: ${config_files[*]}"

# Extract the raw plugin name from a package reference.
# ./dynamic-plugins/dist/foo → foo
# oci://host/path/foo:tag → foo
# oci://host/path/foo:tag!bar → bar
extract_plugin_name() {
    local pkg="$1"
    if [[ "$pkg" == *"!"* ]]; then
        echo "${pkg##*!}"
        return
    fi
    local name="${pkg##*/}"
    name="${name%%:*}" # strip tag (e.g. :v1.2.3 or :{{inherit}})
    echo "$name"
}

# Normalize a plugin name so OCI image names and npm scoped package names
# can be compared. For example:
#   @backstage-community/plugin-quay-backend-dynamic → backstage-community-plugin-quay-backend
#   backstage-community-plugin-quay-backend          → backstage-community-plugin-quay-backend
normalize_plugin_name() {
    local name="$1"
    name="${name#@}"
    name="${name//\//-}"
    name="${name%-dynamic}"
    echo "$name"
}

expected_plugins=()
disabled_plugins=()
for cfg in "${config_files[@]}"; do
    if ! yq -e '.plugins' "$cfg" > /dev/null 2>&1; then
        echo "Config $cfg has no .plugins array, skipping."
        continue
    fi

    enabled_output=$(yq -r '.plugins[] | select(.disabled != true and .enabled != false) | .package' "$cfg") || {
        echo "ERROR: Failed to extract enabled plugins from $cfg" >&2
        exit 1
    }
    while IFS= read -r raw_pkg; do
        [[ -z "$raw_pkg" ]] && continue
        expected_plugins+=("$(extract_plugin_name "$raw_pkg")")
    done <<< "$enabled_output"

    disabled_output=$(yq -r '.plugins[] | select(.disabled == true or .enabled == false) | .package' "$cfg") || {
        echo "ERROR: Failed to extract disabled plugins from $cfg" >&2
        exit 1
    }
    while IFS= read -r raw_pkg; do
        [[ -z "$raw_pkg" ]] && continue
        disabled_plugins+=("$(extract_plugin_name "$raw_pkg")")
    done <<< "$disabled_output"
done

if [[ ${#expected_plugins[@]} -eq 0 ]] && [[ ${#disabled_plugins[@]} -eq 0 ]]; then
    echo "WARNING: No plugins found in config files. Nothing to validate."
    exit 0
fi

echo ""
echo "Obtaining guest auth token from ${RHDH_URL}/api/auth/guest/refresh ..."
guest_response=$(curl -sS -f "${RHDH_URL}/api/auth/guest/refresh" \
    -H "Accept: application/json")
RHDH_TOKEN=$(echo "$guest_response" | jq -r '.backstageIdentity.token // empty' 2>/dev/null)
if [[ -z "$RHDH_TOKEN" ]]; then
    echo "ERROR: Could not obtain guest auth token." >&2
    echo "Response: $guest_response" >&2
    exit 1
fi
echo "Guest auth token obtained."

echo ""
echo "Fetching loaded plugins from ${RHDH_URL}/api/extensions/loaded-plugins ..."
http_code=$(curl -sS -o "$tmpfile" -w "%{http_code}" \
    -H "Authorization: Bearer ${RHDH_TOKEN}" \
    "${RHDH_URL}/api/extensions/loaded-plugins")

if [[ "$http_code" != "200" ]]; then
    echo "ERROR: Could not reach loaded-plugins endpoint (HTTP $http_code)." >&2
    echo "Response body:" >&2
    cat "$tmpfile" >&2 2>/dev/null || true
    exit 1
fi

loaded_names=$(jq -r '.[].name' "$tmpfile" 2>/dev/null)
if [[ -z "$loaded_names" ]]; then
    echo "ERROR: Loaded plugins response was empty or could not be parsed." >&2
    echo "Response body:" >&2
    cat "$tmpfile" >&2 2>/dev/null || true
    exit 1
fi

# Build a list of normalized loaded plugin names for matching.
normalized_loaded=()
while IFS= read -r loaded; do
    normalized_loaded+=("$(normalize_plugin_name "$loaded")")
done <<< "$loaded_names"

failed=0

if [[ ${#expected_plugins[@]} -gt 0 ]]; then
    echo ""
    echo "Validating ${#expected_plugins[@]} expected plugin(s) are loaded:"
    for name in "${expected_plugins[@]}"; do
        norm_expected=$(normalize_plugin_name "$name")
        found=false
        for norm_loaded in "${normalized_loaded[@]}"; do
            if [[ "$norm_expected" = "$norm_loaded" ]]; then
                found=true
                break
            fi
        done
        if $found; then
            echo "  [PASS] $name"
        else
            echo "  [FAIL] $name (normalized: $norm_expected) -- not found in loaded plugins" >&2
            failed=$((failed + 1))
        fi
    done
fi

if [[ ${#disabled_plugins[@]} -gt 0 ]]; then
    echo ""
    echo "Validating ${#disabled_plugins[@]} disabled plugin(s) are NOT loaded:"
    for name in "${disabled_plugins[@]}"; do
        norm_disabled=$(normalize_plugin_name "$name")
        found=false
        for norm_loaded in "${normalized_loaded[@]}"; do
            if [[ "$norm_disabled" = "$norm_loaded" ]]; then
                found=true
                break
            fi
        done
        if $found; then
            echo "  [FAIL] $name (normalized: $norm_disabled) -- should not be loaded" >&2
            failed=$((failed + 1))
        else
            echo "  [PASS] $name"
        fi
    done
fi

echo ""
if [[ $failed -gt 0 ]]; then
    echo "FAILED: $failed plugin validation(s) failed." >&2
    echo ""
    echo "Loaded plugins:"
    jq -r '.[].name' "$tmpfile" | sort
    exit 1
fi

echo "All plugin validations passed."
