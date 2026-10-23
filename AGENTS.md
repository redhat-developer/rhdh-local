# rhdh-local

Red Hat Developer Hub (RHDH) Local — a Docker/Podman Compose setup for running RHDH locally for development and testing. Not a substitute for production RHDH; intended for individual developer use on a laptop/desktop.

## Build & Test Commands

- Start: `podman compose up -d` (or `docker compose up -d`)
- Stop RHDH only: `podman compose stop rhdh`
- Stop all: `podman compose down`
- Teardown (including volumes): `podman compose down --volumes`
- Reinstall plugins then restart RHDH: `podman compose run install-dynamic-plugins && podman compose stop rhdh && podman compose start rhdh`
- Lint all compose files: `npx dclint .`
- Lint single compose file: `npx dclint <file.yaml>`
- Lint shell scripts: `shellcheck *.sh`
- Lint single shell script: `shellcheck <script.sh>`

## Single-File Verification

- Compose/YAML file: `npx dclint <file.yaml>`
- Shell script: `shellcheck <script.sh>`

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
