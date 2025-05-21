# Frontend Plugin Development

Follow these steps to preview and test development changes for your frontend plugin in RHDH local:

1. Ensure a clean start by running the following command:

   ```shell
   podman compose down -v
   ```

2. Use the `compose-dynamic-plugins-root.yaml` override file to start RHDH local.

   ```shell
   podman compose -f compose.yaml -f compose-dynamic-plugins-root.yaml up
   ```

   This command will create a `dynamic-plugins-root` directory in your current working directory. You will place your exported plugin files in this directory.

3. Add the plugin configuration for the plugin you want to develop into the `app-config.local.yaml` file under the `dynamicPlugins` key. Avoid adding this configuration to the `dynamic-plugins.override.yaml` file. You can add additional plugins into the `dynamic-plugins.override.yaml` file, but the one you are developing should be in the `app-config.local.yaml` file.

4. Inside your plugin directory, run the following command to export your plugin:

   ```shell
   npx @janus-idp/cli@latest package export-dynamic-plugin --dev --dynamic-plugins-root <path_to_dynamic-plugins-root_in_rhdh-local_folder>
   ```

5. Restart the RHDH container to apply changes:

   ```shell
   podman compose stop rhdh && podman compose start rhdh
   ```

6. Verify that your plugin appears in RHDH.

7. To apply code changes to your plugin, rerun the command in step 4 and refresh your browser. No need to restart any containers.
