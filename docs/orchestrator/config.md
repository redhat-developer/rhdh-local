# Custom Compose configuration

To make custom changes/configuration to the Compose definition, it is recommended to use a `compose-orchestrator.local.yaml` by merging `compose.yaml` and `orchestrator/compose.yaml` to avoid conflicts with version-controlled files.

Run this command to merge compose files:

```bash
# This will append to any existing compose-orchestrator.local.yaml file.
# Make sure to backup any custom changes, remove the existing file, and run this command.
podman compose -f compose.yaml -f orchestrator/compose.yaml config >> compose-orchestrator.local.yaml
```
 
 And this command to spin up the containers:
 
```bash
podman compose -f compose-orchestrator.local.yaml up -d
```
