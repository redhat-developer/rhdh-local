# rhdh-local

RHDH Local runs Red Hat Developer Hub on your machine with Docker or Podman Compose — a fast inner loop for catalog entries, TechDocs, templates, app config, and dynamic plugin development. It is a testing and development tool only: not a supported product, not for production, not suitable for teams.

Everything below is available through the `Makefile`; run `make help` for the full list. Commands default to Podman — pass `TOOL=docker` for Docker. `make lint` runs both linters from pinned container images (`DCLINT_IMAGE`, `SHELLCHECK_IMAGE`), so no Node.js, npx, or host linter installation is required.

## Build & Test Commands

- Start: `make start` (`podman compose up -d`)
- Stop RHDH only: `make stop` (`podman compose stop rhdh`)
- Restart RHDH only, for configuration changes: `make restart`
- Follow logs for all services, or one: `make logs` / `make logs SERVICE=rhdh`
- Inspect the setup: `make ps` (all containers, stopped included), `make list-services` (service names), `make effective-compose` (merged config)
- Reinstall plugins, then restart RHDH: `make plugins-install`
- Stop and remove all containers: `make down`
- Teardown including volumes: `make clean`
- Full reset, including every pulled image (runtime and lint, they download again on next use): `make reset`
- Compose overlays: `make start OVERLAYS="db orchestrator"` — space-separated names, applied on top of `compose.yaml`, which the Makefile then names explicitly. Available names: `db`, `corporate-proxy`, `dynamic-plugins-root`, `orchestrator`; any `*.yaml` path also works for personal overrides. A local `compose.override.yaml` only applies when `OVERLAYS` is empty.
- Lint tracked compose files and shell scripts: `make lint`

## Verification

CI runs these through `.github/actions/rhdh-local-compose-test/action.yaml`; run whichever covers what you changed. All of the lint checks need only the container engine; the runtime validators need RHDH running plus `yq`, `jq`, and `curl`.

- Compose change: render the config for the overlay you touched, e.g. `make effective-compose OVERLAYS=db` (or `make list-services OVERLAYS=db` to check which services it adds). Because it interpolates `.env`, `make effective-compose` output can contain secrets — never paste it into a PR or issue.
- Dynamic plugins actually load (RHDH must be running; needs `yq`, `jq`, `curl`): `./tests/validate-loaded-plugins.sh`
- Intelligent Assistant: `./tests/validate-intelligent-assistant-compose.sh` and `./tests/validate-intelligent-assistant-runtime.sh`
- Single compose file: `podman run --rm -v "$PWD":/app:ro,z -w /app docker.io/zavoloklom/dclint:3.1.0 <file.yaml>`, using the same image as `make lint`
- Single shell script: `podman run --rm -v "$PWD":/app:ro,z -w /app docker.io/koalaman/shellcheck:v0.11.0 <script.sh>`, using the same image as `make lint`

`make lint` and repo-wide dclint only cover git-tracked files. Developer-specific `*.local.yaml` overrides are deliberately not linted, so lint findings never point at files that are not in the repository.

## Key Conventions

- **Branching**: `main` is the latest stable GA release, `dev` carries development for the next release, `release-x.y` stabilizes a release and takes its patch fixes. Target `dev` for features, docs, and dependency updates; `release-x.y` for bug fixes on a supported release; do not target `main`, which maintainers update by merge and cherry-pick. `.github/workflows/branch-target-check.yaml` comments a warning on every PR opened against `main`.
- **Docs are part of the product**: everything under `docs/` is rendered as TechDocs through `mkdocs.yaml`, so a new page also needs a `nav` entry. `docs/`, `mkdocs.yaml`, and `catalog-info.yaml` are mounted read-only and copied into a writable workdir at startup, so restart `rhdh` to preview edits.
- **User configuration is never committed**: `.env`, `configs/**/*.override.yaml`, `configs/**/*.local.yaml`, and `compose.override.yaml` are git-ignored. Change the tracked `*.example.yaml` counterparts instead; CI's "user config" matrix copies them into place verbatim, so they must stay valid and self-contained.
- **Dynamic plugin configuration replaces, it does not merge**: `configs/dynamic-plugins/dynamic-plugins.override.yaml` wins over the deprecated `configs/dynamic-plugins.yaml`, which wins over `configs/dynamic-plugins/dynamic-plugins.yaml`. The selected file replaces the default plugin list entirely, so start from a copy of the default before adding or removing entries.
- **Plugins under development**: keep the plugin's `dynamicPlugins` entry in `configs/app-config/app-config.local.yaml`, not in `dynamic-plugins.override.yaml`. See [Plugin Development](#plugin-development) for the export, iteration, and debug loops.
- **Both container tools are supported**: compose changes and documented instructions must work with Podman and Docker, and CI runs the matrix on both. Docs present the pair as TechDocs content tabs (`=== "Podman"` / `=== "Docker"`).
- **Images and behavior are tuned through environment variables**: pin `RHDH_IMAGE`, `CATALOG_INDEX_IMAGE`, `LIGHTSPEED_CORE_IMAGE`, `WITH_POSTGRES`, and similar in `.env`/`default.env` instead of editing `compose*.yaml`.
- **Baseline plugins**: `tests/required-plugins.yaml` lists plugins that must load regardless of configuration; `tests/validate-loaded-plugins.sh` fails when one disappears.

## Architecture

- `compose.yaml` is the only base file. Each capability is an overlay that has to be named alongside it: `compose-with-db.yaml` (PostgreSQL), `compose-with-corporate-proxy.yaml`, `compose-dynamic-plugins-root.yaml`, `orchestrator/compose.yaml`, `intelligent-assistant/compose-with-okp.yaml`. `make … OVERLAYS=…` always passes `-f compose.yaml` first.
- Startup is two-stage. `install-dynamic-plugins` runs `prepare-and-install-dynamic-plugins.sh` as root, selects the plugin config, and extracts plugins into the `dynamic-plugins-root` and `extensions-catalog` volumes. `rhdh` then runs `wait-for-plugins-and-start.sh` as uid 1001, blocks until the installer's lock file is gone, and execs the Backstage backend.
- Runtime config layering, last one wins: base `app-config.yaml` → generated `app-config.dynamic-plugins.yaml` → `generated/app-config.patched.yaml` → `configs/app-config/app-config.db.yaml` when `WITH_POSTGRES=true` → `configs/app-config/app-config.local.yaml`. The patched copy only rewrites the users catalog path; components are referenced directly by the base config.
- `configs/` is bind-mounted whole at `/opt/app-root/src/configs`; `generated/` is runtime output and git-ignored. `local-plugins/` holds local plugin artifacts and is git-ignored apart from its `.gitignore`, and `dynamic-plugins-root` is a named volume used as the plugin cache.
- Optional components live in self-contained directories: `orchestrator/` (compose file, configs, workflow examples, and a README that explains adding its plugins to the override file) and `intelligent-assistant/` (OKP overlay).
- `tests/` is not a unit-test suite: each script asserts against a running instance through guest auth and `/api/extensions/loaded-plugins`, and needs `yq`, `jq`, and `curl`. CI invokes the same scripts from `.github/actions/rhdh-local-compose-test/action.yaml`.
- Intelligent Assistant config in `configs/extra-files/lightspeed-stack*.yaml` and `rhdh-profile.py` is generated from upstream by `scripts/sync-lightspeed-configs.sh`, which a scheduled workflow runs; fix those files upstream rather than hand-editing them.

## Plugin Development

Plugin development is a first-class use case, not an afterthought: RHDH Local loads dynamic plugins at boot, so a rebuilt plugin runs in a real RHDH UI and backend without publishing to a registry or deploying to a cluster. The full walkthrough is `docs/rhdh-local-guide/plugins-guide.md`; the short version:

- **Load an exported plugin**: put the package in `local-plugins/` (mounted at `/opt/app-root/src/local-plugins` and loaded without downloading) or copy `dist-dynamic` into the `dynamic-plugins-root` volume, then reference it from the plugin config. Files must be readable by the container — `chmod -R 777 local-plugins` for quick tests.
- **Frontend iteration**: `npx @red-hat-developer-hub/cli@latest plugin export --dev --dynamic-plugins-root <rhdh-local>/dynamic-plugins-root`, start with `make start OVERLAYS=dynamic-plugins-root`, and keep the plugin's `dynamicPlugins` entry in `configs/app-config/app-config.local.yaml`. After a code change, re-run the export and refresh the browser — no container restart.
- **Backend debugging**: copy `dist-dynamic` into the running container (`podman cp dist-dynamic rhdh:/opt/app-root/src/dynamic-plugins-root/<plugin>`), `make restart`, and attach a Node debugger to port 9229 with `remoteRoot` at that in-container path and `localRoot` at the plugin source. Repeat copy + restart after each rebuild.
- **Start clean** before a frontend iteration — `make clean` (`down --volumes`) — because exported plugins persist in the `dynamic-plugins-root` volume.

## PR Conventions

- Conventional Commits are used: `fix:`, `feat:`, `chore:`, `ci:`, `docs:`, etc.
- Scope examples: `nightly`, `deps`, `lightspeed`, `plugins`
- Agent-assisted commits should include an `Assisted-by: <model>` footer
- **Always follow the PR template**: `.github/PULL_REQUEST_TEMPLATE.md` — keep all of its sections (description, related issue, acceptance criteria checklist, how to test) and either tick each checklist item or say why it does not apply. GitHub prefills it in the web UI, but a `gh pr create` body has to reproduce it.
- Report issues to Jira project RHIDP with Component: **RHDH Local**

## Pattern References

- Compose overlay: see `compose-with-corporate-proxy.yaml` for how to extend `compose.yaml`
- Dynamic plugins config: see files in `configs/dynamic-plugins/` for plugin configuration patterns
- Orchestrator integration: see `orchestrator/compose.yaml` for adding services via overlay, and `orchestrator/README.md` for registering its plugins
- Shell utility scripts: see `prepare-and-install-dynamic-plugins.sh` and `wait-for-plugins-and-start.sh`
- Plugin development walkthrough: `docs/rhdh-local-guide/plugins-guide.md` (export, debug, local overrides) and `docs/rhdh-local-guide/dynamic-plugins-management.md` (catalog index, Extensions UI)
- Day-to-day operations and troubleshooting: `docs/rhdh-local-guide/operating-rhdh-local.md`
- Local overrides: copy values from `default.env` into `.env` (git-ignored) to pin images, tags, and feature flags instead of editing compose files
- CI verification: see `.github/actions/rhdh-local-compose-test/action.yaml` and `tests/`
- User-facing docs (rendered as TechDocs): see `docs/`, plus `README.md` for the quick commands
