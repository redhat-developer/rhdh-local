This guide explains how to run this repository in OpenShift Dev Spaces using the workspace [devfile.yaml](../../devfile.yaml).

## What This Devfile Provides

The workspace starts three main containers:

- `tools`: Backstage and plugin development tasks
- `rhdh`: Red Hat Developer Hub runtime
- `sonataflow`: SonataFlow workflow runtime

It also provisions persistent volumes for dynamic plugins, generated assets, Maven cache, and workspace projects.

## Prerequisites

Before using this devfile, ensure you have:

1. Access to an OpenShift cluster with Dev Spaces installed
2. Permissions to create Dev Spaces workspaces
3. Network access to required image registries
4. Enough cluster resources (recommended: at least 2 CPU and 6Gi memory for each main runtime container)

## Create A Workspace From This Devfile

1. Open Dev Spaces and create a workspace from your fork/branch of this repository.
2. Make sure the workspace uses [devfile.yaml](../../devfile.yaml).
3. Start the workspace.

The post-start event runs command `start-rhdh`, which calls:

```bash
/projects/rhdh-local/scripts/start-rhdh.sh
```

This script prepares config links, dynamic plugin layout, and starts the RHDH backend.

## Endpoints Exposed By The Workspace

- RHDH UI/API: endpoint `rhdh` on port `7007`
- Plugin dev frontend: endpoint `webpack-dev` on port `3000`
- Plugin dev backend: endpoint `backstage-dev` on port `7008`
- SonataFlow: endpoint `sonataflow` on port `8899`
- Node inspector (internal): endpoint `node-debug` on port `9229`

## Command Reference

The following commands are defined in [devfile.yaml](../../devfile.yaml):

### RHDH Infrastructure

- `start-rhdh`: Starts RHDH asynchronously via `scripts/start-rhdh.sh` and writes status into `/tmp/rhdh-status`.
- `restart-rhdh`: Stops any process bound to port `7007` and starts RHDH again.

### Plugin Development

- `develop-backstage-plugin`: Scaffolds a Backstage app and frontend plugin in `/projects`.
- `start-plugin-dev`: Starts plugin dev mode and patches ports to avoid conflict with RHDH.
- `deploy-dynamic-plugin`: Builds and exports your plugin into a detected dynamic plugins root.

### SonataFlow

- `start-sonataflow`: Starts SonataFlow runtime.
- `restart-sonataflow`: Restarts SonataFlow runtime by freeing port `8899` and relaunching.

SonataFlow does not start automatically. Start it after RHDH is up and running by running the `start-sonataflow` task in the terminal. The first startup can take about 15 minutes, and subsequent restarts usually take around 2 minutes.

## Typical Development Flows

### Flow 1: Start And Validate RHDH

1. Start the workspace.
2. Wait for `start-rhdh` to complete.
3. Open the `rhdh` public endpoint.
4. Confirm the RHDH home page loads.

If startup fails, check:

```bash
cat /tmp/rhdh-status
cat /tmp/rhdh-start.log
```

### Flow 2: Build And Test A Dynamic Plugin

1. Run `develop-backstage-plugin` once (per new workspace).
2. Run `start-plugin-dev` during active plugin coding.
3. Run `deploy-dynamic-plugin` after code changes you want to test in RHDH.
4. Run `restart-rhdh` to reload backend and plugin wiring.
5. Open the RHDH route and test your plugin page.

### Flow 3: Work With SonataFlow

1. Run `start-sonataflow` to launch workflows.
2. Use `restart-sonataflow` after workflow or config changes.
3. Validate on the SonataFlow endpoint.

## Configuration Notes

- Default environment variables are defined in [devfile.yaml](../../devfile.yaml).
- RHDH startup behavior is controlled by [scripts/start-rhdh.sh](../../scripts/start-rhdh.sh).
- RHDH app config and dynamic plugin files are sourced from [configs](../../configs).
- Plugin defaults are:
  - `BACKSTAGE_APP_NAME=backstage`
  - `BACKSTAGE_APP_DIR=/projects/backstage`
  - `PLUGIN_NAME=hello-world`

## Troubleshooting

### Post-start does not launch RHDH

- Confirm the event exists:
  - `events.postStart: start-rhdh`
- Confirm command id exists:
  - `commands[].id: start-rhdh`

### Script permission errors

Run:

```bash
chmod +x /projects/rhdh-local/scripts/start-rhdh.sh
```

### RHDH not reachable

1. Check `rhdh` container logs.
2. Check `/tmp/rhdh-start.log` in the `rhdh` container.
3. Run `restart-rhdh`.

### Port conflicts during plugin dev

- `start-plugin-dev` adjusts the plugin backend to `7008`.
- Keep RHDH on `7007`.

### Dynamic plugin not visible in RHDH

1. Re-run `deploy-dynamic-plugin`.
2. Re-run `restart-rhdh`.
3. Verify plugin export succeeded and target dynamic root exists.

### To download private repository plugins, create a Kubernetes secret in the format below

When the RHDH startup script runs, it reads this secret, creates an `.npmrc` file, and uses it to download private repository plugins.

```yaml
kind: Secret
apiVersion: v1
metadata:
  name: rhdh-secrets
  namespace: <namespace>
  labels:
    controller.devfile.io/mount-to-devworkspace: "true"
    controller.devfile.io/watch-secret: "true"
  annotations:
    controller.devfile.io/mount-as: env
stringData:
  # ── NPM Registry Configuration ──────────────────────────────────────────
  # The .npmrc content with all registry mappings and auth tokens.
  NPMRC_CONTENT_B64:
    | # Replace <YOUR_JFROG_TOKEN> in the .npmrc content below
    registry=https://registry.npmjs.org/
    @redhat:registry=https://npm.registry.redhat.com
    @cloudtooling:registry=https://jfrog.ford.com/artifactory/api/npm/cloudtooling-npm-repository/
    //jfrog.com/artifactory/api/npm/npmjs/:_authToken=<YOUR_JFROG_TOKEN>
    //jfrog.com/artifactory/api/npm/cloudtooling-npm-repository/:_authToken=<YOUR_JFROG_TOKEN>
type: Opaque
```

## Recommended Next Steps

- Add this page to your onboarding checklist for Dev Spaces users.
- Keep command ids stable in [devfile.yaml](../../devfile.yaml) to prevent event wiring issues.
- If you rename scripts under [scripts](../../scripts), update all related command paths in [devfile.yaml](../../devfile.yaml).
