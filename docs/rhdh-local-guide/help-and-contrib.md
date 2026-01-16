RHDH Local is an open-source project maintained by the Red Hat Developer Hub team and the wider community. We welcome feedback, bug reports, and contributions from all engineers using the project.

!!! info "Community-Driven"
    RHDH Local thrives on community contributions. Whether you're reporting bugs, improving documentation, or adding features, your participation helps make RHDH Local better for everyone.

---

## Getting Help

### Before Seeking Help

1. **Check Built-in Documentation**: Review this comprehensive guide and related pages
2. **Search Existing Issues**: Look through [JIRA issues](https://issues.redhat.com/issues/?jql=project%20in%20(%22Red%20Hat%20Developer%20Hub%20Bugs%22%2C%20%22Red%20Hat%20Internal%20Developer%20Platform%22)%20%20AND%20component%20%3D%20%22RHDH%20Local%22%20AND%20resolution%20is%20EMPTY%20ORDER%20BY%20status%2C%20priority%2C%20updated%20%20%20%20DESC) for similar problems
3. **Verify Your Setup**: Ensure you meet the [prerequisites](getting-started.md#prerequisites)

### Support Channels

#### JIRA Issues (Bug Reports and Feature Requests)

Use [JIRA (Component: RHDH Local)](https://issues.redhat.com/browse/RHIDP) for:

- **Bugs and errors** in RHDH Local functionality
- **Unexpected behavior** that differs from documentation
- **Installation or setup problems** that persist after troubleshooting
- **Feature requests** with clear use cases

!!! tip "Issue Reporting"
    To report issues against RHDH Local, use [JIRA](https://issues.redhat.com/browse/RHIDP) with Component: **RHDH Local**. You can browse existing issues using this [query](https://issues.redhat.com/issues/?jql=project%20in%20(%22Red%20Hat%20Developer%20Hub%20Bugs%22%2C%20%22Red%20Hat%20Internal%20Developer%20Platform%22)%20%20AND%20component%20%3D%20%22RHDH%20Local%22%20AND%20resolution%20is%20EMPTY%20ORDER%20BY%20status%2C%20priority%2C%20updated%20%20%20%20DESC).

**When opening an issue, include:**

```markdown
**Environment:**
- RHDH Local version: [git commit hash]
- Container runtime: [Podman/Docker + version]
- Operating system: [OS + version]
- Available resources, if available: [RAM, CPU, disk space]

**Problem Description:**
[Clear description of what you expected vs. what happened]

**Steps to Reproduce:**
1. [First step]
2. [Second step]
3. [Observed Result]
4. [Expected Result]

**Logs and Configuration:**
[Relevant logs from `podman compose logs` or `docker compose logs`]
[Configuration snippets (remove sensitive data)]
[Screenshots if applicable]

**Additional Context:**
[Any other relevant information]
```

#### Community Guidelines

- **Be respectful** and constructive in all interactions
- **Search before posting** to avoid duplicates
- **Provide context** and details when asking questions
- **Follow up** on your issues and discussions
- **Help others** when you can share knowledge

---

## Contributing

We actively encourage contributions of all types! Here's how you can help:

### Types of Contributions

#### Bug Reports and Fixes

- **Identify and report bugs** with detailed reproduction steps
- **Submit patches** for bugs you can fix
- **Test fixes** from other contributors

#### Feature Development

- **Propose new features** through JIRA
- **Implement approved features** following project guidelines
- **Improve existing functionality** with backwards compatibility

#### Documentation Improvements

- **Update guides** for clarity and accuracy
- **Add missing documentation** for new features
- **Fix typos and formatting** issues
- **Translate content** (if applicable)

#### Configuration and Examples

- **Share working configurations** for common use cases
- **Create example setups** for specific scenarios
- **Document best practices** from real-world usage

### Contribution Workflow

#### 1. Prepare Your Environment

```bash
# Fork the repository on GitHub
# Clone your fork locally
git clone https://github.com/YOUR-USERNAME/rhdh-local.git && cd rhdh-local

# Add upstream remote for staying current
git remote add upstream https://github.com/redhat-developer/rhdh-local.git

# Create a development branch
git checkout -b feature/my-contribution
```

#### 2. Development Guidelines

**Code Contributions:**

- Follow existing code style and conventions
- Write clear, descriptive commit messages
- Include appropriate tests for new functionality
- Ensure changes don't break existing functionality, as much as possible

**Documentation Contributions:**

- Use clear, practical language written "engineer-to-engineer"
- Include code examples and practical snippets
- Test documentation by following your own instructions
- Maintain consistent formatting with existing docs

**Configuration Contributions:**

- Test configurations thoroughly before submitting
- Document any prerequisites or limitations
- Include examples for common use cases
- Remove sensitive information (tokens, passwords)

#### 3. Review Process

- **Automated checks** will run on your PR
- **Maintainers** will review your contribution
- **Address feedback** promptly and professionally
- **Iterate** based on review comments
- **Celebrate** when your contribution is merged!

---

## Contributing to Built-in TechDocs

The documentation you're reading now is built into RHDH Local and automatically rendered as TechDocs in the running application. Contributing to this documentation is especially valuable!

### Documentation Structure

```
mkdocs.yaml                     # The documentation site index
docs/
├── index.md                    # Main introduction (Welcome page)
├── OWNERS                      # Documentation owners
├── images/                     # Embedded images
├── getting-started-rhdh/       # Getting Started Guide for RHDH users
│   ├── index.md
│   ├── highlights.md
│   ├── comparison.md
│   ├── navigation.md
│   ├── search.md
│   ├── software-catalog.md
│   ├── apis.md
│   ├── techdocs.md
│   ├── making-techdocs-appealing.md
│   ├── templates.md
│   ├── templates-authoring.md
│   ├── ten_template_tips.md
│   ├── extensions.md
│   ├── developer-lightspeed.md
│   └── references.md
└── rhdh-local-guide/           # RHDH Local User Guide
    ├── index.md
    ├── getting-started.md
    ├── configuration.md
    ├── loading-content.md
    ├── dynamic-plugins-management.md
    ├── plugins-guide.md
    ├── github-auth.md
    ├── container-image-guide.md
    ├── corporate-proxy-setup-sim.md
    ├── postgresql-guide.md
    ├── operating-rhdh-local.md
    └── help-and-contrib.md     # This file
```

### Documentation Standards

#### Content Guidelines

- **Engineer-to-engineer perspective**: Write for technical users who prefer concise, practical information
- **Step-by-step instructions**: Break complex processes into clear, numbered steps
- **Code examples**: Include working examples that users can copy and modify
- **Cross-references**: Link to related documentation appropriately
- **Troubleshooting focus**: Anticipate common issues and provide solutions
- Update `mkdocs.yaml` if adding new pages or changing structure

#### Formatting Standards

See [Making Your TechDocs More Appealing](../getting-started-rhdh/making-techdocs-appealing.md) for practical tips on using TechDocs.

#### Testing Documentation

1. **Write the documentation** following the standards above
2. **Test the instructions** by following them yourself on a fresh setup
3. **Preview in RHDH Local** to verify formatting and links work
4. **Have someone else test** your instructions (when possible)

#### TechDocs Review Process

Note that TechDocs changes may need to be reviewed by a Product Manager and/or Architect to ensure content accuracy, clarity, and alignment with user needs.

#### Best Practices for TechDocs Contributions

- **Start small**: Begin with minor improvements to learn the workflow
- **Collaborate early**: Discuss major documentation changes via [JIRA issues](https://issues.redhat.com/issues/?jql=project%20in%20(%22Red%20Hat%20Developer%20Hub%20Bugs%22%2C%20%22Red%20Hat%20Internal%20Developer%20Platform%22)%20%20AND%20component%20%3D%20%22RHDH%20Local%22%20AND%20resolution%20is%20EMPTY%20ORDER%20BY%20status%2C%20priority%2C%20updated%20%20%20%20DESC) before investing significant effort
- **Keep it practical and engineer-oriented**: Keep the built-in TechDocs oriented toward engineers with practical commands. The goal is not to repeat the official RHDH documentation
- **Update regularly**: Keep documentation current as features evolve
- **Ask for help**: Reach out to the team if you're unsure about content direction
