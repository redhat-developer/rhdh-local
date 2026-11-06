# rhdh-local

Red Hat Developer Hub (RHDH) Local — a Docker/Podman Compose setup for running RHDH locally for development and testing. Not a substitute for production RHDH; intended for individual developer use on a laptop/desktop.

Everything below is available through the `Makefile`; run `make help` for the full list. Commands default to Podman — pass `TOOL=docker` for Docker. `make lint` runs both linters from pinned container images (`DCLINT_IMAGE`, `SHELLCHECK_IMAGE`), so no Node.js, npx, or host linter installation is required.

## Build & Test Commands

- Start: `make start` (`podman compose up -d`)
- Stop RHDH only: `make stop` (`podman compose stop rhdh`)
- Restart RHDH only, for configuration changes: `make restart`
- Reinstall plugins, then restart RHDH: `make plugins-install`
- Stop and remove all containers: `make down`
- Teardown including volumes: `make clean`
- Compose overlays: `make start OVERLAYS="db orchestrator"` — space-separated names, applied on top of `compose.yaml`, which the Makefile then names explicitly. Available names: `db`, `corporate-proxy`, `dynamic-plugins-root`, `orchestrator`; any `*.yaml` path also works for personal overrides. A local `compose.override.yaml` only applies when `OVERLAYS` is empty.
- Lint tracked compose files and shell scripts: `make lint`

## Verification

CI runs these through `.github/actions/rhdh-local-compose-test/action.yaml`; run whichever covers what you changed. All of the lint checks need only the container engine; the runtime validators need RHDH running plus `yq`, `jq`, and `curl`.

- Compose change: render the config for the overlay you touched, e.g. `podman compose -f compose.yaml -f compose-with-db.yaml config`
- Dynamic plugins actually load (RHDH must be running; needs `yq`, `jq`, `curl`): `./tests/validate-loaded-plugins.sh`
- Intelligent Assistant: `./tests/validate-intelligent-assistant-compose.sh` and `./tests/validate-intelligent-assistant-runtime.sh`
- Single compose file: `podman run --rm -v "$PWD":/app:ro,z -w /app docker.io/zavoloklom/dclint:3.1.0 <file.yaml>`, using the same image as `make lint`
- Single shell script: `podman run --rm -v "$PWD":/app:ro,z -w /app docker.io/koalaman/shellcheck:v0.11.0 <script.sh>`, using the same image as `make lint`

`make lint` and repo-wide dclint only cover git-tracked files. Developer-specific `*.local.yaml` overrides are deliberately not linted, so lint findings never point at files that are not in the repository.

## Key Conventions

<!-- TODO (maintainers): Add 2-3 conventions that an agent couldn't discover by reading the code.
     Examples: naming conventions for compose override files, how *.local.yaml files work,
     how dynamic plugin configs are structured, or how user configs interact with default.env. -->

## Architecture

<!-- TODO (maintainers): Add non-obvious architectural decisions or places where things live
     unexpectedly. Examples: why configs/ is laid out as it is, how compose overlay files
     relate to compose.yaml, how prepare-and-install-dynamic-plugins.sh interacts with
     the dynamic-plugins-root compose variant, or how the wait-for-plugins-and-start.sh
     startup sequence works. -->

## PR Conventions

- Conventional Commits are used: `fix:`, `feat:`, `chore:`, `ci:`, `docs:`, etc.
- Scope examples: `nightly`, `deps`, `lightspeed`, `plugins`
- Agent-assisted commits should include an `Assisted-by: <model>` footer
- Report issues to Jira project RHIDP with Component: **RHDH Local**

## Pattern References

- Compose overlay: see `compose-with-corporate-proxy.yaml` for how to extend `compose.yaml`
- Dynamic plugins config: see files in `configs/dynamic-plugins/` for plugin configuration patterns
- Orchestrator integration: see `orchestrator/compose.yaml` for adding services via overlay
- Shell utility scripts: see `prepare-and-install-dynamic-plugins.sh` and `wait-for-plugins-and-start.sh`
- Local overrides: copy values from `default.env` into `.env` (git-ignored) to pin images, tags, and feature flags instead of editing compose files
- CI verification: see `.github/actions/rhdh-local-compose-test/action.yaml` and `tests/`
- User-facing docs (rendered as TechDocs): see `docs/`, plus `README.md` for the quick commands
