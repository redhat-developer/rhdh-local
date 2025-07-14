# Plugins Guide

## Loading dynamic plugins from a local directory

During boot, the `install-dynamic-plugins` container reads the contents of the plugin configuration file and activates, configures, or downloads any plugins listed. RHDH Local supports two ways of specifying dynamic plugin configuration:

1. Default path: `configs/dynamic-plugins/dynamic-plugins.yaml`

1. User override path: `configs/dynamic-plugins/dynamic-plugins.override.yaml` or `configs/dynamic-plugins.yaml` If present, this file will automatically override the default and be used by the `install-dynamic-plugins` container. `configs/dynamic-plugins/dynamic-plugins.override.yaml` takes precedence over `configs/dynamic-plugins.yaml`.

In addition, the `local-plugins` directory is mounted into the `install-dynamic-plugins` container at `/opt/app-root/src/local-plugins`. Any plugins placed there can be activated/configured the same way (without downloading).

To load dynamic plugins from your local machine:

1. Copy the dynamic plugin binary file into the `local-plugins` directory.
2. Make sure permissions allow the container to read the files (e.g. `chmod -R 777 local-plugins` for quick testing).
3. Configure your plugin in one of the supported config files:
    - Prefer `configs/dynamic-plugins/dynamic-plugins.override.yaml` for local user overrides.
    - If no override file is present, `configs/dynamic-plugins/dynamic-plugins.yaml` will be used.
4. See [Changing Your Configuration](/rhdh-local/additional-config-guides/changing-config.md) for more on updating and reloading configs.

## Customize `.npmrc` for plugin installation

If you're installing dynamic plugins from a private registry or using a proxy, you can customize your own `.npmrc` file. A `.npmrc.example` file is provided in the `configs/` directory as a template.

1. Copy the example file to create your own `.npmrc`:

    ```sh
    cp configs/.npmrc.example configs/.npmrc
    ```

2. Open the newly created `.npmrc` file and add your configuration, such as private registry URLs or authentication tokens:

    ```sh
    //registry.npmjs.org/:_authToken=YOUR_TOKEN
    registry=https://your-private-registry.example.com/
    ```

When present, this `.npmrc` file will be automatically mounted into the `install-dynamic-plugins` container, and the `NPM_CONFIG_USERCONFIG` environment variable will be set to point to it.

If you don't create a `.npmrc`, plugin installation will still work using the default public registry settings.

> For more information on configuring `.npmrc`, see the [npm configuration docs](https://docs.npmjs.com/cli/v10/configuring-npm/npmrc).

## Developers: Using VSCode to debug backend plugins

You can use RHDH-local with a debugger to debug your backend plugins in VSCode. The Node.js debugger is exposed on port 9229. Here is how:

1. Start RHDH-local

   ```sh
   # in rhdh-local directory
   podman compose up -d
   ```

2. Open your plugin source code in VSCode
3. Export plugin an RHDH "dynamic" plugin

   ```sh
   # in plugin source code directory
   npx @janus-idp/cli@latest package export-dynamic-plugin
   ```

4. Copy exported derived plugin package to `dynamic-plugins-root` directory in the `rhdh` container.

   ```sh
   # in plugin source code directory
   podman cp dist-dynamic rhdh:/opt/app-root/src/dynamic-plugins-root/<your-plugin-name>
   ```

5. If your plugin requires configuration, add it to the `app-config.local.yaml` file in your cloned `rhdh-local` directory.

6. Restart the `rhdh` container

   ```sh
   # in rhdh-local directory
   podman compose stop rhdh
   podman compose start rhdh
   ```

7. Configure VSCode debugger to attach to the `rhdh` container.

   `.vscode/launch.json` example:

   ```json
   {
      "version": "0.2.0",
      "configurations": [
         {
            "name": "Attach to Process",
            "type": "node",
            "request": "attach",
            "port": 9229,
            "localRoot": "${workspaceFolder}",
            "remoteRoot": "/opt/app-root/src/dynamic-plugins-root/<your-plugin-name>",
         }
      ]
   }
   ```

8. Now, you can start debugging your plugin using VSCode debugger.
   Source mapping should work, and you should be able to put breakpoints to your TypeScript files.
   If it doesn't work, most likely you need to adjust `localRoot` and `remoteRoot` paths in `launch.json`.

   Every time you make changes to your plugin source code, you need to repeat steps 3-6.

## Frontend plugin development

Follow these steps to preview and test development changes for your frontend plugin in RHDH local:

1. Ensure a clean start by running the following command:

   ```shell
   podman compose down -v
   ```

2. Create the dynamic plugins root directory where you will place your exported plugins:

   ```shell
   mkdir dynamic-plugins-root
   ```

3. Inside your plugin directory, run the following command to export your plugin:

   ```shell
   npx @janus-idp/cli@latest package export-dynamic-plugin --dev --dynamic-plugins-root <path_to_dynamic-plugins-root_in_rhdh-local_folder>
   ```

4. Add the plugin configuration for the plugin you want to develop into the `app-config.local.yaml` file under the `dynamicPlugins` key. Avoid adding this configuration to the `dynamic-plugins.override.yaml` file. You can add additional plugins into the `dynamic-plugins.override.yaml` file, but the one you are developing should be in the `app-config.local.yaml` file.

5. Use the `compose-dynamic-plugins-root.yaml` override file to start RHDH local:

   ```shell
   podman compose -f compose.yaml -f compose-dynamic-plugins-root.yaml up
   ```

6. Verify that your plugin appears in RHDH.

7. To apply code changes to your plugin, rerun the command in step 3 and refresh your browser. No need to restart any containers.
