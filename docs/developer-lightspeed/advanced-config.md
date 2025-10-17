# Advanced Configuration Guides

## Plugin Configuration Reference

Available configuration options:

```yaml
lightspeed:
  # REQUIRED: Configure LLM servers with OpenAI API compatibility
  servers:
    - id: <server_id>                    # REQUIRED: Unique identifier for the server
      url: <server_URL>                  # REQUIRED: Base URL of the LLM server (e.g., https://api.openai.com/v1)
      token: <api_key>                   # REQUIRED: Authentication token/API key for the server
  
  # OPTIONAL: Enable/disable question validation (default: true)
  # When enabled, restricts questions to RHDH-related topics for better security
  questionValidation: true
  
  # OPTIONAL: Custom users prompts displayed to users
  # If not provided, the plugin uses built-in default prompts
  prompts:
    - title: <prompt_title>              # REQUIRED: Display title for the prompt
      message: <prompt_message>          # REQUIRED: The actual prompt text/question
  
  # OPTIONAL: Backend-only configurations
  servicePort: 8080                      # OPTIONAL: Port for lightspeed service (default: 8080)
  systemPrompt: <custom_system_prompt>   # OPTIONAL: Override default RHDH system prompt
```

### Configuration Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `servers` | Array | ✅ Yes | - | Array of LLM server configurations |
| `servers[].id` | String | ✅ Yes | - | Unique identifier for the server |
| `servers[].url` | String | ✅ Yes | - | Base URL of the LLM server with OpenAI API compatibility |
| `servers[].token` | String | ✅ Yes | - | Authentication token or API key for accessing the server |
| `questionValidation` | Boolean | ❌ No | `true` | Enable/disable question validation for security |
| `prompts` | Array | ❌ No | Built-in prompts | Custom welcome prompts for users |
| `prompts[].title` | String | ✅ Yes* | - | Display title for the prompt (*required if prompts array is provided) |
| `prompts[].message` | String | ✅ Yes* | - | The actual prompt text/question (*required if prompts array is provided) |
| `servicePort` | Number | ❌ No | `8080` | Port for lightspeed backend service |
| `systemPrompt` | String | ❌ No | RHDH default | Custom system prompt to override default behavior |

## Example Configurations

### Basic Configuration (Required fields only)
```yaml
lightspeed:
  servers:
    - id: ${LLM_SERVER_ID}
      url: ${LLM_SERVER_URL}
      token: ${LLM_SERVER_TOKEN}
```

### Complete Configuration with All Options
```yaml
lightspeed:
  servers:
    - id: ${LLM_SERVER_ID}
      url: ${LLM_SERVER_URL}
      token: ${LLM_SERVER_TOKEN}
  questionValidation: true
  prompts:
    - title: "Quick Start"
      message: "How do I enable a dynamic plugin?"
  servicePort: 8080
  systemPrompt: "You are a helpful assistant focused on Red Hat Developer Hub development."
```

## Running Larger Models with Ollama

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

## How do I change the Ollama model?

By default, the Ollama service pulls and loads the `tinyllama` model.  
To use a larger or different model, you can now specify the model name using the `OLLAMA_MODEL` environment variable. The Compose file supports a default value using the `${OLLAMA_MODEL:-tinyllama}` syntax.

**Example in your Compose file:**

```yaml
command: >
  "ollama serve &
  sleep 5 &&
  ollama pull ${OLLAMA_MODEL:-tinyllama} &&
  touch /tmp/ready &&
  wait"
```

- If you set `OLLAMA_MODEL` in your `.env` file or environment, that model will be used.
- If not set, it will default to `tinyllama`.
- Example `.env` entry:
  ```env
  OLLAMA_MODEL=llama2:13b
  ```
- Make sure the model you choose fits within your available memory.

!!! tip
    You can find available models and their memory requirements in the [Ollama model library](https://ollama.com/library).

---

## Using Your Own Ollama Models from Your System

If you have custom or pre-downloaded Ollama models on your local system, you can make them available to the Ollama container by mounting your host’s model directory into the container.

### **Step 1: Locate Your Ollama Model Directory**

By default, Ollama stores models in:
- **Linux/macOS:** `~/.ollama`
- **Windows:** `%USERPROFILE%\.ollama`

### **Step 2: Mount the Directory in Your Compose File**

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

### **Step 3: Use Your Models in the Container**

Once mounted, you can reference your model in the `ollama pull` command in the `developer-lightspeed/compose-with-ollama.yaml`. 

Ollama will use the models from the mounted directory, so you don’t need to re-download them inside the container.

!!! tip
    If you add new models to your local `.ollama` directory, they will automatically be available in the container after a restart.

---

**This approach saves bandwidth, speeds up startup, and lets you use custom or fine-tuned models you’ve created locally.**

---
