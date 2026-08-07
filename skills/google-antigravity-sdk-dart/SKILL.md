---
name: google-antigravity-sdk-dart
description: "Initialize, configure, or debug Google Antigravity (AGY) agents, custom tools, persona configs, and subagents in Dart."
---

# Google Antigravity Dart SDK

## 1. Execution Steps

1. **Dependency Verification**: Verify `antigravity` dependency in [`pubspec.yaml`](file://pubspec.yaml).
2. **Key & Tier Lookup**: Pass `GEMINI_API_KEY` via `LocalAgentConfig(apiKey: "...")` or ensure the `GEMINI_API_KEY` environment variable is set. Optionally specify `ServiceTier.priority` for prioritized inference.
3. **Session Initialization**: Configure `LocalAgentConfig` with default generative text model `gemini-3.6-flash`, execution mode `AgentMode.autonomous`, required tool lists, persona system instructions, and policy rules before launching the agent instance.

## 2. Standard Example References

Reference implementations for common setups:

- [`hello_world.dart`](file://example/getting_started/hello_world.dart): Basic agent session initialization.
- [`custom_tools.dart`](file://example/getting_started/custom_tools.dart): Custom tool handler registration.
- [`persona_config.dart`](file://example/getting_started/persona_config.dart): System instruction and persona setup.
- [`structured_output.dart`](file://example/getting_started/structured_output.dart): Structured JSON schema response parsing.
- [`cancellation.dart`](file://example/getting_started/cancellation.dart): Session turn cancellation via `agent.cancel()`.
- [`subagents.dart`](file://example/getting_started/subagents.dart): Subagent spawning and multi-agent orchestration.
- [`agent_skills.dart`](file://example/getting_started/agent_skills.dart): Dynamic skill loading and registration.

## Completion Criteria

- [ ] `antigravity` dependency is resolved in `pubspec.yaml`.
- [ ] `GEMINI_API_KEY` is validated in config or environment.
- [ ] Agent session initializes and executes prompt turn without throw.
- [ ] Turn cancellation `agent.cancel()` terminates active trajectory gracefully when invoked.
