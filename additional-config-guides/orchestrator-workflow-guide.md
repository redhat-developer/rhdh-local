## Testing Orchestrator and Workflow Examples

To set up the infrastructure for developing workflow with Orchestrator, run the following command below to merge
[`compose.yaml`](./compose.yaml) and [`compose-with-orchestrator.yaml`](compose-with-orchestrator.yaml) configs.

Example with `podman-compose` (note that the order of the YAML files is important):
```sh
podman-compose \
   -f compose.yaml \
   -f compose-with-orchestrator.yaml \
   up -d
```
Ensure to copy the orchestrator dynamic plugins from `dynamic-plugins-orchestrator.yaml` to your `dynamic-plugins.override.yaml`
to enable orchestrator plugins within RHDH.

There are two workflow examples to get you started on testing Orchestrator workflow with RHDHO Local.

1. In the project root, `rhdho-workflow-examples` folder contains example workflows and by default, it is already
   mounted
   to
   `/home/kogito/serverless-workflow-project/src/main/resources` for SonataFlow configuration in the compose.yaml. The
   directory contains three workflows; greeting, slack and github. For more information about the workflow and setup,
   refer to this
   [link](rhdho-workflow-examples/README.md).

2. A suite of workflows exists in
   this [backstage-orchestrator-workflows](https://github.com/rhdhorchestrator/backstage-orchestrator-workflows/tree/main/workflows).
   Clone the repository to your local and update the mount directory (value of `sonataflow.volume`) in `compose.yaml`
   file to point to your local `backstage-orchestrator-workflows` directory.
   Note: While developing workflow and after making changes to your resources, the pages might error out. Reloading the
   page (a couple of times) may fix it. Otherwise, you may have to restart the `sonataflow` pod by running:
```shell
   podman-compose stop sonataflow && podman-compose start sonataflow. 
```
This is a known issue.