# Setup Containerized Podman Action

This GitHub Action sets up Podman 5.x using a containerized environment with Docker as the backend. It provides a way to use the latest Podman on GitHub Actions runners without dealing with library incompatibilities.

## How it works

1. Pulls a Podman container image (default: `quay.io/podman/stable:v5`)
2. Starts a persistent container with the host's Docker socket mounted
3. Installs the selected compose provider (docker-compose or podman-compose) inside the container
4. Creates a wrapper script at `/usr/local/bin/podman` that proxies commands to the container

This approach:
- Uses **Podman 5.x** for command parsing and compose orchestration
- Uses the **host's Docker daemon** for actual container operations
- Avoids library incompatibilities when trying to install newer Podman on Ubuntu

## Usage

### Basic usage

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Setup Podman
    uses: ./.github/actions/setup-containerized-podman

  - name: Use Podman
    run: |
      podman --version
      podman compose up -d
```

### With custom docker-compose version

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Setup Podman
    id: podman
    uses: ./.github/actions/setup-containerized-podman
    with:
      podman-image: quay.io/podman/stable:v5
      docker-compose-version: v5.0.1

  - name: Use Podman
    run: podman compose up -d

  - name: Cleanup
    if: always()
    run: |
      docker container stop ${{ steps.podman.outputs.container-name }} || true
      docker container rm ${{ steps.podman.outputs.container-name }} || true
```

### Using podman-compose instead of docker-compose

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Setup Podman
    id: podman
    uses: ./.github/actions/setup-containerized-podman
    with:
      compose-provider: podman-compose
      podman-compose-version: v1.2.0

  - name: Use Podman
    run: podman compose up -d

  - name: Cleanup
    if: always()
    run: |
      docker container stop ${{ steps.podman.outputs.container-name }} || true
      docker container rm ${{ steps.podman.outputs.container-name }} || true
```

### With additional environment variables

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Setup Podman
    id: podman
    uses: ./.github/actions/setup-containerized-podman
    with:
      env: |
        CORPORATE_PROXY_IMAGE=docker.io/ubuntu/squid:latest
        MY_SECRET=${{ secrets.MY_SECRET }}
        NODE_ENV=production

  - name: Use Podman
    run: podman compose up -d

  - name: Cleanup
    if: always()
    run: |
      docker container stop ${{ steps.podman.outputs.container-name }} || true
      docker container rm ${{ steps.podman.outputs.container-name }} || true
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `podman-image` | Podman container image to use | No | `quay.io/podman/stable:v5` |
| `compose-provider` | Compose provider to install: `docker-compose`, `podman-compose`, or empty to skip | No | `''` |
| `docker-compose-version` | Version of docker-compose to install (if compose-provider is docker-compose) | No | `v5.0.1` |
| `podman-compose-version` | Version of podman-compose to install (if compose-provider is podman-compose) | No | `v1.5.0` |
| `env` | Additional environment variables to pass to the Podman container (one per line, KEY=VALUE format) | No | `''` |
| `print-version` | Print Podman and Compose versions after setup | No | `false` |

## Outputs

| Output | Description |
|--------|-------------|
| `container-name` | The name of the Podman container (use this for cleanup) |

## Cleanup

Don't forget to clean up the Podman container after your workflow. Use the `container-name` output:

```yaml
- name: Setup Podman
  id: podman
  uses: ./.github/actions/setup-containerized-podman

# ... your steps ...

- name: Cleanup Podman
  if: always()
  run: |
    docker container stop ${{ steps.podman.outputs.container-name }} || true
    docker container rm ${{ steps.podman.outputs.container-name }} || true
```

## Requirements

- Docker must be available on the runner (pre-installed on GitHub-hosted runners)
- The action requires privileged mode for nested container operations

## License

Apache-2.0

