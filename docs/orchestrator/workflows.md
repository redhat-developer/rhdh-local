# Orchestrator Workflows in RHDH Local

There are three workflow examples to get you started on testing Orchestrator workflow with RHDH Local.

1. The [`orchestrator/workflow-examples`](https://github.com/redhat-developer/rhdh-local/tree/main/orchestrator/workflow-examples) folder contains example workflows and by default, it is already
   mounted
   to
   `/home/kogito/serverless-workflow-project/src/main/resources` for SonataFlow configuration in the
   `compose-orchestrator.yaml` definition. The
   directory contains three workflows; greeting, slack and github. For more information about the workflow and setup,
   refer to this
   [link](https://github.com/redhat-developer/rhdh-local/tree/main/orchestrator/workflow-examples/README.md).

2. A suite of workflows exists in
   this [backstage-orchestrator-workflows](https://github.com/rhdhorchestrator/backstage-orchestrator-workflows/tree/main/workflows) repository.
   Clone the repository to your local and override the mount directory `RHDH_ORCHESTRATOR_WORKFLOWS` in your
   `.env` file
   file to point to your local `backstage-orchestrator-workflows` directory prior to starting your Orchestrator-based instance.
