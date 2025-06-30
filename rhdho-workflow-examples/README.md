## Greeting workflow

A simple workflow that greets the user in a selected language, either in english or spanish.

## Slack interacting workflow

This workflow sends a message to a public channel in slack. Example of public channels: #general or #random.

### Prerequisites

* An existing workspace in slack.
* An existing Slack App and Bot Token with the correct scopes.
* Ensure the app is invited to the public channel.
  Follow [slack guide](https://api.slack.com/tutorials/tracks/getting-a-token) on setting up slack app and bot token.

## GitHub Interacting Workflow

This workflow creates a public repository on GitHub.

### Prerequisites

* A GitHub account.
* A Personal Access Token for authentication. Follow
  this [guide](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
  on how to setup GitHub Token

Ensure to update the generated token in the `application.properties` file.
