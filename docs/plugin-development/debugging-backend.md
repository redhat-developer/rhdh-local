# Using VSCode to debug backend plugins

You can use RHDH-local with a debugger to to debug your backend plugins in VSCode. Here is how:

1. Start RHDH-local with the "debug" compose file

   ```sh
   # in rhdh-local directory
   podman-compose up -f compose.yaml -f compose-debug.yaml
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
   podman-compose stop rhdh
   podman-compose start rhdh
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