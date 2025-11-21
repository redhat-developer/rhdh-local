The Software Catalog is the heart of Red Hat Developer Hub. It's a centralized inventory of all your software components, services, APIs, and resources—giving you a complete view of your software ecosystem in one place.

## What is the catalog and why is it useful?

The **Software Catalog** is RHDH's core feature that maintains a comprehensive inventory of all software assets in your organization. Think of it as a living directory that automatically tracks and displays information about your software components, their relationships, ownership, and status.

!!! success "Centralized Software Inventory"
    The catalog provides a single source of truth for:
    
    * All services, applications, and microservices
    * APIs and API definitions
    * Libraries and shared components
    * Websites and frontend applications
    * Infrastructure resources
    * Teams, users, and their relationships to software

### Why the Catalog Matters

The Software Catalog delivers value across your entire organization. Here's what each group gains:

!!! info "For Developers 🚀"

    🔍 **Discover existing services** - Find what's already built before creating something new

    🔗 **Understand dependencies** - See how components relate to each other

    👥 **Find owners and experts** - Know who to contact for questions or collaboration

    📚 **Access documentation** - Link directly to TechDocs and API documentation

!!! info "For Platform Teams 🔧"

    👁️ **Complete visibility** - See everything that's running in your organization

    📋 **Track ownership** - Know who's responsible for each component

    🔄 **Monitor lifecycle** - Track which services are in production, development, or deprecated

    ✅ **Enforce standards** - Ensure components follow organizational best practices

!!! info "For Organizations 🏢"

    ♻️ **Reduce duplication** - Discover existing solutions before building new ones

    🛡️ **Improve governance** - Maintain an accurate inventory of all software assets

    🤝 **Enable collaboration** - Make it easy for teams to find and reuse components

    📊 **Support compliance** - Track what's deployed and where

### What's in the Catalog?

The catalog can contain various types of entities:

**Components**

* Services, websites, libraries, and other software components
* Each component includes metadata like owner, lifecycle status, and relationships

**APIs**

* API definitions and specifications
* Documentation and testing capabilities

**Systems**

* Groups of related components that work together
* Help organize complex software architectures

**Domains**

* Logical groupings of systems and components
* Represent business domains or organizational boundaries

**Users and Groups**

* People and teams in your organization
* Their relationships to components and systems

**Resources**

* Infrastructure resources, databases, AI assets, and other dependencies

## Using the catalog (filtering etc.)

The Catalog page provides powerful tools to explore, filter, and manage your software inventory.

### Accessing the Catalog

1. Click **Catalog** in the left-hand navigation sidebar
2. You'll see a comprehensive view of all catalog entities

![Red Hat Developer Hub Software Catalog](../images/software-catalog.png)

### Catalog View Features

**Entity Cards**

* Each component, API, or resource is displayed as a card
* Cards show key information: name, description, owner, lifecycle status, and type
* Click any card to view detailed information about that entity

**Filtering Options**

The catalog provides multiple ways to filter and find what you need:

**By Kind**

* Filter to show only Components, APIs, Systems, Domains, Users, Groups, or Resources
* Useful when you know what type of entity you're looking for

**By Type**

* Filter components by their specific type (service, website, library, etc.)
* Helps narrow down results within a category

**By Owner**

* Filter by team or individual owner
* Find all components owned by a specific team or person
* Great for discovering what a team is working on

**By Lifecycle**

* Filter by lifecycle status (production, development, experimental, deprecated)
* Find only production-ready components
* Identify components that need attention or updates

**By Tags**

* Filter by tags or labels applied to components
* Find components with specific characteristics
* Discover related components through common tags

**Search Within Catalog**

* Use the search bar at the top of the catalog page
* Search by name, description, owner, or tags
* Results update as you type



### Viewing Component Details

When you click on a component card, you'll see a detailed view with:

**Overview Tab**

* Component name, description, and metadata
* Owner and team information
* Lifecycle status and tags
* Links to documentation, source code, and related resources (where available)

**Relationships**

* Visual representation of how the component connects to other entities
* Dependencies and dependents
* Part of systems or domains

**APIs Tab**

* API definitions associated with the component
* Test APIs directly from the catalog

**Docs Tab**

* Technical documentation for the component (TechDocs)
* Access guides, runbooks, and other documentation (where available)

**CI/CD Tab**

* Build and deployment information (when configured)
* Pipeline status and history (when configured)
* Integration with CI/CD tools (when configured)

**Other Plugin Tabs**

* Additional information from enabled plugins  (when configured)
* Monitoring, security, cost, and other metrics

### Catalog Best Practices

Make the most of the Software Catalog by following these tips to streamline your workflow and improve your productivity:

!!! tip "Use Filters Strategically"
    Find exactly what you need quickly and efficiently:

    * Start broad, then narrow with filters
    * Combine multiple filters for precise results
    * Save common filter combinations as bookmarks

!!! tip "Explore Relationships"
    Understand your software ecosystem better:

    * Click on owners to see their other components
    * Follow dependency links to understand system architecture
    * Use tags to discover related components

!!! tip "Stay Updated"
    Keep your catalog organized and current:

    * Star frequently used components for quick access from the Global Header
    * Check lifecycle status to identify components needing attention
    * Review ownership to ensure components have clear maintainers

## Adding new items to the catalog

There are several ways to add components and other entities to the Software Catalog. The method you choose depends on your needs and organizational setup.

### Method 1: Using Software Templates (Recommended)

The easiest way to add a new component is through a software template:

1. Click the **Self-Service button** (`+`) in the Global Header
2. Select a template that includes catalog registration (like "[Register Existing Component to Software Catalog](/create/templates/default/register-component)")
3. Fill in the required information:

   * Component name and description
   * Owner (team or individual)
   * Repository location
   * Component type

4. The template will create the component and register it in the catalog automatically

!!! tip "Templates Handle Everything"
    Software templates can automatically:
    
    * Create the `catalog-info.yaml` file
    * Register the component in the catalog
    * Set up initial relationships and metadata
    * Configure integrations with other tools

### Method 2: Manual Registration with `catalog-info.yaml`

For existing components, you can manually register them by adding a `catalog-info.yaml` file to your repository:

**Step 1: Create catalog-info.yaml**

Create a file named `catalog-info.yaml` in the root of your repository:

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: my-service
  description: A description of my service
  tags:
    - service
    - api
  annotations:
    backstage.io/techdocs-ref: dir:.
spec:
  type: service
  lifecycle: production
  owner: platform-team
  system: my-system
```

**Step 2: Configure Catalog Location**

You or your administrator needs to add your repository location to the catalog configuration. This can be done using the ["self service"](/catalog-import) feature in the Global Header or it can be done in the RHDH instance's `app-config.yaml` file on boot:

```yaml
catalog:
  locations:
    - type: url
      target: https://github.com/your-org/your-repo/blob/main/catalog-info.yaml
```

**Step 3: Catalog Processing**

The catalog will automatically discover and process your `catalog-info.yaml` file, registering your component.

!!! note "Catalog Refresh"
    The catalog periodically refreshes to discover new or updated entities. This typically happens every few minutes, but the exact interval depends on your RHDH configuration.

### Method 3: Bulk Import

For organizations with many existing components, bulk import tools may be available:

* **Bulk Import Plugin** - If enabled, allows importing multiple components at once

* **API Integration** - Programmatically register components via the catalog API

* **Configuration Files** - Add multiple components via YAML files in configured locations

Contact your administrator to learn about bulk import options available in your RHDH instance.

### What Information to Include

When adding a component to the catalog, include:

**Required Information**

* Component name (unique identifier)
* Component type (service, website, library, etc.)
* Owner (team or individual responsible)

**Recommended Information**

* Description - What the component does
* Lifecycle status - production, development, experimental, deprecated
* Tags - Keywords for filtering and discovery
* Links - Source code, documentation, runbooks
* System/Domain - Organizational grouping

**Optional but Valuable**

* API definitions
* Dependencies and relationships
* TechDocs reference
* CI/CD integration details
* Monitoring and observability links

### Updating Catalog Entries

**Automatic Updates**

* The catalog automatically refreshes to pick up changes to `catalog-info.yaml` files
* Metadata and relationships update based on your repository contents

**Manual Updates**

* Edit the `catalog-info.yaml` file in your repository
* Commit and push changes
* The catalog will process updates on the next refresh cycle


### Best Practices for Catalog Entries

Follow these guidelines to ensure your catalog entries are useful, discoverable, and maintainable:

!!! tip "Keep Information Current"
    Maintain accurate and up-to-date catalog entries:

    * Update lifecycle status as components evolve
    * Maintain accurate ownership information
    * Keep descriptions and documentation links up to date

!!! tip "Use Consistent Naming"
    Make components easy to find and understand:

    * Follow organizational naming conventions
    * Use clear, descriptive names
    * Avoid abbreviations unless widely understood

!!! tip "Leverage Tags"
    Improve discoverability through strategic tagging:

    * Use consistent tag naming across components
    * Tag by technology, team, domain, or purpose
    * Make components discoverable through relevant tags

!!! tip "Document Relationships"
    Build a clear picture of your software architecture:

    * Define dependencies and dependents
    * Group related components into systems
    * Organize systems into domains

!!! tip "Link Everything"
    Connect your catalog to all relevant resources:

    * Connect to source code repositories
    * Link to documentation and TechDocs
    * Include monitoring, CI/CD, and other tool links

### Next Steps

Now that you understand the Software Catalog, explore related features:

* [Review The Full Catalog Descriptor Format](https://backstage.io/docs/features/software-catalog/descriptor-format/) - Learn the complete `catalog-info.yaml` file format and structure
* [Understanding & Using TechDocs](techdocs.md) - Add documentation to your catalog components
* [Understanding & Using APIs](apis.md) - Register and document APIs in the catalog
* [Understanding & Using Templates](templates.md) - Use templates to create and register components
* [Using Search](search.md) - Find catalog items quickly with search


*[RHDH]: Red Hat Developer Hub

