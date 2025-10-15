# Getting Started with Developer Lightspeed on RHDH Local

## Supported architecture
Developer Lightspeed for Red Hat Developer Hub is available as a plug-in on all platforms that host RHDH, and it requires the use of Road-Core Service (RCS) as a sidecar container.

!!! note
    Currently, the provided RCS image is built for x86 platforms. To use other platforms (for example, arm64), ensure that you enable emulation.

## Getting Started

Follow these steps to configure and launch Developer Lightspeed using either `podman compose` or `docker compose`.  

!!! note
    All instructions in this guide apply to both Podman and Docker.  
    Replace `podman compose` with `docker compose` if you are using Docker.

---

1. **Load the Developer Lightspeed dynamic plugins**

   Add the `developer-lightspeed/configs/dynamic-plugins/dynamic-plugins.lightspeed.yaml` file to the list of `includes` in your `configs/dynamic-plugins/dynamic-plugins.override.yaml` to enable developer lightspeed plugins within RHDH.
  
   Example:

   ```yaml

   includes:
   - dynamic-plugins.default.yaml
   - developer-lightspeed/configs/dynamic-plugins/dynamic-plugins.lightspeed.yaml # <-- to add to enable the developer lightspeed plugins

   # Below you can add your own custom dynamic plugins, including local ones.
   plugins: []
   ```

2. **Copy the Lightspeed App Config example**

   Start by creating a new local app config file for Lightspeed:

   ```bash
   cp developer-lightspeed/configs/app-config/app-config.lightspeed.local.example.yaml developer-lightspeed/configs/app-config/app-config.lightspeed.local.yaml
   ```

   This file contains placeholder values that will be replaced using environment variables:

   ```yaml
   lightspeed:
     questionValidation: false
     servers:
       - id: ${LLM_SERVER_ID}
         url: ${LLM_SERVER_URL}
         token: ${LLM_SERVER_TOKEN}
   ```


   By default, the required environment variables for Lightspeed are already set in the `default.env` file:

   ```env
   LLM_SERVER_ID=ollama
   LLM_SERVER_URL=http://0.0.0.0:11434/v1
   LLM_SERVER_TOKEN=dummy
   ```

   You do **not** need to change these unless you want to use your own model server.  

3. **Start the application**

   You can start Developer Lightspeed in two ways, depending on your model server setup:

   #### **A. Use the default (Ollama included) setup**

   This will start all services, including the built-in Ollama model server:

   ```bash
   podman compose -f compose.yaml -f developer-lightspeed/compose-with-ollama.yaml up -d
   # OR, if using Docker:
   docker compose -f compose.yaml -f developer-lightspeed/compose-with-ollama.yaml up -d
   ```

   ---

   #### **B. Use your own model server (minimal setup)**

   If you want to use your own model server (such as a remote Ollama instance or another provider), use the minimal setup and set your server details in a `.env` file:

   ```bash
   podman compose -f compose.yaml -f developer-lightspeed/compose.yaml up -d
   # OR, if using Docker:
   docker compose -f compose.yaml -f developer-lightspeed/compose.yaml up -d
   ```

   Make sure your `.env` file in the project root contains:
   ```env
   LLM_SERVER_ID=your-server-id
   LLM_SERVER_URL=https://your.lightspeed.server/v1
   LLM_SERVER_TOKEN=your-api-key
   ```

---


4. **Verify that all services are running**

   After starting the application, make sure all services are running:

   ```bash
   podman compose ps
   # OR
   docker compose ps
   ```

   Look for all services to show `running` or `Up (starting)` in the Status column, like:


   #### **A. Default setup (with Ollama):**
   You should see output similar to:

   | CONTAINER ID | IMAGE                                                          | COMMAND                | CREATED         | STATUS                    | PORTS                                                                                                         | NAMES                  |
   |--------------|----------------------------------------------------------------|------------------------|-----------------|---------------------------|---------------------------------------------------------------------------------------------------------------|------------------------|
   | 31c3c681b742 | quay.io/rhdh-community/rhdh:next                               |                        | 16 seconds ago  | Exited (0) 5 seconds ago  | 8080/tcp                                                                                                      | rhdh-plugins-installer |
   | f7b74b9f241e | quay.io/rhdh-community/rhdh:next                               |                        | 4 seconds ago   | Up 5 seconds (starting)   |  0.0.0.0:7007->7007/tcp, 127.0.0.1:9229->9229/tcp, 8080/tcp              | rhdh                   |                                        |
   | 818ddf7fd045 | docker.io/ollama/ollama:latest                                 | ollama serve & ...     | 16 seconds ago  | Up 16 seconds (healthy)   | 0.0.0.0:7007->7007/tcp, 127.0.0.1:9229->9229/tcp, 11434/tcp             | ollama                 |
   | 2860fc13b036 | quay.io/redhat-ai-dev/road-core-service:rcs-06302025-rhdh-1.6  | python3.11 runner...   | 15 seconds ago  | Up 5 seconds (starting)   | 0.0.0.0:7007->7007/tcp, 127.0.0.1:9229->9229/tcp, 8080/tcp, 8443/tcp  | road-core-service      |

   ---

   #### **B. Minimal setup (own model server, no ollama):**
   You should see output similar to:

   | CONTAINER ID | IMAGE                                                          | COMMAND                | CREATED         | STATUS                    | PORTS                                                                                                         | NAMES                  |
   |--------------|----------------------------------------------------------------|------------------------|-----------------|---------------------------|---------------------------------------------------------------------------------------------------------------|------------------------|
   | 31c3c681b742 | quay.io/rhdh-community/rhdh:next                               |                        | 16 seconds ago  | Exited (0) 5 seconds ago  | 8080/tcp                                                                                                      | rhdh-plugins-installer |
   | f7b74b9f241e | quay.io/rhdh-community/rhdh:next                               |                        | 4 seconds ago   | Up 5 seconds (starting)   |  0.0.0.0:7007->7007/tcp, 127.0.0.1:9229->9229/tcp, 8080/tcp              | rhdh                   |                                        |
   | 2860fc13b036 | quay.io/redhat-ai-dev/road-core-service:rcs-06302025-rhdh-1.6  | python3.11 runner...   | 15 seconds ago  | Up 5 seconds (starting)   | 0.0.0.0:7007->7007/tcp, 127.0.0.1:9229->9229/tcp, 8080/tcp, 8443/tcp  | road-core-service      |

   ---

   _Note: If any service is not running, you can inspect the logs:_

   ```bash
   podman logs <container-name>
   ```

5. **Open** http://localhost:7007/lightspeed **in your browser to access Developer Lightspeed.**

   ![Developer Lightspeed](images/Developer-Lightspeed.png)


## Cleanup

To stop and remove the running containers:

```bash
podman compose -f compose.yaml -f compose-with-lightspeed.yaml down -v
# OR
docker compose -f compose.yaml -f compose-with-lightspeed.yaml down -v
```
