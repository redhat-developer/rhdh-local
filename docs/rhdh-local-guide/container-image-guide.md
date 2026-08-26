## Configuring registry credentials

If you need to pull RHDH images or install dynamic plugins from private OCI registries (such as `registry.redhat.io`), you need to configure registry authentication. There are two options:

### Option A: Mount host credentials directly (recommended)

If you already have credentials on your host (from `podman login` or `docker login`), point `REGISTRY_AUTH_FILE_PATH` in your `.env` to that file:

```bash
# Podman (Linux)
REGISTRY_AUTH_FILE_PATH=${XDG_RUNTIME_DIR}/containers/auth.json

# Podman (macOS) or when XDG_RUNTIME_DIR is not set
REGISTRY_AUTH_FILE_PATH=~/.config/containers/auth.json

# Docker
REGISTRY_AUTH_FILE_PATH=~/.docker/config.json
```

The auth file is bind-mounted into the `install-dynamic-plugins` container automatically. When the file contains valid credentials, `REGISTRY_AUTH_FILE` is set internally — no additional configuration needed.

If you haven't logged in yet, do so first:

```bash
podman login registry.redhat.io
```

### Option B: Copy credentials into the project

Copy your registry credentials file into `./configs/extra-files/`, then set the `REGISTRY_AUTH_FILE` variable in your `.env`:

```bash
cp ~/.config/containers/auth.json ./configs/extra-files/auth.json
```

```bash
REGISTRY_AUTH_FILE=/opt/app-root/src/configs/extra-files/auth.json
```

This works because the `configs/` directory is already mounted into the container. Files in `configs/extra-files/` are gitignored, so your credentials will not be committed.

## Changing the container image

By default, the [compose.yaml](https://github.com/redhat-developer/rhdh-local/blob/main/compose.yaml) points to the latest, stable **community build of RHDH** at [quay.io/rhdh-community/rhdh:1.9](https://quay.io/rhdh-community/rhdh:1.9), which includes both `linux-amd64` and `linux-arm64` images.

Community builds are [built with Github Actions](https://github.com/redhat-developer/rhdh/blob/main/.github/workflows/next-build-image.yaml#L46-L47) and [docker buildx](https://github.com/redhat-developer/rhdh/blob/main/.github/actions/docker-build/action.yaml), using the same sources as the commercially supported builds.

Commercially supported Red Hat images are built with [Konflux](https://konflux-ci.dev/) and [buildah](https://buildah.io/) using a [RHEL 9 container image](https://github.com/redhat-developer/rhdh/blob/main/.rhdh/docker/Dockerfile). Additionally, [Hermeto](https://github.com/hermetoproject/hermeto/tree/main) is used to pre-fetch dependencies so that builds are declarative, reproduceable and predictable. CI builds are pushed to quay.io, then later official releases are pushed to registry.redhat.io.

You can switch between these different images by changing the container image name held by the `RHDH_IMAGE` environment variable in your `.env` file, or editing the [compose.yaml](https://github.com/redhat-developer/rhdh-local/blob/main/compose.yaml) file.

### Using nightly community builds

Looking for the bleeding edge? To use the most recent nightly community build of RHDH from the main branch, set the variable as follows.

```sh
RHDH_IMAGE=quay.io/rhdh-community/rhdh:next
```

Or, for builds from a given `release-1.y` branch (for example, 1.10), set the variable as follows.

```sh
RHDH_IMAGE=quay.io/rhdh-community/rhdh:next-1.10
```

### Using unsupported pre-release CI builds

Continuous Integration (CI) builds on from [quay.io/rhdh/rhdh-hub-rhel9](https://quay.io/rhdh/rhdh-hub-rhel9), while unsupported, provide early access to commercially supported builds and bug fixes.

NOTE: Only `linux-amd64` builds are currently commercially supported.

To use the most recent nightly CI build of RHDH 1.y (for example, 1.11), set the variable as follows.

```sh
RHDH_IMAGE=quay.io/rhdh/rhdh-hub-rhel9:1.10
```

### Using commercially supported official images

To use the [official release of RHDH](https://catalog.redhat.com/software/containers/rhdh/rhdh-hub-rhel9/645bd4c15c00598369c31aba?gs&q=developer%20hub) 1.y (for example, 1.9), which includes only `linux-amd64`, set the variable as follows.

NOTE: Using official builds also [requires authentication with the registry](https://access.redhat.com/articles/RegistryAuthentication). See also the section below `Configuring registry credentials` to make this authentication pervasive.

```sh
RHDH_IMAGE=registry.redhat.io/rhdh/rhdh-hub-rhel9:1.10.3
```

#### Using image digests

If you prefer to use digests to floating tags, [browse for the tag you want to use](https://catalog.redhat.com/software/containers/rhdh/rhdh-hub-rhel9/645bd4c15c00598369c31aba/history), and click through to find the digest of the image you want to use. For example, from the [Get this image](https://catalog.redhat.com/software/containers/rhdh/rhdh-hub-rhel9/645bd4c15c00598369c31aba?image=68360c12177ad86df31947d8&architecture=amd64&container-tabs=gti) tab for 1.6.1 provides this image:

```sh
RHDH_IMAGE=registry.redhat.io/rhdh/rhdh-hub-rhel9@sha256:8729c21dc4b6e1339ed29bf87e2e2054c8802f401a029ebb1f397408f3656664
```
