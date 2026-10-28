## Preconfigured Profiles

The `profile/` directory provides an alternative way to set up RHDH using preconfigured profiles. This approach allows you to quickly deploy RHDH with a set of predefined configurations and plugins tailored for specific use cases or environments.

### Benefits of Using Profiles

- **Simplified Setup**: Profiles come with preconfigured settings, reducing the need for manual configuration.
- **Consistency**: Ensures a unified and structured approach to managing and maintaining configurations.
- **Customizability**: Each profile can be tailored to specific requirements while maintaining a consistent structure.

### Trade-offs

While profiles offer a structured approach, they may introduce some duplication of configuration files, as each profile contains its own set of configurations and plugins.

### Example: RHDH Profile

The `rhdh` profile contains configurations and plugins commonly used in Red Hat Developer Hub deployments, including the Orchestrator plugin. This profile is ideal for environments where the Orchestrator plugin is required for workflow management.

### Directory Structure

Each profile in the `profile/` directory follows a consistent structure like this (not exhaustive):

```
profile/
├── <profile-name>/
│   ├── app-config/
│   ├── dynamic-plugins/
│   ├── catalog-entities/
│   ├── services.yaml
```

### How to Use Profiles

1. **Select a Profile**: Choose the profile that best matches your use case from the `profile/` directory.

2. **Create a Profile** *(Optional)*: If you want to create a new profile, you can copy an existing profile as a template and modify it as needed.

3. **Customize the Profile** *(Optional)*:
    - Modify the `app-config.yaml` file to override default application configurations.
    - Update the `dynamic-plugins.yaml` file to include or exclude specific plugins.
    - Adjust the `users.yaml` and `components.yaml` files to customize catalog entities.
    - etc.

3. **Run the Profile**: Use the `PROFILE` environment variable to point to the selected profile. For example:

   ```sh
   PROFILE=profile/rhdho podman compose -f profile/compose.yaml up -d
   ```
   or
    ```sh
    PROFILE=profile/rhdho docker compose -f profile/compose.yaml up -d
    ```
