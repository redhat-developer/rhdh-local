If you want to test how RHDH would behave if deployed in a corporate proxy environment,
you can run `podman compose` or `docker compose` by merging both the [`compose.yaml`](https://github.com/redhat-developer/rhdh-local/blob/main/compose.yaml) and [`compose-with-corporate-proxy.yaml`](https://github.com/redhat-developer/rhdh-local/blob/main/compose-with-corporate-proxy.yaml) files.

Example with `podman compose` (note that the order of the YAML files is important):

```bash
podman compose -f compose.yaml -f compose-with-corporate-proxy.yaml up -d
```

The [`compose-with-corporate-proxy.yaml`](https://github.com/redhat-developer/rhdh-local/blob/main/compose-with-corporate-proxy.yaml) file includes a specific [Squid](https://www.squid-cache.org/)-based proxy container as well as an isolated network, such that:

1. only the proxy container has access to the outside
2. all containers part of the internal network need to communicate through the proxy container to reach the outside. This can be done with the `HTTP(S)_PROXY` and `NO_PROXY` environment variables.
