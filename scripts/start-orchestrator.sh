#!/usr/bin/env bash
# SonataFlow Dev Spaces entrypoint.
set -euo pipefail

# Auto-discover workflow repos: any /projects/*/workflows dir is picked up.
# To pin specific roots instead, set WF_ROOTS (colon-separated):
#   WF_ROOTS="/projects/workflow-repo/workflows:/projects/wf-app-registration/workflows"

PROJECTS_DIR="/projects"
WF_DIR="/home/kogito/serverless-workflow-project"
LOG="/tmp/sonataflow-start.log"

log()  { echo "[sonataflow] $*"; }
warn() { echo "[sonataflow] WARN: $*"; }

# Load the dev .env file so secrets like CLDCTL_GITHUB_TOKEN are available
# to the Quarkus JVM process started later in this script.
# Use safe parsing (only KEY=VALUE lines, skip comments) to prevent arbitrary code execution.
_env_file="${PROJECTS_DIR}/rhdh-local/.env"
if [ -f "$_env_file" ]; then
  set -a
  while IFS='=' read -r key value; do
    # Skip empty lines and comments
    [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
    # Validate key format (alphanumeric and underscore only)
    [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] && export "$key"="$value"
  done < "$_env_file"
  set +a
  log "Loaded env from $_env_file (CLDCTL_GITHUB_TOKEN set=$([ -n "${CLDCTL_GITHUB_TOKEN:-}" ] && echo yes || echo NO))"
else
  warn ".env not found at $_env_file — CLDCTL_GITHUB_TOKEN will be empty; check WORKFLOW_REPO_DIR"
fi

# Build the list of workflow roots
_wf_roots=()
if [[ -n "${WF_ROOTS:-}" ]]; then
  IFS=':' read -ra _wf_roots <<< "$WF_ROOTS"
else
  for d in "$PROJECTS_DIR"/*/workflows; do
    [ -d "$d" ] && _wf_roots+=("$d")
  done
fi
log "Workflow roots: ${_wf_roots[*]:-<none>}"

# --restart: kill existing process and clean stale files so edits are picked up
# if [[ "${1:-}" == "--restart" ]]; then
log "Stopping existing SonataFlow process..."
pkill -f 'java.*quarkus' 2>/dev/null || true

# Wait until the old process is fully gone and port 8899 is free
for _w in $(seq 1 30); do
  if ! pgrep -f 'java.*quarkus' >/dev/null 2>&1; then
    log "Old process terminated after ${_w}s"
    break
  fi
  if [ "$_w" -eq 15 ]; then
    warn "Process still alive after 15s — sending SIGKILL"
    pkill -9 -f 'java.*quarkus' 2>/dev/null || true
  fi
  sleep 1
done

# Ensure port 8899 is free
for _w in $(seq 1 10); do
  if ! curl -sf http://localhost:8899/q/health >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

log "Cleaning workflow resources for fresh copy..."
rm -rf "$WF_DIR/src/main/resources/"* 2>/dev/null || true
rm -rf "$WF_DIR/src/main/java/"* 2>/dev/null || true
rm -rf "$WF_DIR/target/" 2>/dev/null || true
log "Cleaned sources and build cache"

# Truncate old log so health check only sees new process output
: > "$LOG"
# fi

# --- settings.xml: always write a clean file with Red Hat repos and correct proxy ---
mkdir -p /home/kogito/.m2
_proxy_block=""
if [[ -n "${PROXY_HOST:-}" && -n "${PROXY_PORT:-}" ]]; then
  # Strip any accidental http(s):// scheme from the host value
  _ph="${PROXY_HOST#http://}"
  _ph="${_ph#https://}"
  _proxy_block="  <proxies>
    <proxy>
      <id>devspace-proxy</id>
      <active>true</active>
      <protocol>http</protocol>
      <host>${_ph}</host>
      <port>${PROXY_PORT}</port>
      <nonProxyHosts>localhost|127.0.0.1</nonProxyHosts>
    </proxy>
  </proxies>"
  log "Maven proxy configured: ${_ph}:${PROXY_PORT}"
else
  log "Maven proxy: none (PROXY_HOST/PROXY_PORT not set)"
fi

cat > /home/kogito/.m2/settings.xml <<EOF
<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.2.0 https://maven.apache.org/xsd/settings-1.2.0.xsd">
${_proxy_block}
  <profiles>
    <profile>
      <id>redhat-repos</id>
      <repositories>
        <repository>
          <id>redhat-ga</id>
          <url>https://maven.repository.redhat.com/ga/</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>false</enabled></snapshots>
        </repository>
        <repository>
          <id>redhat-earlyaccess</id>
          <url>https://maven.repository.redhat.com/earlyaccess/all/</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>false</enabled></snapshots>
        </repository>
      </repositories>
      <pluginRepositories>
        <pluginRepository>
          <id>redhat-ga-plugins</id>
          <url>https://maven.repository.redhat.com/ga/</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>false</enabled></snapshots>
        </pluginRepository>
        <pluginRepository>
          <id>redhat-earlyaccess-plugins</id>
          <url>https://maven.repository.redhat.com/earlyaccess/all/</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>false</enabled></snapshots>
        </pluginRepository>
      </pluginRepositories>
    </profile>
  </profiles>
  <activeProfiles>
    <activeProfile>redhat-repos</activeProfile>
  </activeProfiles>
</settings>
EOF
log "Wrote clean settings.xml (Red Hat GA + EarlyAccess repos, proxy=$([ -n "${_proxy_block:-}" ] && echo enabled || echo none))"

# Clear cached Maven resolution failures left over from previous bad-proxy runs.
# Maven caches "not found" markers as *.lastUpdated files; stale ones block
# retries even after fixing the settings/network.
log "Clearing stale Maven resolution failure cache (.lastUpdated files)..."
find /home/kogito/.m2/repository -name "*.lastUpdated" -delete 2>/dev/null || true

# --- Merge resources + Java from all workflow roots ---
_any_found=false
for _root in "${_wf_roots[@]}"; do
  [ -d "$_root" ] || { warn "$_root not found — skipping"; continue; }
  _any_found=true
  log "Scanning workflow root: $_root"
  for wf_dir in "$_root"/*/; do
    [ -d "$wf_dir" ] || continue
    wf=$(basename "$wf_dir")
    if [ -d "$wf_dir/src/main/resources" ]; then
      log "Loading resources from $wf ($_root)"
      cp -rf "$wf_dir/src/main/resources/"* "$WF_DIR/src/main/resources/" 2>/dev/null || true
    fi
    if [ -d "$wf_dir/src/main/java" ]; then
      log "Loading Java sources from $wf ($_root)"
      mkdir -p "$WF_DIR/src/main/java"
      cp -rf "$wf_dir/src/main/java/"* "$WF_DIR/src/main/java/" 2>/dev/null || true
    fi
  done
done

if [ "$_any_found" = false ]; then
  warn "No workflow roots found — seeding from examples"
  cp -rf /projects/rhdh-local/orchestrator/workflow-examples/* "$WF_DIR/src/main/resources/" 2>/dev/null || true
fi

# --- Start SonataFlow devmode ---
log "Starting SonataFlow devmode on port 8899..."

# Check if launch script exists
if [ ! -f "/home/kogito/launch/run-app-devmode.sh" ]; then
  warn "Launch script not found: /home/kogito/launch/run-app-devmode.sh"
  ls -la /home/kogito/launch/ 2>&1 | head -20
  exit 1
fi

# Check Java availability
if ! command -v java &> /dev/null; then
  warn "Java command not found in PATH"
  which java || echo "java not in PATH"
  exit 1
fi

cd "$WF_DIR"
log "Working directory: $(pwd)"
log "Maven settings: $HOME/.m2/settings.xml exists? $(test -f "$HOME/.m2/settings.xml" && echo YES || echo NO)"

# Activate the local-dev Quarkus profile so %local-dev.* properties in
# application.properties are resolved (e.g. dev.github.token.override used
# by DevGithubTokenFilter).  Without this the container defaults to the
# built-in "dev" profile and the filter config remains empty.
export QUARKUS_PROFILE=local-dev
log "QUARKUS_PROFILE set to: $QUARKUS_PROFILE"

nohup /home/kogito/launch/run-app-devmode.sh > "$LOG" 2>&1 &
_PID=$!
log "PID=$_PID — logs at $LOG"
log "Waiting for process to write to log..."
sleep 2

# --- Health check (skip only on --no-wait) ---
if [[ "${1:-}" != "--no-wait" ]]; then
  tail -f "$LOG" &
  TAIL_PID=$!
  for i in $(seq 1 900); do
    curl -sf http://localhost:8899/q/health > /dev/null 2>&1 && { kill $TAIL_PID 2>/dev/null; log "UP after $((i*2))s"; exit 0; }
    sleep 2
  done
  kill $TAIL_PID 2>/dev/null
  warn "health check not UP after 1800s (30min) — check $LOG"
else
  log "Skipping health check (--no-wait) — monitor with: tail -f $LOG"
fi
 