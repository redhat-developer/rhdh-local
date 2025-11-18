# Welcome to RHDH Local

RHDH Local is the fastest and simplest way for platform engineers to test their [software catalogs](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.7/html/customizing_red_hat_developer_hub/about-software-catalogs), [TechDocs](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.7/html/techdocs_for_red_hat_developer_hub/about-techdocs_customizing-display), [plugins](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.7/html/introduction_to_plugins/index), [software templates](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.7/html/customizing_red_hat_developer_hub/configuring-templates), [homepage customizations](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.7/html/customizing_red_hat_developer_hub/customizing-the-home-page), [configurations](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.7/html/customizing_red_hat_developer_hub/index) and more with Red Hat Developer Hub!

## What is RHDH Local?

RHDH Local is a containerized, local environment that provides a complete Red Hat Developer Hub instance running on your machine. It's designed specifically for:

- **Testing and Development**: Try out RHDH features, plugins, and configurations locally
- **Education and Demos**: Learn and showcase RHDH concepts without complex infrastructure setup  
- **Plugin Development**: Build and test dynamic plugins locally
- **Configuration Validation**: Test app configurations, catalogs, and templates before deployment

!!! danger "Production Warning"

    **RHDH Local is NOT a substitute for Red Hat Developer Hub**. Do NOT attempt to use RHDH Local as a production system. RHDH Local is designed to help individual developers test various RHDH features. It is not designed to scale and it is not suitable for use by teams (there is no RBAC for example).

!!! warning "Support Notice"

    There is no official, commercial support for RHDH Local from Red Hat. Use at your own risk.

!!! info

    This documentation focuses on **RHDH Local specific workflows and features**. For comprehensive Red Hat Developer Hub documentation, see the [official RHDH documentation](https://docs.redhat.com/en/documentation/red_hat_developer_hub/).

## Primary Use Cases For RHDH Local

RHDH Local serves multiple purposes for platform engineers, developers, and organizations looking to explore and leverage Red Hat Developer Hub. Whether you're validating configurations before production deployment, learning RHDH concepts in a safe environment, or building custom plugins, RHDH Local provides the flexibility and isolation you need. Below are the primary scenarios where RHDH Local delivers the most value.

### Testing & Configuration

!!! tip "Validate Before You Deploy 🧪"

    Use RHDH Local to test and validate your configurations in a safe, isolated environment:

    * Test software catalogs, templates, and TechDocs locally
    * Validate dynamic plugin configurations and behavior
    * Experiment with homepage customizations and branding
    * Test integrations with Source Control Management (SCM) tools like GitHub or GitLab
    * Test authentication flows

### Education & Learning

!!! info "Learn RHDH Hands-On 📚"

    RHDH Local is perfect for learning and teaching Red Hat Developer Hub concepts:

    * Learn RHDH concepts hands-on without Kubernetes complexity
    * Demonstrate RHDH capabilities in workshops or presentations
    * Explore the RHDH ecosystem safely in an isolated environment

### Local Plugin Development

!!! note "Build and Test Plugins Locally 🔌"

    Develop custom plugins with confidence using RHDH Local:

    * Build and test custom dynamic plugins
    * Use plugin scaffolding templates
    * Integrate locally-built plugins for development workflows

## Key Requirements of RHDH Local

To use RHDH Local effectively, you need:

- **Container Runtime**: Podman (preferred) or Docker with Compose support
- **Basic Knowledge**: Familiarity with containers and YAML configuration
- **Local Environment**: Laptop, desktop, or homelab with adequate resources
- **Internet Connection**: For downloading images and accessing external catalogs

## Getting Started

Ready to dive in? Start with our [Getting Started Guide](guides/getting-started.md) for a quick setup, or explore specific topics:

- [Configuration](guides/configuration.md) - Understand RHDH Local configuration
- [Loading Content](guides/loading-content.md) - Configure catalogs, templates, and TechDocs
- [Dynamic Plugin Management](guides/dynamic-plugins-management.md) - Add, remove, and configure plugins  
- [Local Plugin Development](guides/plugins-guide.md) - Build plugins locally
- [Operating RHDH Local](guides/operating-rhdh-local.md) - Start, stop, and manage your instance
- [GitHub Authentication](guides/github-auth.md) - Configure GitHub integration
- [Help & Contributing](guides/help-and-contrib.md) - Get support and contribute back
