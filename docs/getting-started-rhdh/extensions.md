Red Hat Developer Hub (RHDH) is designed to be infinitely extensible. While it comes with a powerful set of core features out of the box, its true power lies in its ability to grow and adapt to your organization's needs through **Extensions** (also known as **Plugins**).

## What are Extensions and why are they important?

Think of Red Hat Developer Hub as a smartphone. Out of the box, it makes calls, sends texts, and takes photos. But it's the **apps** you install that make it truly personal and powerful—turning it into a bank, a map, a game console, or a fitness tracker.

In RHDH, **Plugins are the apps**. They add new capabilities, integrate with external tools, and customize the user interface.

!!! success "Plugins Are Everywhere 🧩"
    You might not realize it, but you're already using plugins! Many of the "core" features you use every day—like the Homepage, [Software Catalog](/catalog), [TechDocs](/docs), and [Search](/search)—are actually plugins that come pre-installed. This modular design means almost every part of the Developer Hub experience can be customized or replaced.

### Why Plugins Matter

*   **Integrate Your Tools**: Connect RHDH to the tools you already use (Jira, Jenkins, ArgoCD, SonarQube, etc.).
*   **Add New Features**: Add capabilities like cost insights, calendar widgets, or AI assistants.
*   **Customize the Experience**: Tailor the dashboard and entity pages to show exactly what your team needs.

## Plugins in the Left Hand Navigation

One of the most common places you'll see plugins is in the main [navigation](navigation.md) sidebar. These plugins usually provide global features that apply across your entire organization.

!!! tip "Example: TechDocs 📚"
    Take a look at the [**"Docs"**](/docs) item in your left-hand navigation. This is powered by the **TechDocs** plugin.
    
    While it feels like a built-in part of the platform, it's actually a plugin that fetches Markdown files from your repositories and renders them as documentation sites. This seamless integration is the hallmark of a well-designed plugin.

Other examples of navigation plugins might include:

*   **Tech Radar**: To visualize approved technologies in your organization.
*   **Cost Insights**: To track cloud spend.
*   **Developer Lightspeed**: For AI-assisted development.

## Plugins in Catalog Entities

Plugins also live inside the specific pages for your components, services, and APIs. These are "Entity Plugins" that provide context-aware information for the specific software you are looking at.

!!! info "Example: CI/CD Status 🚀"
    When you view a component in the Software Catalog, you might see a **"CI"** tab or a widget showing the status of your latest builds.
    
    This isn't magic; it's a plugin (like the Jenkins, GitHub Actions, or Tekton plugin) talking to your build server. It knows *which* build to show because of an annotation in your component's `catalog-info.yaml` file.

Integrating these entity plugins means you don't have to leave Developer Hub to check if your build passed, see your code coverage results, or view your Kubernetes deployments. The plugins bring that data right to you.

## Discovering Plugins

How do you know what plugins are available?

Red Hat Developer Hub includes a built-in [**Extensions**](/extensions) marketplace (sometimes called the "Extensions Plugin") that lists available plugins.

!!! note "For Administrators Only 🔒"
    The Extensions marketplace is primarily a tool for **Administrators** and **Platform Engineers**. It allows them to see which plugins are installed, which are available, and to manage their configuration.
    
    As a user, you typically won't use this page to "install" plugins yourself. Instead, you'll work with your administrator to request the plugins your team needs.

This internal catalog helps your platform team discover and evaluate new capabilities that can be added to your Developer Hub instance.

## From "Static" to "Dynamic"

You might hear your platform engineers talking about "Static Plugins" or "Dynamic Plugins."

*   **Static Plugins**: The "old way" (standard Backstage). Adding a plugin required writing code and recompiling the entire portal.
*   **Dynamic Plugins**: The "RHDH way." Plugins can be added, removed, or updated without rebuilding the code.

!!! success "Why Dynamic is Better ⚡"
    For you as a user, Dynamic Plugins mean **less downtime**. Admins can enable new features or update existing ones much faster, getting new capabilities into your hands without a maintenance window.

## Working with Admins to Enable Plugins

Since RHDH is a shared platform, you usually can't "install" a plugin yourself like you would an app on your phone. Plugins are managed by your Platform Engineering team or Administrators to ensure security and stability.

### How to Request a Plugin

If you see a tool your team uses (like Sentry for error tracking or PagerDuty for incidents) and want to see it inside Developer Hub:

1.  **Check the Catalog**: Administrators can check the internal [**Extensions**](/extensions) page. You can also look at the [Red Hat Ecosystem Catalog](https://catalog.redhat.com/en/developerhubplugins) website or [Backstage Plugin Directory](https://backstage.io/plugins) to see if a plugin exists.
2.  **Contact Your Admin**: Reach out to your RHDH administrator.
3.  **Provide Context**: Explain *why* this integration would help your team (e.g., "It would save us 10 minutes per incident if we could see PagerDuty alerts directly on the entity page").

!!! tip "Make the Case"
    The best argument for a new plugin is productivity. If a plugin saves you from context-switching between three different browser tabs, your admin will likely want to enable it!

### Related Docs For Admins

* [**Dynamic Plugins Management Guide**](../rhdh-local-guide/dynamic-plugins-management.md) - Delves a little deeper into how to work with RHDH dynamic plugins

*[RHDH]: Red Hat Developer Hub
