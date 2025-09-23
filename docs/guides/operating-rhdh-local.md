# Operating RHDH Local

This guide covers all essential operations for managing your RHDH Local environment, from initial startup to advanced maintenance tasks. RHDH Local supports both **Podman** (recommended) and **Docker** with identical commands. Simply replace `podman compose` with `docker compose` throughout this guide if using Docker.

!!! tip "Container Runtime Choice"
    While both Podman and Docker work almost identically, Podman is recommended for its rootless operation and better security model.

## Prerequisites

Before operating RHDH Local, ensure you have:

- **Podman v5.4.1+** with Podman Compose, or **Docker Engine v28.1.0+** with Docker Compose v2.24.0+
<!-- - **8GB+ available RAM** for optimal performance -->
- **Port 7007 available** (or configure alternative in `configs/app-config/app-config.local.yaml`)
- **Internet connection** for image downloads and external content

---

## Basic Operations

### Starting RHDH Local

Navigate to your RHDH Local repository root and start the services:

=== "Podman (Recommended)"
    ```bash
    podman compose up -d
    ```

=== "Docker"
    ```bash
    docker compose up -d
    ```

On Podman, this will block until the dynamic plugins installer container finishes.
But you can open a new terminal and stream the logs with:

```bash
# Stream all service logs
podman compose logs -f
```

**Access the application:**
```
http://localhost:7007
```

Expected startup time: 2-5 minutes depending on system resources and plugins enabled.

### Viewing Logs and Status

Monitor application logs in real-time:

```bash
# Stream all service logs
podman compose logs -f

# View logs for specific service.
podman compose logs -f rhdh

# Check running services
podman compose ps

# View resource usage
podman stats
```

Exit log streaming with `Ctrl+C`.

### Stopping RHDH Local

Stop all services while preserving data:

```bash
podman compose down
```

This preserves:

- Database contents (catalog entities, user preferences) if you are using a PostgreSQL database. By default, RHDH Local makes use of an in-memory SQLite database, so changes might get lost when the application restarts.
- Local volumes (like the default dynamic plugins root local volume) and persistent data

### Graceful Restart

For a clean restart without data loss:

```bash
podman compose stop rhdh
podman compose run install-dynamic-plugins
podman compose start rhdh
```

Or to force-recreate the running containers:

```bash
podman compose up -d --force-recreate
```

---

## Configuration Management

### Applying Configuration Changes

After modifying configuration files, restart to apply changes:

**For app-config changes** (`configs/app-config/app-config.local.yaml`):

```bash
podman compose stop rhdh
podman compose start rhdh
```

**For plugin changes** (`configs/dynamic-plugins/dynamic-plugins.override.yaml`):

```bash
# Reinstall plugins with new configuration
podman compose run install-dynamic-plugins

# Restart RHDH service
podman compose stop rhdh
podman compose start rhdh
```

**For catalog entities** (`configs/catalog-entities/*.yaml`):

```bash
podman compose stop rhdh
podman compose start rhdh
```

### Validating Configuration

Check configuration syntax before restarting:

```bash
# Check for common configuration issues
podman compose config
```

---

## Data and Volume Management

### Understanding RHDH Local Data

By default, RHDH Local stores data in named volumes:

- **`rhdh-local_dynamic-plugins-root`**: Dynamic plugins root, serving for caching dynamic plugins and avoid re-download.

### Cleaning Up Data

**Remove containers only** (keep data):

```bash
podman compose down
```

**Remove containers and cached plugins**:

```bash
podman compose down -v
```

**Complete cleanup** (⚠️ **destroys all data**):

```bash
podman compose down -v --rmi all
```

This removes:

- All containers and networks
- All persistent volumes and databases
- All locally built images

**Fresh start after cleanup:**

```bash
podman compose up -d
```

---

## Advanced Operations

### Performance Tuning

**Monitor resource usage:**

```bash
# Container resource usage
podman stats

# System resource usage  
top
htop
```

### Troubleshooting Operations

**Container won't start:**

```bash
# Check for port conflicts
sudo lsof -i :7007

# Verify container runtime
podman --version
systemctl status podman

# Check logs for errors
podman compose logs
```

**Performance issues:**

```bash
# Rebuild containers from scratch
podman compose up -d --force-recreate

# Clear system cache (Podman)
podman system prune --all --volumes

# Clear system cache (Docker)
docker system prune --all --volumes
```

**Network connectivity issues:**

```bash
# Verify container networking
podman network ls
podman compose ps

# Test internal connectivity
podman exec rhdh curl -f http://localhost:7007/api/catalog/entities
```

### Development and Debugging

**Access container shell:**

```bash
# RHDH application container
podman exec -it rhdh bash
```

---

## Maintenance and Best Practices

### Regular Maintenance Tasks

**Maintenance commands:**

```bash
# Update to latest RHDH Local
git pull origin main
podman compose pull
podman compose up -d

# Clean unused resources
podman system prune
podman volume prune
```

### Security Considerations

- Keep container images updated regularly
- Use local `.env` file (and other git-ignored files) to put sensitive data to inject into the RHDH Local containers
- Don't expose RHDH Local to external networks
- Review plugin sources and permissions

---

## Quick Reference

### Essential Commands

| Operation | Podman | Docker |
|-----------|--------|--------|
| Start | `podman compose up -d` | `docker compose up -d` |
| Stop | `podman compose down` | `docker compose down` |
| Restart RHDH | `podman compose stop rhdh; podman compose run install-dynamic-plugins; podman compose start rhdh` | `docker compose stop; docker compose run install-dynamic-plugins; docker compose start rhdh` |
| Logs | `podman compose logs -f` | `docker compose logs -f` |
| Status | `podman compose ps` | `docker compose ps` |
| Clean up | `podman compose down -v --rmi all` | `docker compose down -v --rmi all` |

### When to Restart vs. Full Reset

- **Restart**: Configuration changes, plugin updates, debugging
- **Full reset**: Major version changes, persistent issues, starting fresh

---

For questions or contributions, visit [Help & Contributing](../help-and-contrib.md).
