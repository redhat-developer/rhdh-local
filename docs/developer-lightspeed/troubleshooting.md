# Troubleshooting

If you encounter issues while setting up or running Developer Lightspeed, try the following solutions:

## 1. Services Not Starting or Exiting Unexpectedly

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

## 2. "model requires more system memory than is available" Error

- Increase the memory allocated to your Podman or Docker virtual machine.  
  See the [Running Larger Models with Ollama](#running-larger-models-with-ollama) section for instructions.

## 3. "Permission Denied" or File Access Errors

- Ensure you have the necessary permissions to access files and directories, especially when mounting volumes.
- On Linux/macOS, you may need to adjust permissions with `chmod` or run commands with `sudo`.

## 4. Web UI Not Accessible at http://localhost:7007/lightspeed

- Make sure all containers are running:
  ```bash
  podman compose ps
  # OR
  docker compose ps
  ```
- Check for firewall or VPN issues that may block access to localhost ports.

## 5. Environment Variables Not Set

- Double-check that your `.env` or `default.env` files are present and correctly configured.
- Restart the containers after making changes to environment files.

## 6. Still Stuck?

- Try stopping and removing all containers, then starting again:
  ```bash
  podman compose -f compose.yaml -f compose-with-lightspeed.yaml down -v
  podman compose -f compose.yaml -f compose-with-lightspeed.yaml up -d
  # OR use docker compose
  ```

If your issue persists, please refer to the general [Help & Contributing Guide](../help-and-contrib.md) for assistance.
