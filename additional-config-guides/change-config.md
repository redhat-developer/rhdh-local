# Changing your configuration

When you change `app-config.local.yaml` you must restart the `rhdh` container to load RHDH your updated configuration.

```sh
podman compose stop rhdh && podman compose start rhdh
```

When you change `dynamic-plugins.yaml` you need to re-run the `install-dynamic-plugins` container and then restart RHDH instance.

```sh
podman compose run install-dynamic-plugins
podman compose stop rhdh && podman compose start rhdh
```
