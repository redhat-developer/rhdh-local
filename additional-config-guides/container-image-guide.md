# Container Image Guide

## Configuring registry credentials

Place your registry credentials in `./configs/extra-files`, then reference the auth file in your `.env`:

```bash
REGISTRY_AUTH_FILE=/opt/app-root/src/configs/extra-files/auth.json
```

This allows RHDH-local to pull OCI artifacts from registries like registry.redhat.io without authentication errors.

## Changing the container image

By default, the [compose.yaml](./compose.yaml) points to the latest, stable **community build of RHDH** at [quay.io/rhdh-community/rhdh:1.7](https://quay.io/rhdh-community/rhdh:1.7), which includes both `linux-amd64` and `linux-arm64` images.

Community builds are [built with Github Actions](https://github.com/redhat-developer/rhdh/blob/main/.github/workflows/next-build-image.yaml#L46-L47) and [docker buildx](https://github.com/redhat-developer/rhdh/blob/main/.github/actions/docker-build/action.yaml), using the same sources as the commercially supported builds.

Commercially supported Red Hat images are built with [Konflux](https://konflux-ci.dev/) and [buildah](https://buildah.io/) using a [RHEL 9 container image](https://github.com/redhat-developer/rhdh/blob/main/.rhdh/docker/Dockerfile). Additionally, [Hermeto](https://github.com/hermetoproject/hermeto/tree/main) is used to pre-fetch dependencies so that builds are declarative, reproduceable and predictable. CI builds are pushed to quay.io, then later official releases are pushed to registry.redhat.io.

You can switch between these different images by changing the container image name held by the `RHDH_IMAGE` environment variable in your `.env` file, or editing the [compose.yaml](./compose.yaml) file.

### Using nightly community builds

Looking for the bleeding edge? To use the most recent nightly community build of RHDH from the main branch, set the variable as follows.

```sh
RHDH_IMAGE=quay.io/rhdh-community/rhdh:next
```

### Using unsupported pre-release CI builds

Continuous Integration (CI) builds on from [quay.io/rhdh/rhdh-hub-rhel9](https://quay.io/rhdh/rhdh-hub-rhel9), while unsupported, provide early access to commercially supported builds and bug fixes.

NOTE: Only `linux-amd64` builds are currently commercially supported.

To use the most recent nightly CI build of RHDH 1.y (for example, 1.8), set the variable as follows.

```sh
RHDH_IMAGE=quay.io/rhdh/rhdh-hub-rhel9:1.8
```

### Using commercially supported official images

To use the [official release of RHDH](https://catalog.redhat.com/software/containers/rhdh/rhdh-hub-rhel9/645bd4c15c00598369c31aba?gs&q=developer%20hub) 1.y (for example, 1.6), which includes only `linux-amd64`, set the variable as follows.

NOTE: Using official builds also [requires authentication with the registry](https://access.redhat.com/articles/RegistryAuthentication). See also the section below `Configuring registry credentials` to make this authentication pervasive.

```sh
RHDH_IMAGE=registry.redhat.io/rhdh/rhdh-hub-rhel9:1.7.0
```

#### Using image digests

If you prefer to use digests to floating tags, [browse for the tag you want to use](https://catalog.redhat.com/software/containers/rhdh/rhdh-hub-rhel9/645bd4c15c00598369c31aba/history), and click through to find the digest of the image you want to use. For example, from the [Get this image](https://catalog.redhat.com/software/containers/rhdh/rhdh-hub-rhel9/645bd4c15c00598369c31aba?image=68360c12177ad86df31947d8&architecture=amd64&container-tabs=gti) tab for 1.6.1 provides this image:

```sh
RHDH_IMAGE=registry.redhat.io/rhdh/rhdh-hub-rhel9@sha256:8729c21dc4b6e1339ed29bf87e2e2054c8802f401a029ebb1f397408f3656664
```
