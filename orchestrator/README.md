# Setup Orchestrator and Workflow Examples

> **Note:** All instructions in this guide apply to both Podman and Docker.
> Replace `podman compose` with `docker compose` if you are using Docker.

Before you begin, ensure to add the orchestrator plugins to your `configs/dynamic-plugins/dynamic-plugins.override.yaml` to enable them within RHDH.
Copy the [plugins](./configs/dynamic-plugins/dynamic-plugins.yaml#L5-L21)
from `orchestrator/configs/dynamic-plugins/dynamic-plugins.yaml` directly into your override file. Example:

```yaml
includes:
  - dynamic-plugins.default.yaml

# Add the Orchestrator plugins directly, and add any other plugins you want to install, including local ones.
plugins:
  - package: 'oci://registry.access.redhat.com/rhdh/red-hat-developer-hub-backstage-plugin-orchestrator:{{inherit}}'
    disabled: false
  - package: 'oci://registry.access.redhat.com/rhdh/red-hat-developer-hub-backstage-plugin-orchestrator-backend:{{inherit}}'
    disabled: false
    pluginConfig:
      orchestrator:
        dataIndexService:
          url: http://sonataflow:8899
  - package: 'oci://registry.access.redhat.com/rhdh/red-hat-developer-hub-backstage-plugin-scaffolder-backend-module-orchestrator:{{inherit}}'
    disabled: false
    pluginConfig:
      orchestrator:
        dataIndexService:
          url: http://sonataflow:8899
  - package: 'oci://registry.access.redhat.com/rhdh/red-hat-developer-hub-backstage-plugin-orchestrator-form-widgets:{{inherit}}'
    disabled: false
```

> **Warning:** Do **not** use the `includes` directive to reference `orchestrator/configs/dynamic-plugins/dynamic-plugins.yaml`.
> Due to a [known issue (RHDHBUGS-2779)](https://redhat.atlassian.net/browse/RHDHBUGS-2779), using `includes` for the orchestrator
> dynamic plugins file prevents the Orchestrator profile from starting correctly.

To set up the infrastructure for developing workflow with Orchestrator, you must merge and run these two compose files:
[`compose.yaml`](../compose.yaml) and [`orchestrator/compose.yaml`](./compose.yaml) configs.

To get started, run the command below or override the `RHDH_ORCHESTRATOR_WORKFLOWS` variable in your `.env` file to
point to your local workflow development directory before running the command.

```shell
podman compose -f compose.yaml -f orchestrator/compose.yaml up -d
```

To make custom changes/configuration to the compose configuration, it is recommended to use a `compose-orchestrator.local.yaml` by merging the default `compose.yaml` and `orchestrator/compose.yaml` to prevent conflicts with version-controlled files.

Run this command to merge compose files:

```shell
# NOTE: this will overwrite your existing compose-orchestrator.local.yaml file, if any
podman compose -f compose.yaml -f orchestrator/compose.yaml config > compose-orchestrator.local.yaml
```

And this command to spin up the containers:

```sh
podman compose -f compose-orchestrator.local.yaml up -d
```

There are three workflow examples to get you started on testing Orchestrator workflow with RHDH Local.

1. The [`orchestrator/workflow-examples`](./workflow-examples/) folder contains example workflows and by default, it is already mounted to `/home/kogito/serverless-workflow-project/src/main/resources` for SonataFlow configuration in the `orchestrator/compose.yaml`. The directory contains three workflows: greeting, slack and github. For more information about the workflow and setup, refer to this [README](./workflow-examples/README.md).

2. A suite of workflows exists in this [backstage-orchestrator-workflows](https://github.com/rhdhorchestrator/backstage-orchestrator-workflows/tree/main/workflows). Feel free to clone the repository to your local and override the mount directory `RHDH_ORCHESTRATOR_WORKFLOWS` in your `.env` file to point to your local `backstage-orchestrator-workflows` directory.
   **Note**: While developing workflows and after making changes to your resources, the pages might error out. Reloading the
   page (a couple of times) may fix it. Otherwise, you may have to restart the `sonataflow` pod by running the command below. This is a **known issue**.

   ```shell
      podman compose -f compose.yaml -f orchestrator/compose.yaml restart sonataflow
   ```
