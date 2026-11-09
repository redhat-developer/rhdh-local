# rhdh-local

RHDH Local runs Red Hat Developer Hub on your machine with Docker or Podman Compose — a fast inner loop for catalog entries, TechDocs, templates, app config, and dynamic plugin development. It is a testing and development tool only: not a supported product, not for production, not suitable for teams.

Run `make help` for the full list of targets. Commands default to Podman — pass `TOOL=docker` for Docker.

## Key conventions

- **Branching**: target `dev` for features, docs, and dependency updates; `release-x.y` for bug fixes on a supported release. Do not target `main` — maintainers update it by merge and cherry-pick.
- **Both container tools are supported**: compose changes and documented instructions must work with Podman and Docker, and CI runs the matrix on both. Docs present the pair as TechDocs content tabs (`=== "Podman"` / `=== "Docker"`).
- **Docs are part of the product**: everything under `docs/` is rendered as TechDocs through `mkdocs.yaml`, so a new page also needs a `nav` entry. Restart `rhdh` to preview edits (the mount is read-only, copied into a writable workdir at startup).
- **User configuration is never committed**: `.env`, `configs/**/*.override.yaml`, `configs/**/*.local.yaml`, and `compose.override.yaml` are git-ignored. Change the tracked `*.example.yaml` counterparts instead.
- **`*.example.yaml` files are CI test inputs**: CI copies them verbatim into the corresponding override/local files, so they must parse and work standalone — treat them as code, not documentation.
- **Images and behavior are tuned through environment variables** in `.env`/`default.env`, not by editing compose files.
- **`make effective-compose` output can contain secrets** (it interpolates `.env`) — never paste it into a PR or issue.
- **Lint only covers git-tracked files**. Developer-specific `*.local.yaml` overrides are deliberately excluded.
- **Shell scripts use `set -euo pipefail`** and are checked by ShellCheck in CI — new scripts must follow the same pattern.
- **CI is path-filtered**: lint and test jobs skip when no relevant files changed. If you add a new file type or top-level path, check whether the changed-files filter in the CI workflow covers it — "CI passed" may mean "CI didn't run."

## Architecture

- **Overlay model**: `compose.yaml` is the only base file. Every overlay must be named alongside it — `make … OVERLAYS=…` always passes `-f compose.yaml` first. A local `compose.override.yaml` only applies when `OVERLAYS` is empty.
- **`OVERLAYS` must be consistent across commands**: if you start with `make start OVERLAYS="db orchestrator"`, pass the same `OVERLAYS` to `stop`, `restart`, `logs`, `effective-compose`, `list-services`, and any other target — otherwise the command operates on the base config only and ignores the overlay services.
- **Two-stage startup**: the `install-dynamic-plugins` service runs as root, selects the plugin config, and extracts plugins into the `dynamic-plugins-root` and `extensions-catalog` volumes. The `rhdh` service then blocks until the installer's lock file is gone and execs the Backstage backend as uid 1001.
- **Config layering** (last wins): `app-config.yaml` → `app-config.dynamic-plugins.yaml` → `generated/app-config.patched.yaml` → `app-config.db.yaml` (when `WITH_POSTGRES=true`) → `app-config.local.yaml`.
- **Dynamic plugin configuration replaces, it does not merge**: the selected plugin config file replaces the default plugin list entirely, so start from a copy of the default before adding or removing entries.
- **Orchestrator plugins are a separate step from the overlay**: `make start OVERLAYS=orchestrator` only adds the compose services — the orchestrator's dynamic plugins must be appended to the override file separately (see `orchestrator/README.md`).
- **Tests need a running instance**: scripts in `tests/` assert against a live RHDH through guest auth, not unit tests. They need `yq`, `jq`, and `curl`.
- **Lightspeed configs are generated from upstream** by a scheduled workflow — fix those files upstream rather than hand-editing them.

## Plugin development

Plugin development is a first-class use case. RHDH Local loads dynamic plugins at boot, so a rebuilt plugin runs in a real RHDH UI and backend without publishing to a registry. The full walkthrough is in `docs/rhdh-local-guide/plugins-guide.md`; the key constraints:

- Keep the plugin's `dynamicPlugins` entry in `configs/app-config/app-config.local.yaml`, not in the dynamic plugins override file.
- Files in `local-plugins/` must be readable by the container (uid 1001).
- Exported plugins persist in the `dynamic-plugins-root` volume — run `make clean` before a fresh frontend iteration.

## PR conventions

- Conventional Commits: `fix:`, `feat:`, `chore:`, `ci:`, `docs:`, etc.
- Agent-assisted commits include an `Assisted-by: <model>` footer.
- Always follow the PR template in `.github/PULL_REQUEST_TEMPLATE.md` — keep all sections and either tick each checklist item or say why it does not apply.
- Report issues to Jira project RHIDP with Component: **RHDH Local**.
