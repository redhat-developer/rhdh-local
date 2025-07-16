## Developer Lightspeed in RHDH local

Red Hat Developer Lightspeed (Developer Lightspeed) is a virtual assistant powered by generative AI that offers in-depth insights into RHDH, including its wide range of capabilities. You can interact with this assistant to explore and learn more about RHDH in greater detail.

Developer Lightspeed provides a natural language interface within the RHDH console, helping you easily find information about the product, understand its features, and get answers to your questions as they come up.

---

**Prerequisites**

1. A PC based on an x86_64 (amd64) or arm64 (aarch64) architecture
2. An installation of Podman (or Docker) (with adequate resources available)
   
   - [**Podman**](https://podman.io/docs/installation) v5.4.1 or newer; [**Podman Compose**](https://github.com/containers/podman-compose) v1.3.0 or newer.
   - [**Docker Engine**](https://docs.docker.com/engine/) v28.1.0 or newer; [**Docker Compose**](https://docs.docker.com/compose/) plugin v2.24.0 or newer. This is necessary for compatibility with features such as ```env_file``` with the ```required``` key used in our compose.yaml.

   > **Note:** If you prefer to work with a graphical user interface, we recommend managing your container environments using [Podman Desktop](https://podman-desktop.io/). Podman Desktop can be [installed on a number of different systems](https://podman-desktop.io/docs/installation), and can be easier to work with if you are not as familiar with command line.
---

## Getting Started

Follow these steps to configure and launch Developer Lightspeed using either `podman compose` or `docker compose`.  

**Substitute `podman compose` with `docker compose` if you are using Docker.**

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

   This file contains placeholder values that will be replaced using environment variables:

   ```yaml
   lightspeed:
     questionValidation: true
     servers:
       - id: ${LIGHTSPEED_SERVER_ID}
         url: ${LIGHTSPEED_SERVER_URL}
         token: ${LIGHTSPEED_SERVER_TOKEN}
   ```

3. **Start the application**

   Use the following command to start the services:

   ```bash
   podman compose -f compose.yaml -f compose-with-lightspeed.yaml up -d
   # OR, if using Docker:
   docker compose -f compose.yaml -f compose-with-lightspeed.yaml up -d
   ```

   This command:

   - Uses the base **compose.yaml**
   - Adds the **compose-with-lightspeed.yaml** overlay
   - Runs all services in detached mode (`-d`)

4. **Verify that all services are running**

   After starting the application, make sure all services are running:

   ```bash
   podman compose ps
   # OR
   docker compose ps
   ```

   Look for all services to show `running` or `Up (starting)` in the Status column, like:

| CONTAINER ID | IMAGE                                                          | COMMAND                | CREATED         | STATUS                    | PORTS                                                                                                         | NAMES                  |
|--------------|----------------------------------------------------------------|------------------------|-----------------|---------------------------|---------------------------------------------------------------------------------------------------------------|------------------------|
| 31c3c681b742 | quay.io/rhdh-community/rhdh:next                               |                        | 16 seconds ago  | Exited (0) 5 seconds ago  | 8080/tcp                                                                                                      | rhdh-plugins-installer |
| 818ddf7fd045 | docker.io/ollama/ollama:latest                                 | ollama serve & ...     | 16 seconds ago  | Up 16 seconds (healthy)   | 0.0.0.0:7007->7007/tcp, 0.0.0.0:8080->8080/tcp, 0.0.0.0:11434->11434/tcp, 127.0.0.1:9229->9229/tcp            | ollama                 |
| 2860fc13b036 | quay.io/redhat-ai-dev/road-core-service:rcs-06302025-rhdh-1.6  | python3.11 runner...   | 15 seconds ago  | Up 5 seconds (starting)   | 0.0.0.0:7007->7007/tcp, 0.0.0.0:8080->8080/tcp, 0.0.0.0:11434->11434/tcp, 127.0.0.1:9229->9229/tcp, 8443/tcp  | road-core-service      |
| f7b74b9f241e | quay.io/rhdh-community/rhdh:next                               |                        | 4 seconds ago   | Up 5 seconds (starting)   | 0.0.0.0:7007->7007/tcp, 0.0.0.0:8080->8080/tcp, 0.0.0.0:11434->11434/tcp, 127.0.0.1:9229->9229/tcp            | rhdh                   |                                        |

   _Note: If any service is not running, you can inspect the logs:_

   ```bash
   podman logs <container-name>
   ```

5. **Open** http://localhost:7007/lightspeed **in your browser to access Developer Lightspeed.**

---

## Cleanup

To stop and remove the running containers:

```bash
podman compose -f compose.yaml -f compose-with-lightspeed.yaml down -v
# OR
docker compose -f compose.yaml -f compose-with-lightspeed.yaml down -v
```

---

> **Note:** All instructions in this guide apply to both Podman and Docker.  
> Replace `podman compose` with `docker compose` if you are using Docker.
