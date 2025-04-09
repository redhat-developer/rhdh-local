## Developer Lightspeed in RHDH local

Red Hat Developer Lightspeed (Developer Lightspeed) is a virtual assistant powered by generative AI that offers in-depth insights into RHDH, including its wide range of capabilities. You can interact with this assistant to explore and learn more about RHDH in greater detail.

Developer Lightspeed provides a natural language interface within the RHDH console, helping you easily find information about the product, understand its features, and get answers to your questions as they come up.

---

**Prerequisites**

- Ensure you have **Podman** and **podman-compose** installed and available in your PATH.
- You should have a working RHDH local environment.
- Access to a Lightspeed server and API key.

---

## Getting Started

Follow these steps to configure and launch Developer Lightspeed using `podman-compose`.

---

1. **Load the Developer Lightspeed dynamic plugin**

   Copy the Lightspeed dynamic plugin overrides to **`configs/dynamic-plugins/dynamic-plugins.override.yaml`**.

   > **Warning:** This will overwrite your existing `dynamic-plugins.override.yaml` file. If you have customizations, back up or manually merge the content as needed.

   To get started quickly with Developer Lightspeed, you can copy the entire content with the following command:

   ```bash
   cp configs/dynamic-plugins/dynamic-plugins.lightspeed.override.example.yaml configs/dynamic-plugins/dynamic-plugins.override.yaml
   ```

   Alternatively, you can manually copy the content inside the `plugins` property and paste it into your existing `dynamic-plugins.override.yaml` file. If merging manually, ensure correct YAML structure and avoid duplicate keys.

2. **Copy the Lightspeed App Config example**

   Start by creating a new local app config file for Lightspeed:

   ```bash
   cp configs/app-config/app-config.lightspeed.local.example.yaml configs/app-config/app-config.lightspeed.local.yaml
   ```

   This file contains placeholder values that will be replaced using environment variables in the next steps:

   ```yaml
   lightspeed:
     questionValidation: true
     servers:
       - id: ${LIGHTSPEED_SERVER_ID}
         url: ${LIGHTSPEED_SERVER_URL}
         token: ${LIGHTSPEED_SERVER_TOKEN}
   ```

3. **Set up Environment variables**

   Create or edit a **.env** file in the root of the project with the required values:

   ```bash
   LIGHTSPEED_SERVER_ID=ollama
   LIGHTSPEED_SERVER_URL=[your-value-here, e.g. https://your.lightspeed.server/v1]
   LIGHTSPEED_SERVER_TOKEN=[your-api-key]
   ```

   > Replace the values in brackets with your actual server URL and API key. The `.env` file is used to inject values into your runtime environment and configurations.

4. **Update `rcsconfig.yaml`**

   Open the file at **`configs/lightspeed/rcsconfig.yaml`** and replace the `${LIGHTSPEED_SERVER_URL}` placeholder with the actual value:

   ```yaml
   llm_providers:
     - name: ollama
       type: openai
       url: [your-value-here, e.g. https://your.lightspeed.server/v1]
   ```

   ⚠️ This is a temporary manual step. Ensure the value matches what's in `.env`.

5. **Start the application**

   Use the following command to start the services:

   ```bash
   podman-compose -f compose.yaml -f compose-with-lightspeed.yaml up -d
   ```

   This command:

   - Uses the base **compose.yaml**
   - Adds the **compose-with-lightspeed.yaml** overlay
   - Runs all services in detached mode (`-d`)

6. **Verify that all services are running**

   After starting the application, make sure all services are running:

   ```bash
   podman-compose ps
   ```

   Look for all services to show `running` or `Up (starting)` in the Status column, like:

   | Container Name           | Image                                            | Command                | Status        | Ports                                                                     |
   | ------------------------ | ------------------------------------------------ | ---------------------- | ------------- | ------------------------------------------------------------------------- |
   | `rhdh-plugins-installer` | `quay.io/rhdh-community/rhdh:next`               |                        | Exited (0)    | `8080/tcp`                                                                |
   | `rhdh`                   | `quay.io/rhdh-community/rhdh:next`               |                        | Up (starting) | `7007/tcp`, `9229/tcp`, `8080/tcp`<br> → `0.0.0.0:7007`, `127.0.0.1:9229` |
   | `road-core-service`      | `quay.io/redhat-ai-dev/road-core-service:latest` | `python3.11 runner...` | Up (starting) | `8080/tcp`, `8443/tcp`                                                    |

   _Note: If any service is not running, you can inspect the logs:_

   ```bash
   podman logs <container-name>
   ```

7. **Open** http://localhost:7007/lightspeed **in your browser to access Developer Lightspeed.**

---

## Cleanup

To stop and remove the running containers:

```bash
podman-compose -f compose.yaml -f compose-with-lightspeed.yaml down -v
```
