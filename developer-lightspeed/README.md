## Developer Lightspeed in RHDH local

Red Hat Developer Lightspeed (Developer Lightspeed) is a virtual assistant powered by generative AI that offers in-depth insights into Red Hat Developer Hub (RHDH), including its wide range of capabilities. You can interact with this assistant to explore and learn more about RHDH in greater detail.

Developer Lightspeed provides a natural language interface within the RHDH console, helping you easily find information about the product, understand its features, and get answers to your questions as they come up.


## Supported Architecture
Developer Lightspeed for Red Hat Developer Hub is available as a plug-in on all platforms that host RHDH, and it requires the use of Lightspeed-Core Service (LCS) and Llama Stack as sidecar containers.

## Table of Contents
1. [Getting Started](#getting-started)
2. [Cleanup](#cleanup)
3. [Troubleshooting](#troubleshooting)
4. [Advanced Configuration Guides](#advanced-configuration-guides)

---

## Getting Started

> [!IMPORTANT]
> Developer Lightspeed can be resource intensive on the model side because of the use of RAG and in some cases question validation. If using the provided Ollama server locally you may encounter unforeseen responses if the model cannot handle the context. 
>
> For best results it is recommended to provide your own external LLM provider.


Follow these steps to configure and launch Developer Lightspeed.

---

1. **Load the Developer Lightspeed dynamic plugins**

   Add the `developer-lightspeed/configs/dynamic-plugins/dynamic-plugins.lightspeed.yaml` file to the list of `includes` in your `configs/dynamic-plugins/dynamic-plugins.override.yaml` to enable Developer Lightspeed plugins within RHDH.
  
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

3. **Understanding the Setup Process**

   The setup script (`start-lightspeed.sh`) uses a simple 2-step process to configure Developer Lightspeed:

   **Step 1: Choose Your LLM Provider**
   - **Ollama** (recommended for beginners): Uses the built-in Ollama container that runs locally. No additional configuration needed - the script handles everything automatically.
   - **Bring Your Own Model**: Use your own external LLM provider (any OpenAI API compatible service). You must configure the environment variables for your chosen provider before starting.

   **Step 2: Choose Question Validation**
   - **No validation**: Allows any type of questions - Developer Lightspeed acts as a general-purpose assistant.
   - **With validation**: Filters questions to RHDH/Backstage topics only - ensures all questions are relevant to Red Hat Developer Hub.

   > [!NOTE]
   > **What does "Bring Your Own Model" mean?**
   >
   > This option allows you to use an external LLM service instead of the local Ollama container. Developer Lightspeed supports any service that is **OpenAI API compatible**, including but not limited to:
   > - **vLLM**: A high-performance inference server (self-hosted or cloud)
   > - **OpenAI**: OpenAI's API (GPT-3.5, GPT-4, etc.)
   > - **Vertex AI**: Google Cloud's Vertex AI service (experimental)
   > - **Other compatible services**: Azure OpenAI, WatsonX, Amazon Bedrock, Mistral, Nvidia NIM, LM Studio, and other OpenAI API compatible services
   >
   > **Tested Providers**: Red Hat has tested and verified the following providers: vllm, ollama, openai, and vertex_ai. For other services, compatibility testing is the responsibility of the user. Red Hat has not performed testing on all OpenAI API compatible services.
   >
   > If you select "Bring Your Own Model" in step 1, you **must** configure at least one provider in step 4 below.

4. **Set Environment Variables**

    In the root of this repository there is a `default.env` file. Copy its contents to `.env` and fill in the required values:

    ```bash
    cp default.env .env
    ```

    > [!IMPORTANT]
    > **Configuration Requirements:**
    > - **If you selected Ollama in step 1**: You don't need to modify any environment variables. The defaults work out of the box.
    > - **If you selected "Bring Your Own Model" in step 1**: You **must** configure at least one external LLM provider below before starting the application.
    > - **If you selected "With validation" in step 2**: You **must** configure `VALIDATION_PROVIDER` and `VALIDATION_MODEL` (see section below).

    ### Quick Reference: Setup Combinations → Required Configuration

    | Provider | Validation | Required Env Vars | Compose Files Used |
    |----------|------------|-------------------|-------------------|
    | **Ollama** | No validation | None (defaults work) | `compose.yaml` + `compose-with-ollama.yaml` |
    | **Ollama** | With validation | `VALIDATION_PROVIDER`, `VALIDATION_MODEL` | `compose.yaml` + `compose-with-ollama.yaml` + `compose-with-validation.yaml` |
    | **Bring your own model** | No validation | At least one: vLLM, OpenAI, or Vertex AI | `compose.yaml` |
    | **Bring your own model** | With validation | At least one provider + validation vars | `compose.yaml` + `compose-with-validation.yaml` |

    ---

    ### Configure External LLM Providers (Required if you selected "Bring Your Own Model")

    If you selected "Bring Your Own Model" in step 1, configure **at least one** of the following providers in your `.env` file:

    #### **Option A: vLLM Provider**

    Use vLLM for high-performance inference with self-hosted or cloud-based vLLM servers.

    ```env
    # Enable vLLM provider
    ENABLE_VLLM=true
    
    # REQUIRED: URL to your vLLM server (must end with /v1)
    VLLM_URL=https://your-vllm-server.com/v1
    
    # REQUIRED: API key for authentication (if your server requires it)
    VLLM_API_KEY=your-api-key-here
    
    # OPTIONAL: Maximum tokens per request (default: 4096)
    # VLLM_MAX_TOKENS=4096
    
    # OPTIONAL: TLS verification (default: true)
    # VLLM_TLS_VERIFY=true
    ```

    #### **Option B: OpenAI Provider**

    Use OpenAI's API to access GPT models (GPT-3.5, GPT-4, etc.).

    ```env
    # Enable OpenAI provider
    ENABLE_OPENAI=true
    
    # REQUIRED: Your OpenAI API key
    OPENAI_API_KEY=sk-your-openai-api-key-here
    ```

    #### **Option C: Vertex AI Provider (Experimental)**

    Use Google Cloud's Vertex AI service to run Gemini models.

    > [!WARNING]
    > **Experimental Feature:** Using Vertex AI to run Google models is experimental. Vertex AI provides an OpenAI-compatible API for Gemini models, which is why it can work with Developer Lightspeed (which supports OpenAI API implementations). This is provided as an alternative way to access Google models since `remote:gemini` is not yet fully supported.

    ```env
    # Enable Vertex AI provider
    ENABLE_VERTEX_AI=true
    
    # REQUIRED: Absolute path to your Google Cloud credentials JSON file
    VERTEX_AI_CREDENTIALS_PATH=/absolute/path/to/your/google-cloud-credentials.json
    
    # REQUIRED: Your GCP project ID
    VERTEX_AI_PROJECT=your-gcp-project-id
    
    # OPTIONAL: GCP location/region (default: us-central1)
    # VERTEX_AI_LOCATION=us-central1
    ```

    > [!NOTE]
    > **To use Vertex AI, you need:**
    > 1. A Google Cloud Platform (GCP) project with Vertex AI API enabled
    > 2. A service account with appropriate permissions
    > 3. A service account key file (JSON) downloaded from GCP
    > 4. Set `VERTEX_AI_PROJECT` to your project ID
    > 5. Set `VERTEX_AI_CREDENTIALS_PATH` to the absolute path of your credentials JSON file
    > 
    > **Read more:** [Vertex AI Provider Documentation](https://llamastack.github.io/v0.2.18/providers/inference/remote_vertexai.html)

    ---

    ### Configure Question Validation (Required if you selected "With validation")

    If you selected "With validation" in step 2, configure the validation provider:

    ```env
    # REQUIRED: Provider to use for question validation
    # Must be one of: ollama, vllm, openai, vertexai
    # Must match an enabled provider (e.g., if ENABLE_VLLM=true, use VALIDATION_PROVIDER=vllm)
    VALIDATION_PROVIDER=ollama
    
    # REQUIRED: Model identifier for validation
    # Format depends on provider:
    #   - Ollama: model-name (e.g., llama3.2:1b)
    #   - vLLM: model-name (e.g., meta-llama/Llama-2-7b-chat-hf)
    #   - OpenAI: model-name (e.g., gpt-3.5-turbo)
    #   - Vertex AI: model-name (e.g., gemini-pro)
    VALIDATION_MODEL=llama3.2:1b
    ```

    > [!IMPORTANT]
    > **Validation Model Requirements:**
    > - The validation model must support larger context windows to handle question validation
    > - For Ollama: `llama3.2:1b` is recommended
    > - Ensure `VALIDATION_PROVIDER` matches one of your enabled providers

5. **Start the application**

   To start the Developer Lightspeed interactive setup script, run the following from the root of the repository:

   ```bash
   bash ./developer-lightspeed/scripts/start-lightspeed.sh
   ```

   The script will guide you through a simple 3-step process:
   1. **Choose your LLM provider** (Ollama or Bring your own model)
   2. **Choose question validation** (No validation or With validation)
   3. **Container runtime detection** (auto-detects podman or docker, prompts only if detection fails or to override)

   > [!IMPORTANT]
   > **Before starting:**
   > - If you selected "Bring Your Own Model" in step 1, ensure you've configured at least one external LLM provider in your `.env` file (see step 4 above)
   > - If you selected "With validation" in step 2, ensure `VALIDATION_PROVIDER` and `VALIDATION_MODEL` are set correctly in your `.env` file
   > - For question validation, the model must support larger context windows (e.g., `llama3.2:1b` for Ollama)


---


6. **Verify that all services are running**

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
   | 2860fc13b036 | quay.io/lightspeed-core/lightspeed-stack:dev-20251021-ee9f08f  | python3.11 runner...   | 15 seconds ago  | Up 5 seconds (starting)   | 0.0.0.0:7007->7007/tcp, 127.0.0.1:9229->9229/tcp, 8080/tcp, 8443/tcp  | lightspeed-core-service      |
   | 1572ghe259c0 | quay.io/redhat-ai-dev/llama-stack:6b98aa4ac2178e35d33ef0078bb948202e7dfabc | | 3 minutes ago  |  Up 3 minutes (healthy) |  7007/tcp, 127.0.0.1:9229->9229/tcp | llama-stack |

   ---

   #### **B. Minimal setup (own model server, no ollama):**
   You should see output similar to:

   | CONTAINER ID | IMAGE                                                          | COMMAND                | CREATED         | STATUS                    | PORTS                                                                                                         | NAMES                  |
   |--------------|----------------------------------------------------------------|------------------------|-----------------|---------------------------|---------------------------------------------------------------------------------------------------------------|------------------------|
   | 31c3c681b742 | quay.io/rhdh-community/rhdh:next                               |                        | 16 seconds ago  | Exited (0) 5 seconds ago  | 8080/tcp                                                                                                      | rhdh-plugins-installer |
   | f7b74b9f241e | quay.io/rhdh-community/rhdh:next                               |                        | 4 seconds ago   | Up 5 seconds (starting)   |  0.0.0.0:7007->7007/tcp, 127.0.0.1:9229->9229/tcp, 8080/tcp              | rhdh                   |                                        |
   | 2860fc13b036 | quay.io/lightspeed-core/lightspeed-stack:dev-20251021-ee9f08f  | python3.11 runner...   | 15 seconds ago  | Up 5 seconds (starting)   | 0.0.0.0:7007->7007/tcp, 127.0.0.1:9229->9229/tcp, 8080/tcp, 8443/tcp  | lightspeed-core-service      |
   | 1572ghe259c0 | quay.io/redhat-ai-dev/llama-stack:6b98aa4ac2178e35d33ef0078bb948202e7dfabc | | 3 minutes ago  |  Up 3 minutes (healthy) |  7007/tcp, 127.0.0.1:9229->9229/tcp | llama-stack |

   ---

   _Note: If any service is not running, you can inspect the logs:_

   ```bash
   podman logs <container-name>
   ```

7. **Open** http://localhost:7007/lightspeed **in your browser to access Developer Lightspeed.**

   ![Developer Lightspeed](images/Developer-Lightspeed.png)

---

## Cleanup

### Quick Cleanup (Recommended)

The easiest way to stop Developer Lightspeed is using the interactive stop script:

```bash
bash ./developer-lightspeed/scripts/stop-lightspeed.sh
```

**With volumes removal (non-interactive):**
```bash
bash ./developer-lightspeed/scripts/stop-lightspeed.sh -v
# or
bash ./developer-lightspeed/scripts/stop-lightspeed.sh --volumes
```

The script will:
- Auto-detect your container runtime (podman or docker)
- Detect which configuration is running
- **Without `-v` flag**: Stops containers only (preserves volumes for faster restart)
- **With `-v` flag**: Stops containers and removes volumes (complete cleanup)

### Manual Cleanup

If you prefer to stop containers manually, use the commands below based on your setup:



#### **A. Default setup (with Ollama)**

##### **Without Question Validation**
```bash
podman compose -f compose.yaml -f developer-lightspeed/compose-with-ollama.yaml down -v
```

##### **With Question Validation**
```bash
podman compose -f compose.yaml -f developer-lightspeed/compose-with-ollama.yaml -f developer-lightspeed/compose-with-validation.yaml down -v
```

#### **B. Minimal setup (own model server, no ollama)**

##### **Without Question Validation**
```bash
podman compose -f compose.yaml -f developer-lightspeed/compose.yaml down -v
```

##### **With Question Validation**
```bash
podman compose -f compose.yaml -f developer-lightspeed/compose.yaml -f developer-lightspeed/compose-with-validation.yaml down -v
```

---

> **Note:** All instructions in this guide apply to both Podman and Docker.  
> Replace `podman compose` with `docker compose` if you are using Docker.



## Troubleshooting

If you encounter issues while setting up or running Developer Lightspeed, try the following solutions:

### 1. Services Not Starting or Exiting Unexpectedly

- **Check container logs:**  
  Use the following command to view logs for a specific container:
  ```bash
  podman logs <container-name>
  # OR
  docker logs <container-name>
  ```
  Look for error messages that can help diagnose the problem.

- **Common causes:**
  - Port conflicts (another service is using the same port)
  - Insufficient memory or CPU resources
  - Incorrect environment variables

### 2. "model requires more system memory than is available" Error

- Increase the memory allocated to your Podman or Docker virtual machine.  
  See the [Running Larger Models with Ollama](#running-larger-models-with-ollama) section for instructions.

### 3. "Permission Denied" or File Access Errors

- Ensure you have the necessary permissions to access files and directories, especially when mounting volumes.
- On Linux/macOS, you may need to adjust permissions with `chmod` or run commands with `sudo`.

### 4. Web UI Not Accessible at http://localhost:7007/lightspeed

- Make sure all containers are running:
  ```bash
  podman compose ps
  # OR
  docker compose ps
  ```
- Check for firewall or VPN issues that may block access to localhost ports.

### 5. Environment Variables Not Set

- Double-check that your `.env` or `default.env` files are present and correctly configured.
- Restart the containers after making changes to environment files.

### 6. "Bring Your Own Model" Not Working

If you selected "Bring Your Own Model" in step 1 but the external LLM provider isn't working:

- **Verify provider is enabled**: Check that `ENABLE_VLLM=true`, `ENABLE_OPENAI=true`, or `ENABLE_VERTEX_AI=true` is set in your `.env` file
- **Check required variables**: Ensure all required variables for your chosen provider are set (see step 4 above)
- **Verify connectivity**: For vLLM, ensure the `VLLM_URL` is accessible from the container
- **Check logs**: Review `llama-stack` container logs for provider connection errors:
  ```bash
  podman logs llama-stack
  # OR
  docker logs llama-stack
  ```
- **Validate API keys**: Ensure API keys are correct and have proper permissions

### 7. Still Stuck?

- Try stopping and removing all containers, then starting again, see [cleanup](#cleanup).

If your issue persists, please [open an issue on GitHub](https://github.com/your-org/your-repo/issues) with details about your problem so we can help you troubleshoot.



## Advanced Configuration Guides

  ### Plugin Configuration Reference

  Available configuration options:

  ```yaml
  lightspeed:
    # OPTIONAL: Custom users prompts displayed to users
    # If not provided, the plugin uses built-in default prompts
    prompts:
      - title: <prompt_title>              # REQUIRED: Display title for the prompt
        message: <prompt_message>          # REQUIRED: The actual prompt text/question
    
    # OPTIONAL: Backend-only configurations
    servicePort: 8080                      # OPTIONAL: Port for lightspeed service (default: 8080)
    systemPrompt: <custom_system_prompt>   # OPTIONAL: Override default RHDH system prompt
  ```

  #### Configuration Fields

  | Field | Type | Required | Default | Description |
  |-------|------|----------|---------|-------------|
  | `prompts` | Array | ❌ No | Built-in prompts | Custom welcome prompts for users |
  | `prompts[].title` | String | ✅ Yes* | - | Display title for the prompt (*required if prompts array is provided) |
  | `prompts[].message` | String | ✅ Yes* | - | The actual prompt text/question (*required if prompts array is provided) |
  | `servicePort` | Number | ❌ No | `8080` | Port for lightspeed backend service |
  | `systemPrompt` | String | ❌ No | RHDH default | Custom system prompt to override default behavior |

  ### Example Configuration

  ```yaml
  lightspeed:
    prompts:
      - title: "Quick Start"
        message: "How do I enable a dynamic plugin?"
    servicePort: 8080
    systemPrompt: "You are a helpful assistant focused on Red Hat Developer Hub development."
  ```


### Running Larger Models with Ollama

Some AI models require more memory than the default Podman machine allocation. If you encounter errors such as “model requires more system memory than is available,” you can increase the memory available to your Podman virtual machine:

```bash
podman machine stop
podman machine set --memory=8192
podman machine start
```

- The example above sets the memory to **8 GiB** (`8192` MB).
- Adjust the value as needed (e.g., `--memory=16384` for 16 GiB).
- Ensure your host system has enough free RAM.

After increasing the memory, restart your containers to use the new limits.

---

### How do I change the Ollama model?

By default, the Ollama service pulls and loads the `llama3.2:1b` model.  
To use a larger or different model, you can now specify the model name using the `OLLAMA_MODEL` environment variable. The Compose file supports a default value using the `${OLLAMA_MODEL:-llama3.2:1b}` syntax.

**Example in your Compose file:**

```yaml
command: >
  "ollama serve &
  sleep 5 &&
  ollama pull ${OLLAMA_MODEL:-llama3.2:1b} &&
  touch /tmp/ready &&
  wait"
```

- If you set `OLLAMA_MODEL` in your `.env` file or environment, that model will be used.
- If not set, it will default to `llama3.2:1b`.
- Example `.env` entry:
  ```env
  OLLAMA_MODEL=llama2:13b
  ```
- Make sure the model you choose fits within your available memory.

> **Tip:** You can find available models and their memory requirements in the [Ollama model library](https://ollama.com/library).

---

### Using Your Own Ollama Models from Your System

If you have custom or pre-downloaded Ollama models on your local system, you can make them available to the Ollama container by mounting your host’s model directory into the container.

#### **Step 1: Locate Your Ollama Model Directory**

By default, Ollama stores models in:
- **Linux/macOS:** `~/.ollama`
- **Windows:** `%USERPROFILE%\.ollama`

#### **Step 2: Mount the Directory in Your Compose File**

You can set the path to your local `.ollama` directory using an environment variable in your `.env` file:

**In your `.env` file:**
```env
OLLAMA_MODELS_PATH=/absolute/path/to/your/.ollama
```

**In your Compose file (already set up):**
```yaml
volumes:
  - ${OLLAMA_MODELS_PATH:-ollama_data}:/root/.ollama
```

- If you set `OLLAMA_MODELS_PATH` in your `.env` file, that directory will be mounted.
- If not set, it will default to using the `ollama_data` volume.

---

#### **Step 3: Use Your Models in the Container**

Once mounted, you can reference your model in the `ollama pull` command in the `developer-lightspeed/compose-with-ollama.yaml`. 

Ollama will use the models from the mounted directory, so you don’t need to re-download them inside the container.

> **Tip:** If you add new models to your local `.ollama` directory, they will automatically be available in the container after a restart.

---

**This approach saves bandwidth, speeds up startup, and lets you use custom or fine-tuned models you've created locally.**

---

