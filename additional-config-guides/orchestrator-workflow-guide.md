## Setup Orchestrator and Workflow Examples

Before you begin, ensure to copy the orchestrator dynamic plugins from `dynamic-plugins-orchestrator.yaml` to your
`dynamic-plugins.override.yaml`
to enable orchestrator plugins within RHDH.

To set up the infrastructure for developing workflow with Orchestrator, you must merge and run these two compose files:
[`compose.yaml`](./compose.yaml) and [`compose-with-orchestrator.yaml`](compose-with-orchestrator.yaml) configs.

> **NOTE**: You must log in to RedHat Registry to use the Sonataflow dev image. To get an account,
> check [Red Hat Login](https://access.redhat.com/RegistryAuthentication#getting-a-red-hat-login-2).

To get started, run the command below or override the `RHDH_ORCHESTRATOR_WORKFLOWS` variable in your `.env` file to
point to your local workflow development directory before running the command.

```shell
podman compose -f compose.yaml -f orchestrator/compose.yaml up -d
```

To make custom changes/configuration, it is recommended to use a `compose-orchestrator.local.yaml` by merging
`compose.yaml` and `orchestrator/compose.yaml` to prevent conflicts with version controlled files.

Run this command to merge compose files:

```shell
podman compose -f compose.yaml -f orchestrator/compose.yaml config >> compose-orchestrator.local.yaml
```

And this command to spin up the containers:

```sh
podman compose \
   -f compose-orchestrator.local.yaml \
   up -d
```

There are three workflow examples to get you started on testing Orchestrator workflow with RHDH Local.

1. In the project root, `rhdho-workflow-examples` folder contains example workflows and by default, it is already
   mounted
   to
   `/home/kogito/serverless-workflow-project/src/main/resources` for SonataFlow configuration in your
   `compose-orchestrator.local.yaml`. The
   directory contains three workflows; greeting, slack and github. For more information about the workflow and setup,
   refer to this
   [link](rhdho-workflow-examples/README.md).

2. A suite of workflows exists in
   this [backstage-orchestrator-workflows](https://github.com/rhdhorchestrator/backstage-orchestrator-workflows/tree/main/workflows).
   Clone the repository to your local and override the mount directory `RHDH_ORCHESTRATOR_WORKFLOWS` in your
   `.env` file
   file to point to your local `backstage-orchestrator-workflows` directory.
   Note: While developing workflow and after making changes to your resources, the pages might error out. Reloading the
   page (a couple of times) may fix it. Otherwise, you may have to restart the `sonataflow` pod by running:

```shell
   podman compose stop sonataflow && podman compose start sonataflow. 
```

This is a known issue.