# Understanding & Using TechDocs

TechDocs is Red Hat Developer Hub's built-in documentation system that brings your technical documentation directly into the developer portal. Instead of hunting through wikis, README files, or separate documentation sites, TechDocs makes all your documentation discoverable, searchable, and accessible right where developers need it—alongside the components they're working with.

## What are TechDocs and why are they useful?

**TechDocs** stands for "Technical Documentation" and represents a "documentation as code" approach to managing your technical content. In RHDH, TechDocs are Markdown-based documentation files that live alongside your source code in version control, making them easy to maintain, review, and keep up-to-date.

!!! info "Documentation as Code"

    TechDocs follow the same principles as infrastructure as code: your documentation is versioned, reviewed through pull requests, and maintained alongside your codebase. This ensures documentation stays current and reflects the actual state of your software.

### Why TechDocs Matter

Traditional documentation often suffers from being outdated, scattered across multiple locations, or difficult to find when you need it. TechDocs solves these problems by integrating documentation directly into your developer portal.

!!! tip "Always Up-to-Date 🔄"

    Since TechDocs live in your source code repository, they're updated as part of your development workflow. When code changes, documentation can be updated in the same pull request, ensuring they stay in sync.

!!! info "Discoverable and Searchable 🔍"

    All TechDocs are automatically indexed and searchable through RHDH's [global search](search.md). Developers can find documentation without knowing exactly where it lives or what it's called or even which coding project it belongs to.

!!! success "Context-Aware 📍"

    Documentation appears directly on the component page in the Software Catalog (and in the right hand [navigation](navigation.md)), giving developers immediate access to relevant information without leaving their workflow.

!!! note "Standardized Format 📝"

    TechDocs use Markdown and [MkDocs](https://www.mkdocs.org/), providing a consistent format across all documentation while still allowing rich formatting, code examples, diagrams, and more.

### Common Use Cases

TechDocs are perfect for documenting your microservices, components, deployment procedures, architecture decisions, troubleshooting guides, onboarding instructions, and any other technical information your team needs. They're particularly valuable for microservices architectures where understanding each service's purpose, dependencies, and usage patterns is critical.

## Finding and viewing techdocs

Finding TechDocs in RHDH is straightforward. The most common way is through the [Software Catalog](software-catalog.md), where documentation is automatically linked to components.

### From the Software Catalog

When you view any component in the [Software Catalog](software-catalog.md), you'll see a **"Docs"** tab if TechDocs are available for that component. Simply click the tab to view the documentation. The documentation appears inline, so you don't need to navigate away from the component page.

!!! tip "Quick Access"

    The Docs tab appears automatically when a component has TechDocs configured. You don't need to do anything special—just browse to any component and look for the Docs tab in the component details view.

### From the Left Navigation Pane

You can also access TechDocs directly from the left-hand navigation pane. Click on the **"Docs"** item in the navigation menu to view all available TechDocs in your organization. This provides a centralized view of all documentation, making it easy to browse and discover documentation across different components and services.

When you click on "[Docs](/docs)" in the navigation pane, you'll see a list of all components that have TechDocs available. You can browse through this list, search for specific documentation, or click on any item to view its TechDocs directly.

!!! info "Direct Access"

    The "Docs" navigation item gives you a documentation-focused view of your entire [software catalog](software-catalog.md), filtering to show only components with available TechDocs. This is particularly useful when you want to explore documentation without navigating through the full Software Catalog.

### Using Search

You can also find TechDocs through RHDH's [global search](search.md). Type your search query in the search bar at the top of the page, and TechDocs content will appear in the search results alongside components, APIs, and other catalog items. This makes it easy to find documentation even when you're not sure which component it belongs to.

!!! note "Search Across All Docs"

    The [search](search.md) feature indexes the full content of all TechDocs, not just titles. This means you can search for specific concepts, error messages, or procedures and find relevant documentation across your entire organization.

### Navigation Within TechDocs

Once you're viewing TechDocs, you'll see a table of contents on the left side that helps you navigate through the documentation hierarchy. TechDocs support multiple pages and hierarchical organization, so complex documentation can be structured logically with clear navigation paths.

On the right hand side (space permitting) you'll see a list of all the sections within the current open document, so you can navigate to subheadings and important content quickly.

When you hover over a heading in your TechDoc, you'll notice a sharable link is available in the browser's address bar. Share this URL with colleagues to help them quickly navigate to documents and subsections with just one click.

### TechDocs Add-ons

TechDocs supports add-ons that enhance your documentation experience with additional functionality. Some add-ons are preinstalled and enabled by default, while others can be dynamically loaded to extend TechDocs capabilities. Add-ons can provide features like issue reporting, text size controls, lightbox image viewing, and more. For information on configuring and using TechDocs add-ons, see the [official TechDocs documentation](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.8/html-single/techdocs_for_red_hat_developer_hub/index).

## Writing TechDocs & adding TechDocs to a component

Creating TechDocs for your components is a straightforward process that follows the "documentation as code" philosophy. Your documentation lives in your repository alongside your source code.

### Setting Up TechDocs

TechDocs use MkDocs, a popular static site generator that converts Markdown files into beautiful documentation. To add TechDocs to a component, you need to create a `docs` folder in your repository and add a `mkdocs.yaml` configuration file.

!!! info "Standard Structure"

    Most TechDocs setups follow this structure:
    
    * A `docs/` directory containing your Markdown files
    * A `docs/index.md` that would act as a starting point for your content pages
    * An `mkdocs.yaml` file at the root (alongside your `catalog-info.yaml`) that defines the documentation structure
    * Optionally, an `docs/images/` or `docs/assets` folder to store files, diagrams, and screenshots

    ```text
    docs/
    docs/index.md
    docs/images
    mkdocs.yaml
    catalog-info.yaml (more on this later)
    ```

The `mkdocs.yaml` file defines your documentation's navigation structure, similar to how a table of contents works. You can organize your documentation into sections, subsections, and pages as needed. 

Here's a short example of how you might begin your first `mkdocs.yaml` documentation index:

```yaml
plugins:
  - techdocs-core
nav:
  - "Introduction": index.md # <-- The index file would be under docs/index.md
```

!!! tip "Need An Example?"

    Examine the docs in the [RHDH Local GitHub repository](https://github.com/redhat-developer/rhdh-local) to see a fully working TechDocs documentation hierarchy.

### Writing Your Documentation

Write your TechDocs using Markdown, which provides a simple yet powerful way to format text, include code blocks, create lists, and add links. MkDocs Material (the theme used by TechDocs) extends Markdown with additional features like callouts, tabs, and more advanced formatting options.

!!! tip "Make It Engaging"

    Use callouts, emojis, and visual elements to make your documentation more engaging. The [Making TechDocs Appealing](../guides/making-techdocs-appealing.md) guide shows you how to use these features effectively.

When writing, focus on clarity and completeness. Include information about what the component does, how to use it, how to deploy it, and how to troubleshoot common issues. Remember that your audience might be developers who are new to your component, so provide context and examples.

### Connecting TechDocs to Your Component

To link TechDocs to a component in the Software Catalog, you need to add an annotation to your component's `catalog-info.yaml` file. The annotation tells RHDH where to find your documentation.

Add the `techdocs-ref` annotation to your component's `metadata` section:

```yaml
metadata:
  name: my-component
  description: |
    Description of my component
    ...
  annotations:
    backstage.io/techdocs-ref: dir:. # <-- Use this to tell Developer Hub that the mkdocs.yaml is in the same location
```

The `dir:.` value tells TechDocs to look for the documentation index (the `mkdocs.yaml`) in the same directory as the `catalog-info.yaml` file. You can also specify a relative path if your documentation is in a different location.

!!! success "Automatic Discovery"

    Once you add the annotation and commit your changes, RHDH will automatically discover and index the TechDocs attached to any registered component. The next time someone views your component, they'll see the Docs tab with your documentation.

### Best Practices

* **Keep your documentation close to your code—literally**. Store TechDocs in the same repository as your component so they evolve together. Update documentation as part of your code review process, and treat documentation changes with the same importance as code changes.

* **Write for your audience**. Consider who will be reading your documentation and what they need to know. New team members need different information than experienced developers who are troubleshooting a specific issue.

* **Keep it current**. Outdated documentation is worse than no documentation because it misleads readers. Make updating documentation a natural part of your development workflow, not an afterthought.

!!! tip "Start Simple"

    You don't need to document everything at once. Start with the essentials: what the component does, how to get it running, and how to use it. You can always expand your documentation over time as you learn what information is most valuable to your team.

### Next Steps

Now that you understand TechDocs, you might want to explore:

* [Understanding & Using the Software Catalog](software-catalog.md) - Learn how components and TechDocs work together
* [Making TechDocs Appealing](../guides/making-techdocs-appealing.md) - Discover advanced formatting techniques
* [Official TechDocs Documentation](https://backstage.io/docs/features/techdocs/) - Deep dive into TechDocs configuration and features

*[RHDH]: Red Hat Developer Hub

