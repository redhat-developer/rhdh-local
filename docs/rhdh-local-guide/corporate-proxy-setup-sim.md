If you want to test how RHDH would behave if deployed in a corporate proxy environment,
list both [`compose.yaml`](https://github.com/redhat-developer/rhdh-local/blob/main/compose.yaml) and [`compose-with-corporate-proxy.yaml`](https://github.com/redhat-developer/rhdh-local/blob/main/compose-with-corporate-proxy.yaml) in the same `podman compose` or `docker compose` command.

Note that the order of the YAML files is important:

=== "Podman"
    ```bash
    podman compose -f compose.yaml -f compose-with-corporate-proxy.yaml up -d
    ```

=== "Docker"
    ```bash
    docker compose -f compose.yaml -f compose-with-corporate-proxy.yaml up -d
    ```

[`compose-with-corporate-proxy.yaml`](https://github.com/redhat-developer/rhdh-local/blob/main/compose-with-corporate-proxy.yaml) adds a [Squid](https://www.squid-cache.org/) proxy container and a network setup where:

1. only the proxy container can reach the public internet directly
2. RHDH and the plugin installer reach the internet through that proxy, using `HTTP(S)_PROXY`, `NO_PROXY`, and `NODE_USE_ENV_PROXY` as described in [`default.env`](https://github.com/redhat-developer/rhdh-local/blob/main/default.env) and [Backstage’s corporate proxy guide](https://backstage.io/docs/tutorials/corporate-proxy/).