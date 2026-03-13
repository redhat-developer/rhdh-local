This guide walks you through configuring GitHub authentication in RHDH Local, enabling secure login and full repository integration features like catalog discovery, template publishing, and pull request tracking.

This guide focuses more on RHDH Local, but feel free to refer to the [official RHDH docs](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.7/html-single/integrating_red_hat_developer_hub_with_github/index) for more details about integrating RHDH with GitHub.

## Prerequisites

Before setting up GitHub authentication:

- **GitHub Account**: Personal or organization account
- **RHDH Local Running**: Complete the [Getting Started Guide](getting-started.md) first
- **Admin Access**: To your GitHub account or organization settings
- **Port 7007 Available**: Default RHDH Local port (or note your custom port)

---

## Step 1: Create GitHub App

Register a GitHub by following the [GitHub documentation](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/registering-a-github-app).

!!! tip
    You can also use the Backstage CLI to interactively create a new GitHub App:

    ```bash
    npx @backstage/cli create-github-app <github-org-name>
    ```

Refer to the [official RHDH docs](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.7/html/authentication_in_red_hat_developer_hub/enabling-user-authentication-with-github) for more details, but in a nutshell, fill in the GitHub App form with these values:

| Field | Value | Notes |
|-------|-------|-------|
| **Application name** | `RHDH Local` | Choose a descriptive name |
| **Description** | `Local RHDH development environment` | Optional but recommended |
| **Homepage URL** | `http://localhost:7007` | Use your actual RHDH Local URL |
| **Authorization callback URL** | `http://localhost:7007/api/auth/github/handler/frame` | ⚠️ Must be exact |
| **Permissions** | Refer to [App permissions](https://backstage.io/docs/integrations/github/github-apps/#app-permissions) | At least, Read access to checks, code, members, and metadata |

!!! warning "Critical: Callback URL"
    The callback URL **must** end with `/api/auth/github/handler/frame`. This is the exact endpoint RHDH expects for auth completion.

1. Click **General**, then **Client secrets** and click **Generate a new client secret**
2. Click **"Generate a new client secret"**
3. **Copy the app ID, client ID, and client secret immediately** - the secret won't be shown again
4. Scroll down to **Private keys** and click on **Generate a private key** to download the private key file. Copy its contents.

---

## Step 2: Configure the credentials file

Copy the template `configs/extra-files/github-app-credentials.example.yaml` file to your own, and fill in the template. Don't worry, all files under the `configs/extra-files` directory (except the template above) are not version-controlled.

```bash
# copy the template credentials file
cp configs/extra-files/github-app-credentials.example.yaml configs/extra-files/github-app-credentials.yaml

# edit your copy and fill in the values
edit configs/extra-files/github-app-credentials.yaml
```

---

## Step 3: Configure RHDH Application

Open or create `configs/app-config/app-config.local.yaml` (from the `configs/app-config/app-config.local.example.yaml` example) and add GitHub authentication and integration, like so:

```yaml
auth:
  environment: development
  providers:
    github:
      development:
        # You can declare these variables in your local .env file
        clientId: ${GITHUB_CLIENT_ID}
        clientSecret: ${GITHUB_CLIENT_SECRET}
        signIn:
          resolvers:
            - resolver: usernameMatchingUserEntityName
              dangerouslyAllowSignInWithoutUserInCatalog: true
        
# GitHub integration for catalog discovery
integrations:
  github:
    - host: github.com
      apiBaseUrl: https://api.github.com
      rawBaseUrl: https://github.com/raw
      apps:
        - $include: ../extra-files/github-app-credentials.yaml

# Catalog discovery from GitHub
catalog:
  providers:
    github:
      - organization: 'my-organization'
        catalogPath: '/catalog-info.yaml'
        filters:
          repository: '.*'
          branch: 'main'
        schedule:
          frequency: { minutes: 30 }
          timeout: { minutes: 10 }
```

---

## Step 4: Apply Configuration

### 4.1 Restart RHDH Local

Apply your authentication changes:

=== "Podman"
    ```bash
    podman compose up -d --force-recreate
    ```

=== "Docker"
    ```bash
    docker compose up -d --force-recreate
    ```

### 4.2 Verify Startup

Check that RHDH Local starts successfully with GitHub authentication:

=== "Podman"
    ```bash
    # Monitor startup logs
    podman compose logs -f rhdh
    ```

=== "Docker"
    ```bash
    # Monitor startup logs
    docker compose logs -f rhdh
    ```

Then try to login using GitHub.

---

For additional help, see [Help & Contributing](help-and-contrib.md).
