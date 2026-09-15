# Maintaining Developer Hub Intelligent Assistant

This guide is for maintainers of the Developer Hub Intelligent Assistant integration within RHDH Local. It covers syncing upstream configuration files, overriding images, OKP document retrieval, tuning resources, and understanding the service architecture.

For user-facing setup instructions (configuring LLM providers, troubleshooting, etc.), see [Working with Developer Hub Intelligent Assistant](./working-with-intelligent-assistant.md).

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Syncing Lightspeed Configuration Files](#syncing-lightspeed-configuration-files)
3. [Overriding the Lightspeed Core Image](#overriding-the-lightspeed-core-image)
4. [Overriding the OKP Image](#overriding-the-okp-image)
5. [Increasing Container Runtime Memory](#increasing-container-runtime-memory)

---

## Architecture Overview

Developer Hub Intelligent Assistant runs as part of the default RHDH Local compose stack with the following services:

- **rhdh** -- The main Red Hat Developer Hub container, which includes the Developer Hub Intelligent Assistant frontend and backend dynamic plugins.
- **lightspeed-core** -- Runs Lightspeed Core with the unified embedded stack configuration. Uses `network_mode: service:rhdh` to share the network namespace with the RHDH container. Depends on `rhdh` and a healthy `okp` service.
- **okp** -- Runs Offline Knowledge Portal as a separate Solr and httpd workload. It replaces the pre-built FAISS RAG content container and provides Red Hat product documentation over HTTP.
- **install-dynamic-plugins** -- Installs dynamic plugins (including Developer Hub Intelligent Assistant plugins) into a shared volume.

### Key Configuration Files

| File | Purpose |
|------|---------|
| `configs/extra-files/lightspeed-stack.yaml` | Tracked unified Lightspeed Core config, including OKP retrieval (synced from upstream). Do not edit to enable providers. |
| `configs/extra-files/lightspeed-stack-no-okp.yaml` | Generated tracked variant with the top-level `rag` section removed. Used when running Intelligent Assistant without OKP. |
| `configs/extra-files/lightspeed-stack.local.yaml` | Gitignored overlay. Copy `lightspeed-stack.yaml` here, uncomment providers, and set `LIGHTSPEED_STACK_CONFIG` in `.env`. Sync does **not** touch this file. |
| `configs/extra-files/rhdh-profile.py` | Python profile with system prompts and response templates |
| `configs/extra-files/templates/placeholder.json` | Placeholder for Vertex AI GCP credentials bind mount |
| `configs/dynamic-plugins/dynamic-plugins.yaml` | Default dynamic plugins config (includes Developer Hub Intelligent Assistant plugin entries) |
| `configs/app-config/app-config.yaml` | Main RHDH app-config (includes Developer Hub Intelligent Assistant plugin settings and CSP) |

### Volumes

| Volume | Purpose |
|--------|---------|
| `dynamic-plugins-root` | Installed dynamic plugins shared between installer and RHDH |
| `extensions-catalog` | Extensions catalog entities |

---

## Syncing Lightspeed Configuration Files

The Lightspeed Core configuration files (`rhdh-profile.py`, `lightspeed-stack.yaml`) are maintained upstream in the [redhat-ai-dev/lightspeed-configs](https://github.com/redhat-ai-dev/lightspeed-configs) repository. The sync script downloads them into `configs/extra-files/`.

**Sync from default (main branch):**
```bash
bash ./scripts/sync-lightspeed-configs.sh
```

**Sync from a specific ref:**
```bash
bash ./scripts/sync-lightspeed-configs.sh --ref v1.0.0
```

**Sync from a different repository:**
```bash
bash ./scripts/sync-lightspeed-configs.sh --repo your-org/your-fork
```

**Check if local files are up to date (dry run):**
```bash
bash ./scripts/sync-lightspeed-configs.sh --check
```

The sync script fetches upstream `lightspeed-stack.yaml` and `rhdh-profile.py`. It does **not** touch gitignored `lightspeed-stack.local.yaml`. After sync, recopy the tracked stack file if you want upstream changes plus your uncommented providers:

```bash
cp configs/extra-files/lightspeed-stack.yaml \
   configs/extra-files/lightspeed-stack.local.yaml
# then re-uncomment provider blocks
```

The tracked `lightspeed-stack.yaml` is copied verbatim from upstream. The current upstream `main` configuration includes the active OKP RAG configuration used by this integration.

Compose mounts `${LIGHTSPEED_STACK_CONFIG:-./configs/extra-files/lightspeed-stack.yaml}`. Presence of `lightspeed-stack.local.yaml` does not change the in-container config until `.env` sets `LIGHTSPEED_STACK_CONFIG=./configs/extra-files/lightspeed-stack.local.yaml`.

The sync script also derives `lightspeed-stack-no-okp.yaml` by removing the top-level `rag` section. `compose.okp-disabled.override.example.yaml` mounts that variant and disables the OKP service. A user-specific no-OKP provider configuration should be named `lightspeed-stack-no-okp.local.yaml` and selected with `LIGHTSPEED_STACK_NO_OKP_CONFIG`; sync does not touch local files.

---

## Overriding the Lightspeed Core Image

By default, the compose setup uses `quay.io/lightspeed-core/lightspeed-stack:dev-20260824-cbd182b`. To use a different image (e.g., a newer version or a custom build), set the `LIGHTSPEED_CORE_IMAGE` environment variable in your `.env` file:

```env
LIGHTSPEED_CORE_IMAGE=quay.io/lightspeed-core/lightspeed-stack:dev-20260824-cbd182b
```

---

## Overriding the OKP Image

The default OKP image is pinned in `compose.yaml`. Authenticate with `registry.redhat.io` before starting the stack. To test another build, set `OKP_IMAGE` in `.env`:

```env
OKP_IMAGE=registry.redhat.io/offline-knowledge-portal/rhokp-rhel9:1.2.12-1788274041
```

Lightspeed Core reaches OKP through the host-published endpoint at `http://host.docker.internal:8081`. LCORE also uses this URL as the base for browser-facing citation links. Port `8081` exposes the OKP httpd endpoint on the host (`http://localhost:8081`), while `8983` exposes Solr for local diagnostics. Override `OKP_SERVICE_URL` in `.env` when the default hostname is not reachable from both the container and browser.

---

## Increasing Container Runtime Memory

OKP and Lightspeed Core increase the local environment's memory usage. If containers are terminated due to insufficient memory, increase the memory allocated to the Podman or Docker virtual machine. Actual requirements depend on the enabled services and workload. For example:

```bash
podman machine stop
podman machine set --memory=8192
podman machine start
```

- The example above sets the memory to **8 GiB** (`8192` MB); it is not a validated minimum requirement.
- Adjust the value as needed (e.g., `--memory=16384` for 16 GiB). OKP's Solr process is configured with a 1 GiB Java heap.
- Ensure your host system has enough free RAM.

After increasing the memory, restart your containers to use the new limits.
