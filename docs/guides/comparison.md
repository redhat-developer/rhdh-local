# Comparing Red Hat Developer Hub to CNCF Backstage

Choosing the right internal developer portal (IDP) is a critical decision for engineering teams aiming to improve their developer experience, streamline software delivery, and adopt DevOps best practices. CNCF Backstage has become a popular open-source framework for building IDPs, but it often requires significant customization, manual plugin integration, and ongoing maintenance effort.

Red Hat Developer Hub, built on top of Backstage, offers an enterprise-ready alternative. It provides a curated, fully supported, and production-hardened solution out of the box — eliminating many of the complexities associated with a DIY Backstage setup.

!!! tip "Built on Open Source, Enhanced for Enterprise 🚀"

    Red Hat Developer Hub is built from CNCF Backstage. If you're already using Backstage, you can migrate to RHDH without losing any of the core functionality. RHDH adds enterprise features, support, and production-ready capabilities on top of the open-source foundation.

!!! info "Which Should You Choose?"

    **Choose CNCF Backstage if:**

    * You have a dedicated team to maintain and customize the platform
    * You prefer full control over the codebase and can handle security updates yourself
    * You're comfortable with manual plugin integration at the source code level, regular re-compilation & releases, and ongoing maintenance
    * You don't need enterprise support or RBAC features

    **Choose Red Hat Developer Hub if:**

    * You need enterprise support and production-ready security
    * You want zero-code solutions with dynamic plugins (no recompilation needed)
    * You need RBAC, audit logging, and enterprise authentication
    * You want verified plugin compatibility and a curated extensions catalog
    * You prefer a supported, hardened solution that's ready for production

## Feature Comparison

The comparison matrix below highlights key differences to help enterprise platform engineering teams determine which solution best aligns with their specific needs.

### Core Features

Both platforms share the same foundational features:

| Feature | CNCF Backstage | Red Hat Developer Hub |
|---------|----------------|------------------------|
| **Software Catalog** | ✅ | ✅ |
| **Software Templates (Scaffolder)** | ✅ | ✅ |
| **TechDocs** | ✅ | ✅ |
| **Global Search and Query** | ✅ | ✅ |
| **Kubernetes Helm-based Installer** | ✅ | ✅ |

!!! success "Shared Foundation"

    Both platforms provide the same core developer portal capabilities. The differences lie in enterprise features, support, and operational capabilities.

### Enterprise & Operations

| Feature | CNCF Backstage | Red Hat Developer Hub |
|---------|----------------|------------------------|
| **Kubernetes Operator-based Installer** | ❌ | ✅ |
| **Zero-Code Solution** (no need to maintain Backstage code) | ❌ | ✅ |
| **24x7 Enterprise Support** | ❌ | ✅ |
| **Supported on all major K8s platforms** (GKE, AKS, EKS, OpenShift) | ❌ | ✅ |
| **Enterprise Grade Security** | ❌ | ✅ |
| **Secure RHEL-based UBI Container** | ❌ | ✅ |
| **Fast-track Security Fixes** (Rapid CVE resolution) | ❌ | ✅ |
| **Docker/Podman Local Installation** (faster inner-loop development) | ❌ | ✅ |

!!! warning "DIY vs Enterprise-Ready"

    CNCF Backstage requires you to maintain the codebase, handle security updates, and manage plugin compatibility yourself. Red Hat Developer Hub provides a fully supported, production-hardened solution with enterprise security and support.

### Security & Governance

| Feature | CNCF Backstage | Red Hat Developer Hub |
|---------|----------------|------------------------|
| **Authentication** (e.g., Keycloak federated, Ping Federate) | ❌ | ✅ |
| **Audit Logging** (template/catalog actions) | ❌ | ✅ |
| **Role-Based Access Control (RBAC) with GUI** | ❌ | ✅ |

!!! success "Enterprise Security Built-In 🔒"

    Red Hat Developer Hub includes enterprise authentication, RBAC, and audit logging out of the box—essential features for organizations with compliance and security requirements.

### Plugins & Extensibility

| Feature | CNCF Backstage | Red Hat Developer Hub |
|---------|----------------|------------------------|
| **Dynamic Plug-Ins** (no need to recompile) | ❌ | ✅ |
| **Verified Plugin Compatibility** | ⚠️ (self-verify) | ✅ |
| **Extensions Catalog Plugin** (marketplace) | ❌ | ✅ |
| **Adoption Insights Plugin** (user metrics) | ❌ | ✅ |
| **20+ Red Hat Plugins** (e.g., Tekton, ArgoCD, Kiali, 3scale, ACS, Ansible) | ❌ | ✅ |
| **[Free Software Templates Library](https://github.com/redhat-developer/red-hat-developer-hub-software-templates)** | ❌ | ✅ |

!!! tip "Dynamic Plugins = Faster Innovation 🔌"

    Red Hat Developer Hub's dynamic plugin system means you can add, remove, and update plugins without recompiling the application. This dramatically reduces deployment time, improves uptime, and enables faster iteration.

### Advanced Features

| Feature | CNCF Backstage | Red Hat Developer Hub |
|---------|----------------|------------------------|
| **Workflow Automation Engine** (Orchestrator) | ❌ | ✅ |

!!! info "Workflow Automation"

    The Orchestrator plugin in Red Hat Developer Hub enables you to automate complex workflows and integrate with external systems, providing capabilities beyond the core Backstage features.

## Summary

### When to Choose CNCF Backstage

CNCF Backstage is an excellent choice if you:

* Have a dedicated platform team with Backstage expertise
* Want full control over customization and are comfortable maintaining the codebase
* Don't require enterprise support or RBAC features
* Have the resources to handle security updates and plugin compatibility testing

### When to Choose Red Hat Developer Hub

Red Hat Developer Hub is the better choice if you:

* Need enterprise support and production-ready security
* Want zero-code solutions with dynamic plugins
* Require RBAC, audit logging, and enterprise authentication
* Prefer verified plugin compatibility and a curated extensions catalog
* Want a supported, hardened solution that's ready for production deployment
* Need fast-track security fixes and enterprise-grade containers

!!! success "Best of Both Worlds"

    Red Hat Developer Hub gives you all the power and flexibility of CNCF Backstage, plus enterprise features, support, and production-ready capabilities. You get the open-source innovation with enterprise reliability.

## Learn More

* [What is RHDH and why is it useful?](../getting-started-rhdh/index.md) - Understand the fundamentals
* [Understanding & Using Templates](../getting-started-rhdh/templates.md) - Explore the free templates library
* [Understanding & Using TechDocs](../getting-started-rhdh/techdocs.md) - Learn about documentation features
* [Official Red Hat Developer Hub Documentation](https://docs.redhat.com/en/documentation/red_hat_developer_hub/) - Complete product documentation
* [CNCF Backstage Documentation](https://backstage.io/docs) - Learn about the open-source foundation

*[RHDH]: Red Hat Developer Hub
*[IDP]: Internal Developer Portal
*[RBAC]: Role-Based Access Control
*[CVE]: Common Vulnerabilities and Exposures

