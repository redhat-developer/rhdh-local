The API browser in Red Hat Developer Hub provides a centralized way to discover, view, and test APIs registered in your organization. Instead of searching through multiple documentation sites or API gateways, you can find all your APIs in one place and interact with them directly from the Developer Hub interface.

## What are APIs and why are they important?

**APIs** (Application Programming Interfaces) define how different software components communicate with each other. In Red Hat Developer Hub, APIs are catalog entities that represent API definitions, making them discoverable alongside your other software components.

!!! info "API Discovery"

    The API browser helps you:
    
    * **Discover available APIs** - Find APIs that your organization has built or acquired
    * **Understand API contracts** - View API definitions to understand what endpoints are available
    * **Test APIs interactively** - Try out API endpoints directly in the browser without leaving Developer Hub
    * **See API relationships** - Understand which components use which APIs

!!! tip "API Formats Supported"

    Red Hat Developer Hub supports API specification formats including **OpenAPI** (formerly Swagger) for REST APIs. The platform may also support other formats like AsyncAPI and GraphQL depending on your version and configuration. Check with your administrator or see the [official Backstage API documentation](https://backstage.io/docs/features/software-catalog/descriptor-format#kind-api) for the most current list of supported formats.

### Why APIs Matter in Developer Hub

APIs are first-class citizens in the Software Catalog, just like services and components. This means:

**Centralized Discovery**

Instead of hunting through multiple API gateways, documentation sites, or asking colleagues, you can browse and [search](search.md) all available APIs in one place. On discovering an API, you can read more information (including [TechDocs](techdocs.md) for the API if they're available) and 'favourite' an API so you can quickly navigate to it at any time using the [GlobalHeader](navigation.md).

**Interactive Testing**

You can test API endpoints directly in the Developer Hub interface, similar to tools like Swagger UI or Postman, without switching to external applications.

**Context and Relationships**

APIs appear alongside the components that use them, helping you understand how different parts of your system connect.

## Finding and viewing APIs

APIs in Red Hat Developer Hub are accessible through the left navigation pane and the Software Catalog.

### From the Left Navigation Pane

1. Click on **"APIs"** in the left-hand navigation menu (indicated by a puzzle piece icon 🧩)
2. You'll see a list of all APIs registered in your organization
3. Click on any API to view its details

!!! tip "Quick Access"

    The APIs navigation item provides a dedicated view of all APIs, making it easy to browse and discover what's available across your organization.

### From the Software Catalog

APIs also appear in the [Software Catalog](software-catalog.md) alongside other catalog entities:

1. Navigate to the [Software Catalog](software-catalog.md)
2. Use the **Kind** filter to show only APIs, or browse all entities
3. Click on an API entity to view its details

### Viewing API Details

When you select an API, you'll see several tabs:

* **Overview** - General information about the API, including owner, lifecycle status, links, and relations
* **Definition** - The API specification (OpenAPI etc.) rendered in a readable format

The Definition tab shows:

* **API Information** - Title, version, and description
* **Servers** - Base URLs where the API is hosted
* **Operations** - Available endpoints (GET, POST, PUT, DELETE, etc.) with descriptions
* **Schemas** - Data models used by the API

!!! info "Swagger-like Interface"

    The API definition view provides a familiar, Swagger-like interface that makes it easy to understand API structure and available operations.

## Testing APIs in the Developer Hub GUI

One of the most powerful features of the API browser is the ability to test API endpoints directly within Developer Hub.

### How to Test an API

1. **Navigate to an API** - Find the API you want to test using the methods described above
2. **Select the Definition tab** - This shows the API specification (if it has been provided)
3. **Find the operation** - Browse to the endpoint you want to test (e.g., `POST /api/analyze`)
4. **Expand the operation** - Click on the endpoint to see its details
5. **Try it out** - Click the 'Try It Out' button to reveal the test interface
6. **Fill in parameters** - Enter any required parameters or request body
7. **Execute the request** - Send the request and view the response

!!! success "Interactive Testing"

    You can test API endpoints without leaving Developer Hub or opening external tools like Postman. This makes it easy to explore APIs and verify they're working correctly.

!!! warning "Authentication Required"

    Some APIs may require authentication. If you encounter authentication errors, contact the API owner or your administrator for access credentials.

### Understanding API Responses

When you test an API endpoint, you'll see:

* **Response status code** - Whether the request succeeded (200, 201) or failed (400, 401, 500, etc.)
* **Response body** - The data returned by the API
* **Response headers** - Additional metadata about the response

## Adding APIs to a component

APIs are typically registered in the Software Catalog by the API owners. However, understanding how APIs are added helps you know what to expect and how to add new APIs to the catalog.

### How APIs Are Registered

APIs are defined alongside catalog entities using YAML or JSON descriptor files (similar to how components are defined). These files specify:

* API name and description
* API specification location
* Owner and lifecycle information
* Relationships to other components

### Linking APIs to Components

APIs can be linked to components in the Software Catalog, showing which services use which APIs. This helps you understand:

* Which components depend on a particular API
* What APIs a component uses
* The relationships between your services and APIs

## Learning more

### Official Documentation

For detailed information about APIs in Red Hat Developer Hub, see:

* [Backstage API Docs Plugin](https://backstage.io/docs/features/software-catalog/descriptor-format#kind-api) - How APIs are defined in the catalog
* [Backstage Software Catalog API Documentation](https://backstage.io/docs/features/software-catalog/) - Catalog entity format and API definitions

### Related Features

APIs work closely with other Red Hat Developer Hub features:

* [Understanding & Using the Software Catalog](software-catalog.md) - Learn how APIs are part of the catalog
* [Using Search](search.md) - Find APIs using global search
* [Understanding & Using TechDocs](techdocs.md) - Document your APIs with TechDocs

!!! success "Start Exploring"

    The best way to learn about APIs in Developer Hub is to explore! Navigate to the APIs section and browse the available APIs in your organization. Try testing some endpoints to see how the interactive API browser works.

*[RHDH]: Red Hat Developer Hub
