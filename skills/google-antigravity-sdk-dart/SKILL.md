---
name: google-antigravity-sdk-dart
description: "Design, implement, and debug autonomous AI agents and multi-agent systems using the Google Antigravity (AGY) Dart SDK. ACTIVATE this skill when the user wants to create, configure, or orchestrate Google Antigravity agents in Dart."
---

# Google Antigravity Dart SDK

## Installation & Setup

Ensure the Dart environment is ready:

-   **Verify Applicability**: Verify that using this Dart SDK is possible and appropriate for the project.
-   **Check Dependencies**: Check if `antigravity` is listed in the project's `pubspec.yaml` dependencies.
-   **Authentication Setup**: Check for a valid `GEMINI_API_KEY` environment variable.
    -   API key can be passed explicitly in code: `LocalAgentConfig(apiKey: "...")` or automatically read from the environment.

## Examples

-   `example/getting_started/hello_world.dart`: Simple hello world prompt.
-   `example/getting_started/custom_tools.dart`: Defining stateless and stateful tools.
-   `example/getting_started/persona_config.dart`: System instructions configurations.
-   `example/getting_started/subagents.dart`: Spawning child agents for delegation.
-   `example/getting_started/agent_skills.dart`: Loading and using agent skills.
