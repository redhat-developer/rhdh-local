#!/usr/bin/env bash
# shellcheck shell=bash
# RHDH startup for Dev Spaces.
# rhdh-local provides upstream scripts; all user config comes from this repo.
set -euo pipefail

log() { printf '[devspaces-start] %s\n' "$*"; }
warn() { printf '[devspaces-start] WARN: %s\n' "$*" >&2; }
fail() { printf '[devspaces-start] ERROR: %s\n' "$*" >&2; exit 1; }

run_script() {
  local s="$1" mode="${2:-}"
  [[ -f "$s" ]] || fail "$(basename "$s") not found"
  if [[ "$mode" == "exec" ]]; then
    if [[ -x "$s" ]]; then
      exec "$s"
    else
      exec bash "$s"
    fi
  elif [[ -x "$s" ]]; then
    "$s"
  else
    bash "$s"
  fi
}

# Link all files from $1/<subdir>/* into $2/<subdir>/
link_dir() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  for f in "$src"/*; do [[ -e "$f" ]] && ln -sfn "$f" "$dst/$(basename "$f")"; done
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Locate rhdh-local ────────────────────────────────────────────────────────
for _dir in "${RHDH_LOCAL_DIR:-}" "$PWD" "/projects/rhdh-local" "$SCRIPT_DIR"; do
  [[ -n "$_dir" && -d "$_dir" && -f "$_dir/prepare-and-install-dynamic-plugins.sh" ]] && ROOT_DIR="$_dir" && break
done
ROOT_DIR="${ROOT_DIR:-/projects/rhdh-local}"
log "ROOT_DIR=$ROOT_DIR  SCRIPT_DIR=$SCRIPT_DIR"
cd "$ROOT_DIR"

# ── Paths ────────────────────────────────────────────────────────────────────
APP="/opt/app-root/src"
# Support both names. Prefer explicit env, then existing new-name dir, else legacy.
if [[ -n "${WORKSPACE_DYNAMIC_PLUGINS_DIR:-}" ]]; then
  DYN="$WORKSPACE_DYNAMIC_PLUGINS_DIR"
elif [[ -d "$APP/dynamic-root-plugins" ]]; then
  DYN="$APP/dynamic-root-plugins"
else
  DYN="$APP/dynamic-plugins-root"
fi
EXT="${WORKSPACE_EXTENSIONS_DIR:-$APP/extensions}"
GEN="${WORKSPACE_GENERATED_DIR:-$APP/generated}"
TMP="${WORKSPACE_TMP_DIR:-/projects/.rhdh/tmp}"

mkdir -p "$DYN" "$EXT" "$GEN" "$TMP" "$APP"

# Keep repo plugin folders as real directories (not symlinks/files).
for _local_dir in "$ROOT_DIR/dynamic-root-plugins" "$ROOT_DIR/dynamic-plugins-root"; do
  if [[ -L "$_local_dir" ]]; then
    rm -f "$_local_dir"
  elif [[ -e "$_local_dir" && ! -d "$_local_dir" ]]; then
    fail "$_local_dir exists and is not a directory"
  fi
  mkdir -p "$_local_dir"
done

# Generated/extensions should still map to writable workspace locations.
for _pair in "generated=$GEN" "extensions=$EXT"; do
  _target="$ROOT_DIR/${_pair%%=*}"
  [[ "$_target" == "/" ]] && fail "Refusing to remove root path"
  rm -rf -- "$_target" && ln -sfn "${_pair#*=}" "$_target"
done

# ── Env ──────────────────────────────────────────────────────────────────────
SAVED_BASE_URL="${BASE_URL:-auto}"
export NPM_CONFIG_CACHE="$TMP/.npm" YARN_CACHE_FOLDER="$TMP/.yarn"
mkdir -p "$NPM_CONFIG_CACHE" "$YARN_CACHE_FOLDER"

for f in "$ROOT_DIR/default.env" "$ROOT_DIR/.env"; do
  # shellcheck source=/dev/null
  [[ -f "$f" ]] && { set -a; source "$f"; set +a; }
done
export BASE_URL="$SAVED_BASE_URL"

# ── BASE_URL detection ───────────────────────────────────────────────────────
if [[ "$BASE_URL" == auto || "$BASE_URL" == AUTO || "$BASE_URL" == http://localhost:* ]]; then
  _ns="${DEVWORKSPACE_NAMESPACE:-}" _name="${DEVWORKSPACE_NAME:-}" _dom="${CLUSTER_APPS_DOMAIN:-}"
  if [[ -n "$_ns" && -n "$_name" && -n "$_dom" ]]; then
    export BASE_URL="https://${_ns%-devspaces}-${_name}-${RHDH_PUBLIC_ENDPOINT_NAME:-rhdh}.${_dom}"
    log "BASE_URL=$BASE_URL"
  else
    export BASE_URL="${BASE_URL_FALLBACK:-http://localhost:7007}"
    warn "Could not detect BASE_URL; using $BASE_URL"
  fi
fi

# ── No-op chown (OpenShift arbitrary UIDs) ───────────────────────────────────
mkdir -p "$TMP/noop-bin"
printf '#!/bin/sh\nexit 0\n' > "$TMP/noop-bin/chown" && chmod +x "$TMP/noop-bin/chown"
export PATH="$TMP/noop-bin:$PATH"

# ── Build writable configs dir ───────────────────────────────────────────────
CFG="$ROOT_DIR/configs"
WCFG="$TMP/configs"
rm -rf "$WCFG" && mkdir -p "$WCFG/dynamic-plugins" "$WCFG/app-config"

# Use only the cloned rhdh-local repository configs.
if [[ -d "$CFG" ]]; then
  link_dir "$CFG/dynamic-plugins" "$WCFG/dynamic-plugins"
  link_dir "$CFG/app-config"      "$WCFG/app-config"
  [[ -d "$CFG/extra-files" ]] && ln -sfn "$CFG/extra-files" "$WCFG/extra-files"
  log "Linked rhdh-local configs"
fi

# .npmrc: optional. Use a Kubernetes secret only when private npm auth is needed.
NPMRC_FILE="$WCFG/.npmrc"

# Preferred key: NPMRC_CONTENT (raw)
# Backward-compatible key: NPMRC_CONTENT_B64 (base64)
# Also supports mounted secret files.
_npmrc_payload=""
_npmrc_source=""

if [[ -n "${NPMRC_CONTENT:-}" ]]; then
  _npmrc_payload="$NPMRC_CONTENT"
  _npmrc_source="env:NPMRC_CONTENT"
elif [[ -n "${NPMRC_CONTENT_B64:-}" ]]; then
  # Keep compatibility with existing setups where Kubernetes already injects
  # this key as plain .npmrc content.
  _npmrc_payload="$NPMRC_CONTENT_B64"
  _npmrc_source="env:NPMRC_CONTENT_B64(raw)"

  # If the value looks base64-encoded, decode and prefer decoded content.
  if [[ "$NPMRC_CONTENT_B64" =~ ^[A-Za-z0-9+/=[:space:]]+$ ]]; then
    _decoded=""
    if command -v base64 >/dev/null 2>&1; then
      _decoded=$(printf '%s' "$NPMRC_CONTENT_B64" | base64 -d 2>/dev/null || true)
    elif command -v openssl >/dev/null 2>&1; then
      _decoded=$(printf '%s' "$NPMRC_CONTENT_B64" | openssl base64 -d -A 2>/dev/null || true)
    fi
    if [[ -n "$_decoded" ]]; then
      _npmrc_payload="$_decoded"
      _npmrc_source="env:NPMRC_CONTENT_B64(decoded)"
    fi
  fi
else
  for _secret_file in \
    "${NPMRC_CONTENT_FILE:-}" \
    "/etc/secrets/rhdh-secrets/NPMRC_CONTENT" \
    "/var/run/secrets/rhdh-secrets/NPMRC_CONTENT" \
    "/projects/.codespaces/secrets/NPMRC_CONTENT"; do
    [[ -n "$_secret_file" && -f "$_secret_file" ]] || continue
    _payload_from_file=$(cat "$_secret_file" 2>/dev/null || true)
    if [[ -n "$_payload_from_file" ]]; then
      _npmrc_payload="$_payload_from_file"
      _npmrc_source="file:$_secret_file"
      break
    fi
  done
fi

if [[ -n "$_npmrc_payload" ]]; then
  printf '%s\n' "$_npmrc_payload" > "$NPMRC_FILE"
  chmod 600 "$NPMRC_FILE"
  log ".npmrc created from ${_npmrc_source} ($(wc -l < "$NPMRC_FILE") lines)"
elif [[ -f "$ROOT_DIR/.npmrc" ]]; then
  cp "$ROOT_DIR/.npmrc" "$NPMRC_FILE"
  chmod 600 "$NPMRC_FILE"
  log ".npmrc copied from $ROOT_DIR/.npmrc"
elif [[ -f "$HOME/.npmrc" ]]; then
  cp "$HOME/.npmrc" "$NPMRC_FILE"
  chmod 600 "$NPMRC_FILE"
  log ".npmrc copied from $HOME/.npmrc"
else
  log ".npmrc not provided; continuing with public registries"
  log "If you use private npm, provide NPMRC_CONTENT (or NPMRC_CONTENT_B64) and restart workspace"
fi

# Tell npm/yarn to use this file directly (survives symlink breaks)
if [[ -f "$NPMRC_FILE" ]]; then
  export NPM_CONFIG_USERCONFIG="$NPMRC_FILE"
  for _d in "$APP" "$ROOT_DIR" "$HOME"; do
    [[ -d "$_d" ]] && ln -sfn "$NPMRC_FILE" "$_d/.npmrc" 2>/dev/null || true
  done
  log ".npmrc linked to: $APP, $ROOT_DIR, $HOME"
fi

# Symlink configs into RHDH app dir
rm -rf "$APP/configs" 2>/dev/null || true
ln -sfn "$WCFG" "$APP/configs"
log "configs → $WCFG | .npmrc: $(test -f "$WCFG/.npmrc" && echo present || echo MISSING)"

# Homepage data.json
if [[ -f "$ROOT_DIR/configs/extra-files/data.json" ]]; then
  mkdir -p "$APP/packages/app/dist/homepage"
  ln -sfn "$ROOT_DIR/configs/extra-files/data.json" "$APP/packages/app/dist/homepage/data.json"
fi

# Root-level symlinks for marketplace/extensions
ln -sfn "$EXT" /extensions 2>/dev/null || true
ln -sfn "$EXT" /marketplace 2>/dev/null || true
ln -sfn "$DYN" /dynamic-plugins-root 2>/dev/null || true
ln -sfn "$DYN" /dynamic-root-plugins 2>/dev/null || true

# ── Prepare install script ────────────────────────────────────────────────────
# The upstream prepare-and-install-dynamic-plugins.sh may have been overwritten
# by a previous run's NOOP stub. Restore from git if needed.
_install_script="$ROOT_DIR/prepare-and-install-dynamic-plugins.sh"

_is_real_install_script() {
  [[ -s "$1" ]] || return 1
  local _content
  _content=$(< "$1") 2>/dev/null || return 1
  (( ${#_content} > 500 )) || return 1
  [[ "$_content" != *__DEVSPACES_NOOP_STUB__* && "$_content" != *'Plugin install skipped'* ]]
}

if ! _is_real_install_script "$_install_script"; then
  log "Install script is missing or was overwritten — restoring..."

  # Method 1: git checkout (works if git binary available, e.g. tools container)
  if [[ -d "$ROOT_DIR/.git" ]] && command -v git &>/dev/null; then
    git -C "$ROOT_DIR" checkout HEAD -- prepare-and-install-dynamic-plugins.sh 2>/dev/null || true
  fi

  # Method 2: download from git remote (works without git binary)
  if ! _is_real_install_script "$_install_script" && [[ -d "$ROOT_DIR/.git" ]]; then
    # Parse remote URL and branch from .git/config and .git/HEAD
    _remote_url=$(sed -n '/\[remote "origin"\]/,/url/{s/.*url = //p}' "$ROOT_DIR/.git/config" 2>/dev/null | head -1)
    _branch=$(sed 's|ref: refs/heads/||' "$ROOT_DIR/.git/HEAD" 2>/dev/null)
    _branch="${_branch:-main}"
    # Convert GitHub URL to raw content URL
    _raw_url=$(printf '%s' "$_remote_url" | sed 's|github\.com|raw.githubusercontent.com|; s|\.git$||')
    _raw_url="${_raw_url}/${_branch}/prepare-and-install-dynamic-plugins.sh"

    if [[ "$_raw_url" == https://* ]]; then
      # Try curl
      if command -v curl &>/dev/null; then
        curl -fsSL "$_raw_url" -o "$_install_script" 2>/dev/null && chmod +x "$_install_script" || true
      fi
      # Try node (always available in rhdh container)
      if ! _is_real_install_script "$_install_script"; then
        NODE_OPTIONS="" node -e '
          const https = require("https"), fs = require("fs");
          function fetch(u, cb) {
            https.get(u, {headers:{"User-Agent":"rhdh"}}, r => {
              if ([301,302].includes(r.statusCode)) return fetch(r.headers.location, cb);
              let d = ""; r.on("data", c => d += c); r.on("end", () => cb(r.statusCode, d));
            }).on("error", () => cb(0, ""));
          }
          fetch(process.argv[1], (s, d) => {
            if (s === 200 && d.length > 500) { fs.writeFileSync(process.argv[2], d, {mode:0o755}); process.exit(0); }
            process.exit(1);
          });
        ' "$_raw_url" "$_install_script" 2>/dev/null || true
      fi
      _is_real_install_script "$_install_script" && log "Install script restored from remote: $_raw_url"
    fi
  fi

  _is_real_install_script "$_install_script" || \
    fail "Cannot restore install script. Open a 'tools' terminal and run: cd $ROOT_DIR && git checkout HEAD -- prepare-and-install-dynamic-plugins.sh"
  log "Install script restored"
fi

# Snapshot to a PID-unique temp so the original stays untouched for future runs
_run_script="$TMP/.install-script-to-run.$$.sh"
cp "$_install_script" "$_run_script"
chmod +x "$_run_script"

# Patch volume-mount paths + rm-rf handler in the snapshot (not the original)
sed -i "s|'/dynamic-plugins-root|'$DYN|g;s|\"/dynamic-plugins-root|\"$DYN|g;s| /dynamic-plugins-root| $DYN|g;s|'/extensions|'$EXT|g;s|\"/extensions|\"$EXT|g;s| /extensions| $EXT|g;s|rm -rf \\./dynamic-plugins-root|rm -rf ./dynamic-plugins-root/* ./dynamic-plugins-root/.[!.]* 2>/dev/null; true #|" "$_run_script" 2>/dev/null || true
[[ -f "$APP/install-dynamic-plugins.py" ]] && \
  sed -i "s|'/dynamic-plugins-root|'$DYN|g;s|\"/dynamic-plugins-root|\"$DYN|g;s| /dynamic-plugins-root| $DYN|g;s|'/extensions|'$EXT|g;s|\"/extensions|\"$EXT|g;s| /extensions| $EXT|g" "$APP/install-dynamic-plugins.py" 2>/dev/null || true

# ── Link local dynamic plugins into APP for npm pack ─────────────────────────
# Search order: LOCAL_PLUGINS_DIR env > $SCRIPT_DIR candidates > auto-discover under /projects
_local_plugins_dir=""
for _candidate in "${LOCAL_PLUGINS_DIR:-}" \
                  "$SCRIPT_DIR/dynamic-plugin-root" \
                  "$SCRIPT_DIR/dynamic-root-plugins" \
                  "$SCRIPT_DIR/dynamic-plugins-root"; do
  [[ -n "$_candidate" && -d "$_candidate" ]] || continue
  # Accept only real plugin source dirs that contain at least one package.json
  # in a direct child directory. This avoids selecting runtime symlink targets
  # such as $DYN when they are empty.
  if find "$_candidate" -mindepth 2 -maxdepth 2 -type f -name package.json -print -quit 2>/dev/null | grep -q .; then
    _local_plugins_dir="$_candidate"
    break
  fi
done

# Auto-discover: find directories named dynamic-plugin*-root under /projects with plugin subdirs
if [[ -z "$_local_plugins_dir" ]]; then
  while IFS= read -r _candidate; do
    # Verify it contains at least one subdir with a package.json
    for _sub in "$_candidate"/*/package.json; do
      [[ -f "$_sub" ]] && _local_plugins_dir="$_candidate" && break 2
    done
  done < <(find /projects -maxdepth 3 -type d \( -name 'dynamic-root-plugins' -o -name 'dynamic-plugins-root' -o -name 'dynamic-plugin*-root' \) ! -path '*/node_modules/*' ! -path '/opt/*' 2>/dev/null | sort)
fi

if [[ -n "$_local_plugins_dir" ]]; then
  for plugin_dir in "$_local_plugins_dir"/*/; do
    [[ -d "$plugin_dir" ]] || continue
    plugin_name=$(basename "$plugin_dir")
    # Support package paths like ./<plugin> and ./dynamic-root-plugins/<plugin>
    ln -sfn "$plugin_dir" "$DYN/$plugin_name"
    ln -sfn "$plugin_dir" "$APP/$plugin_name"
    log "Local plugin linked: $plugin_name → $DYN/$plugin_name and $APP/$plugin_name"
  done
else
  log "No local plugins dir found (set LOCAL_PLUGINS_DIR to override)"
fi

# ── Install dynamic plugins ──────────────────────────────────────────────────
cd "$APP"

GEN_CFG="$DYN/app-config.dynamic-plugins.yaml"
FORCE_REINSTALL="${FORCE_REINSTALL_PLUGINS:-false}"
CACHE_MARKER="$DYN/.cache-fingerprint"
PLUGIN_BACKUP="$TMP/.plugin-cache-backup"

# Fingerprint: RHDH version + all dynamic plugin config YAMLs + catalog image
# NOTE: Hash the REAL source files ($CFG and $ROOT_DIR), not $WCFG which holds symlinks.
# find -type f silently skips symlinks, so hashing the symlink dir always returns "none".
_override_file="$WCFG/dynamic-plugins/dynamic-plugins.override.yaml"
_rhdh_version=$(NODE_OPTIONS="" node -p "require('$APP/package.json').version" 2>/dev/null || echo "unknown")

_dynamic_plugins_cfg_hash() {
  # Hash the real source dirs/files — follow symlinks with -L just in case.
  # Include:
  #   1. Our overlay: $CFG/dynamic-plugins (real files, not the WCFG symlink copies)
  #   2. Upstream rhdh-local root-level dynamic-plugins*.yaml (the files the user edits)
  {
    [[ -d "$CFG/dynamic-plugins" ]] && \
      find -L "$CFG/dynamic-plugins" -type f \( -name '*.yaml' -o -name '*.yml' \) -print0 2>/dev/null | \
        sort -z | xargs -0 md5sum 2>/dev/null
    find -L "$ROOT_DIR" -maxdepth 1 -type f -name 'dynamic-plugins*.yaml' -print0 2>/dev/null | \
      sort -z | xargs -0 md5sum 2>/dev/null
  } | md5sum 2>/dev/null | cut -d' ' -f1 || echo "none"
}

_dynamic_cfg_hash=$(_dynamic_plugins_cfg_hash)
CURRENT_FP="${_rhdh_version}:${CATALOG_INDEX_IMAGE:-none}:${_dynamic_cfg_hash}"
log "Cache fingerprint: $CURRENT_FP"

# Check cache
CACHE_HIT=false
if [[ "$FORCE_REINSTALL" == "true" ]]; then
  log "Force reinstall requested"
elif [[ ! -f "$GEN_CFG" || ! -f "$CACHE_MARKER" ]]; then
  # DYN was wiped (workspace restart) — try restoring from persistent backup
  if [[ -f "$PLUGIN_BACKUP/app-config.dynamic-plugins.yaml" && -f "$PLUGIN_BACKUP/.cache-fingerprint" ]] && \
     [[ "$(cat "$PLUGIN_BACKUP/.cache-fingerprint" 2>/dev/null)" == "$CURRENT_FP" ]]; then
    log "DYN wiped but backup fingerprint matches — restoring from cache"
    cp -a "$PLUGIN_BACKUP"/. "$DYN/" 2>/dev/null || true
    CACHE_HIT=true
  else
    log "No plugin cache — first install"
  fi
elif [[ "$(cat "$CACHE_MARKER" 2>/dev/null)" == "$CURRENT_FP" ]]; then
  CACHE_HIT=true
else
  log "Dynamic plugin config changed — reinstalling all plugins"
fi

if [[ "$CACHE_HIT" == "true" ]]; then
  log "Plugins cached (fingerprint match) — skipping install"
  log "  (set FORCE_REINSTALL_PLUGINS=true to force)"
else
  log "Installing dynamic plugins..."

  # Validate local-path plugins before install. Do not skip silently.
  if [[ -L "$_override_file" ]]; then
    _resolved="$(readlink -f "$_override_file")"
    rm -f "$_override_file"
    cp "$_resolved" "$_override_file"
  fi

  # Collect local-path package refs from active config files.
  mapfile -t _required_local_pkgs < <(
    grep -RhoE "package:[[:space:]]*[\"']?\./(dynamic-root-plugins|dynamic-plugins-root)/[^\"'[:space:]]+" "$APP" "$ROOT_DIR" "$WCFG" 2>/dev/null |
      sed -E "s/^package:[[:space:]]*[\"']?\.\///" |
      sort -u
  )

  if (( ${#_required_local_pkgs[@]} )); then
    _missing_local_pkgs=()
    for _pkg in "${_required_local_pkgs[@]}"; do
      [[ -f "$APP/$_pkg/package.json" ]] || _missing_local_pkgs+=("$_pkg")
    done

    if (( ${#_missing_local_pkgs[@]} )); then
      warn "Local plugin package paths are referenced but not materialized:"
      printf '  - ./%s\n' "${_missing_local_pkgs[@]}" >&2
      fail "Missing package.json for local plugin paths above. Run deploy-dynamic-plugin first, then restart-rhdh."
    fi
  fi

  # Back up DYN before wiping (fallback if install fails)
  if [[ -f "$GEN_CFG" ]]; then
    rm -rf "$PLUGIN_BACKUP" && mkdir -p "$PLUGIN_BACKUP"
    cp -a "$DYN"/. "$PLUGIN_BACKUP/" 2>/dev/null || true
    log "Backed up existing plugins for fallback"
  fi

  find "$DYN" -mindepth 1 -delete 2>/dev/null || true

  # Re-link local plugins after cleanup so package paths like
  # ./dynamic-root-plugins/<plugin> are present for npm pack.
  if [[ -n "${_local_plugins_dir:-}" ]]; then
    for plugin_dir in "$_local_plugins_dir"/*/; do
      [[ -d "$plugin_dir" ]] || continue
      plugin_name=$(basename "$plugin_dir")
      ln -sfn "$plugin_dir" "$DYN/$plugin_name"
    done
  fi

  export CATALOG_ENTITIES_EXTRACT_DIR="$EXT"
  export MAX_ENTRY_SIZE="${MAX_ENTRY_SIZE:-30000000}"

  # Run installer with errexit disabled so we can handle failures
  _install_log="$TMP/plugin-install.log"
  set +eo pipefail
  bash "$_run_script" 2>&1 | tee "$_install_log"
  _rc=${PIPESTATUS[0]}
  set -eo pipefail
  [[ $_rc -ne 0 ]] && warn "Install script exited with code $_rc"

  # Outcome: success, fallback, or fatal
  if [[ -f "$GEN_CFG" ]]; then
    log "Plugin install succeeded"
    echo "$CURRENT_FP" > "$CACHE_MARKER"
  elif [[ -f "$PLUGIN_BACKUP/app-config.dynamic-plugins.yaml" ]]; then
    warn "Install FAILED — falling back to previous cached plugins."
    warn "Log: $TMP/plugin-install.log | Fix then FORCE_REINSTALL_PLUGINS=true"
    cp -a "$PLUGIN_BACKUP"/. "$DYN/" 2>/dev/null || true
  else
    [[ -f "$_install_log" ]] && { log "Last 30 lines:"; tail -30 "$_install_log" >&2; }
    fail "Plugin install failed, no fallback available. See log: $TMP/plugin-install.log"
  fi
fi
rm -f "$_run_script" 2>/dev/null || true
log "Plugin config ready"

# ── Copy local dynamic plugins ───────────────────────────────────────────────
if [[ -n "${_local_plugins_dir:-}" ]]; then
  for plugin_dir in "$_local_plugins_dir"/*/; do
    [[ -d "$plugin_dir" ]] || continue
    plugin_name=$(basename "$plugin_dir")
    dest="$DYN/$plugin_name"
    rm -rf "$dest" && cp -r "$plugin_dir" "$dest"
    log "Local plugin copied: $plugin_name"
  done
fi

# Save DYN for cache restore on workspace restart
if [[ -f "$GEN_CFG" ]]; then
  rm -rf "$PLUGIN_BACKUP" && mkdir -p "$PLUGIN_BACKUP"
  cp -a "$DYN"/. "$PLUGIN_BACKUP/" 2>/dev/null || true
fi

# Restore configs symlink if upstream broke it
[[ "$(readlink "$APP/configs" 2>/dev/null)" == "$WCFG" ]] || {
  warn "Restoring configs symlink"
  rm -rf "$APP/configs" 2>/dev/null || true
  ln -sfn "$WCFG" "$APP/configs"
}

# ── Patch BASE_URL + extensions path in image configs ────────────────────────
for cfg in "$APP"/app-config*.yaml "$GEN_CFG"; do
  [[ -f "$cfg" ]] || continue
  sed -i "s|baseUrl: http://localhost:[0-9]*|baseUrl: ${BASE_URL}|g;s|: /extensions|: ${EXT}|g" "$cfg" 2>/dev/null || true
done

# ── Write generated/app-config.patched.yaml (only file Backstage reads) ─────
PATCHED="$GEN/app-config.patched.yaml"
: > "$PATCHED"
for f in "$ROOT_DIR/configs/app-config/app-config.yaml" \
         "$ROOT_DIR/configs/app-config/app-config.local.yaml"; do
  [[ -f "$f" ]] && { cat "$f" >> "$PATCHED"; printf '\n' >> "$PATCHED"; log "Config: $f"; }
done

# Stubs for required plugin keys
grep -q '^quay:' "$PATCHED"       || printf 'quay:\n  uiUrl: https://quay.io\n' >> "$PATCHED"
grep -q '^extensions:' "$PATCHED" || printf 'extensions:\n  directory: %s\n' "$EXT" >> "$PATCHED"
grep -q '^marketplace:' "$PATCHED"|| printf 'marketplace:\n  directory: %s\n' "$EXT" >> "$PATCHED"

# ── Start ────────────────────────────────────────────────────────────────────
log "Starting RHDH..."
run_script "$ROOT_DIR/wait-for-plugins-and-start.sh" exec
