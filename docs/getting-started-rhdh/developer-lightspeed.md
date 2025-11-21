Developer Lightspeed for Red Hat Developer Hub (often shortened to "Developer Lightspeed for RHDH" or simply "Lightspeed") is a general-purpose AI-powered virtual assistant designed to help developers with a multitude of daily questions and tasks. Whether you need help with coding, debugging, understanding technologies, or navigating Red Hat Developer Hub, Developer Lightspeed is available 24/7 to provide assistance. Developer Lightspeed is an optional feature (an '[extension](extensions.md) or plugin') that must be installed and configured by your administrator, so it may not be available on your Developer Hub instance.

## What is Developer Lightspeed and why is it useful?

**Developer Lightspeed for RHDH** is a natural language interface powered by generative AI that serves as your general-purpose development assistant. It can help with coding questions, technology explanations, troubleshooting, best practices, and much more. When answering questions about Red Hat Developer Hub specifically, it can provide accurate, cited answers based on official documentation.

!!! info "AI-Powered 🤖"

    Developer Lightspeed uses Generative AI LLM models and Retrieval Augmented Generation (RAG) technology, which means when answering questions about Red Hat Developer Hub, it has access to official documentation and can provide accurate, cited answers based on those sources. For general development questions, it leverages its entire model training data to provide helpful guidance and explanations.

!!! tip "Always Available 💬"

    Unlike waiting for a colleague to be available or searching through multiple documentation sites, Developer Lightspeed is always ready to help. Ask questions at any time, in any order, and get immediate responses to a wide variety of development-related questions.

!!! success "General-Purpose 🛠️"

    Developer Lightspeed isn't limited to Red Hat Developer Hub questions (assuming your administrator has turned off 'question validation' mode). It can help with coding challenges, technology explanations, debugging assistance, architecture decisions, best practices, and any other development-related questions you might have throughout your day. 

!!! note "Question Validation Mode 🚫"

    Developer Lightspeed can operate in different modes. When in **"Question Validation" mode**, it limits its responses to ensure they're appropriate and relevant. In standard mode, it provides broader assistance across a wide range of topics. This mode is generally set by default and managed by your RHDH administrator.

### Why Developer Lightspeed Matters

Developer Lightspeed solves common challenges developers face:

**Natural Language Interface**

You don't need to know the exact terminology or search terms. Ask questions in plain English like "How do I debug a memory leak in Java?" or "What's the difference between microservices and monoliths?" and get clear, helpful answers.

**Instant Answers**

No more clicking through multiple pages, reading entire documentation sections, or waiting for colleagues. Get direct answers to your specific questions immediately, whether they're about code, technologies, or Red Hat Developer Hub features.

**Versatile Helper**

Developer Lightspeed can assist with:
* Coding questions and syntax help
* Technology explanations and comparisons
* Debugging and troubleshooting guidance
* Best practices and patterns
* Red Hat Developer Hub navigation and features
* Architecture and design decisions
* And much more

!!! warning "Developer Preview Feature ⚠️"

    Developer Lightspeed for RHDH is currently a **Developer Preview** feature. This means:
    
    * It's not supported by Red Hat for production use
    * Features may change or be removed
    * It's provided for testing and feedback purposes
    * Your input helps improve the feature for future releases

## Accessing Developer Lightspeed

Developer Lightspeed is an optional feature that must be installed and configured by your platform engineer or administrator. If you don't see it in your navigation, contact your administrator to have it enabled.

### From the Left Navigation Pane

Once enabled, Developer Lightspeed appears in the left-hand navigation pane of Red Hat Developer Hub:

1. Look for **"Lightspeed"** in the navigation menu
2. Click on it to open the Developer Lightspeed interface
3. You'll see the chat interface with your conversation history (if any)

!!! note "Administrator Setup Required"

    Developer Lightspeed requires:
    
    * Installation of the Developer Lightspeed plugin
    * Configuration of Lightspeed Core Service (LCS) and Llama Stack sidecar containers
    * Setup of a Large Language Model (LLM) provider that's compatible with the OpenAI API (such as OpenAI, Ollama, or vLLM)
    
    If you're a platform engineer setting this up, see the [official installation documentation](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.8/html-single/interacting_with_red_hat_developer_lightspeed_for_red_hat_developer_hub/index) for detailed instructions.

## Starting a chat

When you first open Developer Lightspeed, you'll see the chat interface. Here's how to get started:

### Your First Chat

1. **Open Developer Lightspeed** from the left navigation pane
2. **Review the Important notice** at the top of the chat window—this reminds you not to include personal or sensitive information in your messages
3. **Type your question** in the message input field at the bottom
4. **Click send** (or press Enter) to submit your question
5. **Wait for the response**—Developer Lightspeed will process your question and provide an answer

For Red Hat Developer Hub questions, responses may include citations to official documentation that you can verify.

### Creating New Chats

After your first chat, you can create additional conversations:

1. Click the **"New chat"** button in the chat history panel (middle section)
2. A new conversation will start
3. Each chat maintains its own history and context

!!! tip "Organize Your Conversations"

    You can create separate chats for different topics. For example, one chat for coding questions, another for Red Hat Developer Hub features, another for architecture discussions, and another for troubleshooting. This helps keep your conversation history organized and makes it easier to find previous discussions.

### Chat History

Developer Lightspeed maintains a history of your conversations:

* **View previous chats** in the middle panel labeled "Chat history"
* **Search your history** using the "Search previous chats..." box
* **Select a previous chat** to continue that conversation
* **Delete chats** using the three-dot menu (⋯) next to each chat in your history

## Getting help with your questions

Developer Lightspeed is a general-purpose assistant that can help with a wide variety of development questions and tasks. Here are some examples of what you can ask:

### Example Questions

**💻 Coding and Development**

* "How does microservices architecture work?"
* "How do I handle errors in async JavaScript functions?"
* "What's the best way to structure a REST API?"

**🚀 Technology Questions**

* "What is GraphQL and when should I use it?"
* "What are the benefits of containerization?"
* "Can you explain the difference between Docker and Kubernetes?"

**🧰 Red Hat Developer Hub**

* "What is the Software Catalog and how does it work?"
* "How do I create a new software template?"
* "What's the difference between TechDocs and regular documentation?"

**🔍 Troubleshooting**

* "Why is my application running slowly?"
* "How do I debug a memory leak?"
* "Why isn't my component appearing in the catalog?"

**⭐ Best Practices**

* "What are security best practices for API design?"
* "How should I structure my Git workflow?"
* "What are the best practices for writing templates?"

### Understanding Responses

When Developer Lightspeed answers your questions, you'll notice:

**Cited Sources (for RHDH questions)**

When answering questions about Red Hat Developer Hub, responses often include citations to official documentation. These appear as clickable links below the answer, allowing you to verify information or read more details. Use the arrows on the citation card to scroll between the citations.

**Model Information**

The chat interface shows which AI model is being used (e.g., "openai/gpt-oss-20b"). Your administrator configures which models are available, and you can select from available models using the model selector dropdown at the beginning of a new chat.

**Feedback Options**

After each response, you can provide feedback:

* **Thumbs up** 👍 - If the answer was helpful
* **Thumbs down** 👎 - If the answer wasn't helpful or was incorrect
* **Copy** - To copy the response text

!!! tip "Ask Follow-Up Questions"

    Developer Lightspeed maintains context within a conversation. You can ask follow-up questions like "Can you show me an example?" or "How do I do that?" without repeating the original context.

### Best Practices for Using Developer Lightspeed

**Be Specific**

The more specific your question, the better the answer. Instead of "Tell me about templates," try "How do I create a template that publishes to GitHub?" or "What are the best practices for template parameter validation?"

**Use Natural Language**

You don't need to use technical jargon or exact terminology. Ask questions the way you'd ask a colleague.

**Review Citations (when provided)**

When Developer Lightspeed provides citations (typically for Red Hat Developer Hub questions), always check them for important information. The citations link directly to the relevant documentation.

**Provide Feedback**

Use the thumbs up/down buttons to help improve Developer Lightspeed. Your feedback helps make the feature better for everyone.

!!! warning "Data Privacy and Security"

    **Important**: Developer Lightspeed sends your questions to the configured LLM provider (such as OpenAI, Ollama, or vLLM). Do not include:
    
    * Personal information
    * Sensitive business data
    * Credentials or secrets
    * Confidential information
    
    The AI has limited ability to filter or redact information. Be mindful of what you share in your questions, especially when dealing with proprietary code or sensitive business logic.

## Learning more

### Official Documentation

For detailed information about Developer Lightspeed, including installation, configuration, and advanced features, see:

* [Interacting with Red Hat Developer Lightspeed for Red Hat Developer Hub](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.8/html-single/interacting_with_red_hat_developer_lightspeed_for_red_hat_developer_hub/index) - Complete official documentation

### Related Features

Developer Lightspeed works alongside other Red Hat Developer Hub features:

* [Understanding & Using the Software Catalog](software-catalog.md) - Learn about the catalog that Lightspeed can help you navigate
* [Understanding & Using Templates](templates.md) - Get help creating and using templates
* [Understanding & Using TechDocs](techdocs.md) - Learn about documentation that Lightspeed can reference
* [Using Search](search.md) - Alternative way to find information in RHDH

!!! success "Start Exploring"

    The best way to learn Developer Lightspeed is to use it! Open a chat and start asking questions—whether they're about coding, technologies, Red Hat Developer Hub, or any other development topic. The more you use it, the more you'll discover how helpful it can be for your daily development work.

*[RHDH]: Red Hat Developer Hub
