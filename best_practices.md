
<b>Pattern 1: Always extend the base dynamic-plugins configuration instead of replacing it, and avoid duplicating plugins that are already enabled by default. In user override files, include the default list via includes and only add or customize what is necessary.</b>

Example code before:
```
# configs/dynamic-plugins/dynamic-plugins.override.yaml
plugins:
  - package: ./dynamic-plugins/dist/backstage-community-plugin-tech-radar
    disabled: false
  - package: ./dynamic-plugins/dist/backstage-community-plugin-quay
    disabled: false
```

Example code after:
```
# configs/dynamic-plugins/dynamic-plugins.override.yaml
includes:
  - dynamic-plugins.default.yaml
plugins:
  # Only add what’s not already in the defaults or needs customization
  - package: ./dynamic-plugins/dist/my-custom-plugin
    disabled: false
    pluginConfig:
      dynamicPlugins:
        frontend:
          my.custom.plugin:
            appIcon: myIcon
```

<details><summary>Examples for relevant past discussions:</summary>

- https://github.com/redhat-developer/rhdh-local/pull/48#discussion_r2121546365
- https://github.com/redhat-developer/rhdh-local/pull/89#discussion_r2309367544
- https://github.com/redhat-developer/rhdh-local/pull/89#discussion_r2309381271
- https://github.com/redhat-developer/rhdh-local/pull/92#discussion_r2318355187
</details>


___

<b>Pattern 2: Preserve backward compatibility for legacy configuration locations while migrating to new paths by checking both in startup scripts and emitting clear deprecation warnings. Keep legacy behavior working, but guide users toward the new structure.</b>

Example code before:
```
# wait-for-plugins-and-start.sh
DEFAULT_APP_CONFIG="configs/app-config/app-config.local.yaml"
exec node packages/backend --config "$DEFAULT_APP_CONFIG"
```

Example code after:
```
# wait-for-plugins-and-start.sh
EXTRA_CLI_ARGS=""
NEW_USER_APP_CONFIG="configs/app-config/app-config.local.yaml"
LEGACY_USER_APP_CONFIG="configs/app-config.local.yaml"

if [ -f "$NEW_USER_APP_CONFIG" ]; then
  EXTRA_CLI_ARGS="--config $NEW_USER_APP_CONFIG"
elif [ -f "$LEGACY_USER_APP_CONFIG" ]; then
  echo "[warn] Using legacy app-config.local.yaml. Please migrate to configs/app-config/app-config.local.yaml."
  EXTRA_CLI_ARGS="--config $LEGACY_USER_APP_CONFIG"
fi

exec node packages/backend --config app-config.yaml $EXTRA_CLI_ARGS
```

<details><summary>Examples for relevant past discussions:</summary>

- https://github.com/redhat-developer/rhdh-local/pull/34#discussion_r2011011416
- https://github.com/redhat-developer/rhdh-local/pull/34#discussion_r2011004167
- https://github.com/redhat-developer/rhdh-local/pull/61#discussion_r2206744859
</details>


___

<b>Pattern 3: Pin GitHub Actions to immutable commit SHAs and conditionally run steps in matrix workflows to avoid unnecessary work. Ensure required directories or artifacts are created only for the scenarios that need them.</b>

Example code before:
```
jobs:
  test:
    steps:
      - uses: actions/checkout@v4
      - name: Start app
        run: docker compose up -d
```

Example code after:
```
jobs:
  test:
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4
      - name: Create dynamic plugins dir
        if: ${{ matrix.composeConfig.name == 'dynamic-plugins-root' }}
        run: mkdir -p dynamic-plugins-root
      - name: Start app
        run: ${{ matrix.tool }} compose ${{ matrix.composeConfig.cliArgs }} up --detach --quiet-pull
```

<details><summary>Examples for relevant past discussions:</summary>

- https://github.com/redhat-developer/rhdh-local/pull/58#discussion_r2207019446
- https://github.com/redhat-developer/rhdh-local/pull/48#discussion_r2123380191
- https://github.com/redhat-developer/rhdh-local/pull/48#discussion_r2124828857
- https://github.com/redhat-developer/rhdh-local/pull/48#discussion_r2124836152
- https://github.com/redhat-developer/rhdh-local/pull/48#discussion_r2128148749
</details>


___

<b>Pattern 4: Use a single image tag variable across all dependent Compose services and prefer multi-architecture images by default. Ensure the plugin installer uses the exact same image tag as the main application.</b>

Example code before:
```
services:
  rhdh:
    image: ${RHDH_IMAGE:-quay.io/rhdh/rhdh-hub-rhel9:1.4}
  install-dynamic-plugins:
    image: ${RHDH_IMAGE:-quay.io/rhdh-community/rhdh:1.6}
```

Example code after:
```
services:
  rhdh:
    image: ${RHDH_IMAGE:-quay.io/rhdh-community/rhdh:1.6}
  install-dynamic-plugins:
    image: ${RHDH_IMAGE:-quay.io/rhdh-community/rhdh:1.6}
```

<details><summary>Examples for relevant past discussions:</summary>

- https://github.com/redhat-developer/rhdh-local/pull/53#discussion_r2159092757
- https://github.com/redhat-developer/rhdh-local/pull/53#discussion_r2159093245
- https://github.com/redhat-developer/rhdh-local/pull/55#discussion_r2169227185
</details>


___

<b>Pattern 5: Enforce ShellCheck in CI and document any suppressions inline with a justification placed on or next to the directive. When expanding CLI arguments intentionally, allow word splitting and add a clear rationale for SC2086 suppression.</b>

Example code before:
```
# Start server
EXTRA_CLI_ARGS="--config $USER_APP_CONFIG"
exec node packages/backend --config "app-config.yaml" "$EXTRA_CLI_ARGS"
```

Example code after:
```
# Start server
# shellcheck disable=SC2086 # Allow word splitting so EXTRA_CLI_ARGS expands into multiple CLI flags
exec node packages/backend --config app-config.yaml $EXTRA_CLI_ARGS
```

<details><summary>Examples for relevant past discussions:</summary>

- https://github.com/redhat-developer/rhdh-local/pull/67#discussion_r2207895135
- https://github.com/redhat-developer/rhdh-local/pull/58#discussion_r2207019446
</details>


___

<b>Pattern 6: Make documentation explicit and actionable by listing tested tool versions with links, using assertive language (“works with”) and standardized commands. Prefer the podman compose wrapper and clarify compose provider expectations.</b>

Example code before:
```
- Docker and Compose should work.
- Podman should work.
docker-compose up -d
```

Example code after:
```
- Docker Engine v28.1.0+ and Docker Compose v2.24.0+ (install docs linked)
- Podman v5.4.1+ (podman compose wrapper), podman-compose v1.3.0+ if used as provider
podman compose up -d
docker compose up -d
```

<details><summary>Examples for relevant past discussions:</summary>

- https://github.com/redhat-developer/rhdh-local/pull/52#discussion_r2159085433
- https://github.com/redhat-developer/rhdh-local/pull/52#discussion_r2164453539
- https://github.com/redhat-developer/rhdh-local/pull/56#discussion_r2175521878
- https://github.com/redhat-developer/rhdh-local/pull/56#discussion_r2175387414
</details>


___

<b>Pattern 7: Isolate optional or niche features into dedicated override files and folders (compose and config), and instruct users to merge them when needed. Avoid mixing optional feature setup into default paths to keep the baseline experience simple.</b>

Example code before:
```
# compose.yaml (monolithic)
services:
  rhdh: ...
  orchestrator: ...
  extra-plugins: ...
```

Example code after:
```
# compose.yaml (baseline)
services:
  rhdh: ...
# compose-orchestrator.yaml (optional)
services:
  orchestrator: ...
# Run with:
# podman compose -f compose.yaml -f compose-orchestrator.yaml up -d
```

<details><summary>Examples for relevant past discussions:</summary>

- https://github.com/redhat-developer/rhdh-local/pull/55#discussion_r2176840772
- https://github.com/redhat-developer/rhdh-local/pull/72#discussion_r2224853832
</details>


___
