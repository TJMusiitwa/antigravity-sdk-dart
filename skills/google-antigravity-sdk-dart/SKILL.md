---
name: google-antigravity-sdk-dart
description: "Use when initializing, configuring, or debugging Google Antigravity (AGY) agents, subagents, or persona configs in Dart."
---

# Google Antigravity Dart SDK

## 1. Environment & Setup Steps

1.  **Check Dependencies**: Ensure `antigravity` is declared in `pubspec.yaml`.
2.  **Authentication**: Pass `GEMINI_API_KEY` via `LocalAgentConfig(apiKey: "...")` or verify the `GEMINI_API_KEY` environment variable is set.
3.  **Configure Session**: Initialize `LocalAgentConfig` with required tools, system instructions, and policies.

## 2. Standard Example References

Reference implementations for common setups:

-   [`example/getting_started/hello_world.dart`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/example/getting_started/hello_world.dart): Basic hello world agent setup.
-   [`example/getting_started/custom_tools.dart`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/example/getting_started/custom_tools.dart): Registering custom tool handlers.
-   [`example/getting_started/persona_config.dart`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/example/getting_started/persona_config.dart): Configuring system instructions.
-   [`example/getting_started/subagents.dart`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/example/getting_started/subagents.dart): Spawning and orchestrating subagents.
-   [`example/getting_started/agent_skills.dart`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/example/getting_started/agent_skills.dart): Loading agent skills.

## Completion Criteria

- [ ] `antigravity` dependency is present and resolved in `pubspec.yaml`.
- [ ] `GEMINI_API_KEY` is provided either via config or environment.
- [ ] Agent session initializes and responds cleanly to a test prompt.
