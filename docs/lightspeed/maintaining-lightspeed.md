# Maintaining Developer Lightspeed

This guide is for maintainers of the Developer Lightspeed integration within RHDH Local. It covers syncing upstream configuration files, overriding images, tuning resources, and understanding the service architecture.

For user-facing setup instructions (configuring LLM providers, troubleshooting, etc.), see [Working with Lightspeed](./working-with-lightspeed.md).

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Syncing Lightspeed Configuration Files](#syncing-lightspeed-configuration-files)
3. [Overriding the Lightspeed Core Image](#overriding-the-lightspeed-core-image)
4. [Increasing Container Runtime Memory](#increasing-container-runtime-memory)

---

## Architecture Overview

Developer Lightspeed runs as part of the default RHDH Local compose stack with the following services:

- **rhdh** -- The main Red Hat Developer Hub container, which includes the Lightspeed frontend and backend dynamic plugins.
- **lightspeed-core** -- Runs both Lightspeed Core and Llama Stack in a single container (library mode). Uses `network_mode: service:rhdh` to share the network namespace with the RHDH container. Depends on `rhdh` (started) and `rag-init` (completed).
- **rag-init** -- An init container that copies RAG embeddings and vector database files from a pre-built image into shared volumes (`rag_embeddings`, `rag_vector_db`). Runs once at startup and exits.
- **install-dynamic-plugins** -- Installs dynamic plugins (including Lightspeed plugins) into a shared volume.

### Key Configuration Files

| File | Purpose |
|------|---------|
| `configs/extra-files/lightspeed-stack.yaml` | Lightspeed Core HTTP service config (port, auth, MCP, customization) |
| `configs/extra-files/config.yaml` | Llama Stack v3 distro config (inference providers, RAG, safety/validation) |
| `configs/extra-files/rhdh-profile.py` | Python profile with system prompts and response templates |
| `configs/extra-files/templates/placeholder.json` | Placeholder for Vertex AI GCP credentials bind mount |
| `configs/dynamic-plugins/dynamic-plugins.yaml` | Default dynamic plugins config (includes Lightspeed plugin entries) |
| `configs/app-config/app-config.yaml` | Main RHDH app-config (includes Lightspeed plugin settings and CSP) |

### Volumes

| Volume | Purpose |
|--------|---------|
| `rag_embeddings` | Sentence-transformer embedding model files, populated by `rag-init` |
| `rag_vector_db` | FAISS vector database with RHDH product docs, populated by `rag-init` |
| `dynamic-plugins-root` | Installed dynamic plugins shared between installer and RHDH |
| `extensions-catalog` | Extensions catalog entities |

---

## Syncing Lightspeed Configuration Files

The Lightspeed Core configuration files (`config.yaml`, `rhdh-profile.py`, `lightspeed-stack.yaml`) are maintained upstream in the [redhat-ai-dev/lightspeed-configs](https://github.com/redhat-ai-dev/lightspeed-configs) repository. The sync script downloads them into `configs/extra-files/`.

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

---

## Overriding the Lightspeed Core Image

By default, the compose setup uses `quay.io/lightspeed-core/lightspeed-stack:0.5.1`. To use a different image (e.g., a newer version or a custom build), set the `LIGHTSPEED_CORE_IMAGE` environment variable in your `.env` file:

```env
LIGHTSPEED_CORE_IMAGE=quay.io/lightspeed-core/lightspeed-stack:0.6.0
```

---

## Increasing Container Runtime Memory

If you encounter out-of-memory issues with the Lightspeed Core container, you can increase the memory available to your Podman or Docker virtual machine:

```bash
podman machine stop
podman machine set --memory=8192
podman machine start
```

- The example above sets the memory to **8 GiB** (`8192` MB).
- Adjust the value as needed (e.g., `--memory=16384` for 16 GiB).
- Ensure your host system has enough free RAM.

After increasing the memory, restart your containers to use the new limits.
