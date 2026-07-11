# 0.4.1

* **Bug Fixes & Adjustments**:
  - Restored default workspaces (current working directory) and capabilities configuration on `BaseLocalAgentConfig` to prevent silent sandboxing regressions.
  - Fixed client handshake protocol to announce the correct client version instead of a stale one.
  - Added missing `read_url_content` tool field mapping in `Step.fromMap` parser.
  - Resolved `HttpClient` socket/connection leak in LiteRT loopback server health checks.
  - Documented public configuration fields on `LocalOpenAIAgentConfig` and `LiteRTAgentConfig`.

# 0.4.0

* **Local Inference & OpenAI Endpoint Support**:
  - Added support for local Gemma execution using LiteRT via `LiteRTAgentConfig` and `LiteRTConnectionStrategy` (which manages a python loopback HTTP server).
  - Added support for any OpenAI-compatible completions API (e.g. Ollama, LM Studio) via `LocalOpenAIAgentConfig` and `LocalOpenAIConnectionStrategy`.
* **Multimodal Tool Outputs**:
  - Enabled custom tools to return media assets (images, audio, video, documents) directly via a single tool response without needing separate follow-up turns. Media is extracted and sent as `supplemental_media` in `tool_response`.
* **Model Context Protocol (MCP)**:
  - Decoupled tool calls and safety policy engines from legacy `mcp_` string prefix synthesis, utilizing explicit `serverName` attributes in tool evaluation.
* **Alias Deserialization Support**:
  - Handled `results`/`entries` alias in `ListDirectoryResult` and `output`/`combined_output` alias in `RunCommandResult`.
* **Automated Binary Discovery Updates**:
  - Added version checking logic to verify if the cached `localharness` binary is out of date.
  - Automatically triggers a re-download/upgrade if the cached binary version is older than the SDK's default version (`0.1.6`).


# 0.3.1

* **Fix Tool Error Hook Dispatching**:
  - Resolved a bug where `OnToolErrorHook` was never dispatched for either client-side custom tool failures or harness-side built-in tool failures.
  - Implemented client-side tool error dispatching in `local_connection.dart` with support for recovery values.
  - Added routing for `LIFECYCLE_HOOK_ON_TOOL_ERROR` and `ON_TOOL_ERROR` hook requests in `hook_router.dart` and covered it with a unit test.

* **Dart 3 Modernization**:
  - Refactored core classes `Connection` and `ConnectionStrategy` to use Dart 3 `abstract interface class` modifiers.
  - Marked `MediaContent` as a `sealed class` to restrict subclass hierarchy and support compiler-level exhaustiveness checks.
  - Modernized `registerHook`, `allow`, `deny`, and `askUser` to leverage case type pattern matching inside switch statements.
  - Refactored policy bucket index resolution (`_bucketIndex`), file change triggers (`onFileChange`), shorthand model builder (`_buildShorthandModels`), and step state mappings (`Step.fromMap`) to use clean switch expressions and logical OR patterns.
  - Updated local connection classes to implement rather than extend the new interface classes.
  - Added conditional imports in `lib/src/types/content.dart` to support running the package on the web.

# 0.3.0

* **Synchronize updates from Python SDK (v0.1.5)**:
  - Added new `read_url_content` builtin tool and its `ReadUrlContentResult` structured output.
  - Added `StepType.thinking` to enum representation for telemetry tracking.
  - Implemented the `HookRouter` to process WebSocket-based `CallHookRequest` turn and tool lifecycle hooks delegated by the harness.
  - Added support for telemetry `PreStepHook` and `PostStepHook` inside `HookRunner` and connection parser.
  - Implemented `_StepTracker` to prevent duplicate step hooks or non-linear state transitions.
  - Supported error and cancelled propagation in `trajectory_state_update` events.
  - **Historical Step Absorption**: Aligned startup handshake to await and parse pre-existing conversation history and usage metadata from `initialize_conversation_response`, populating them immediately in `Conversation` on start.

# 0.2.2

* Update to support web platform use 

# 0.2.1

* Reintroduce generated files in package

# 0.2.0

*   **Model Configuration Overhaul**: Replaced the monolithic `GeminiConfig` with a more flexible `ModelTarget` and polymorphic `ModelEndpoint` class hierarchy (`GeminiAPIEndpoint`, `VertexEndpoint`).
*   **Subagents Feature**: Introduced `SubagentConfig` and `SubagentCapabilities` allowing definition and inclusion of subagents in the main agent's configuration.
*   **New Builtin Tools**: Added `SearchWeb` tool and related `SearchWebResult` structured output.
*   **Enhanced Configuration**: Support for environment variables (`env`) in `McpStdioServer`. Removed `imageModel` from `CapabilitiesConfig` to favor the new generic model targeting features.

## 0.1.3

* Added support for Vertex AI configuration (project, location, vertex options) in `GeminiConfig`.
* Refactored Model Context Protocol (MCP) server configurations to run connections natively on the Go-based harness, removing client-side `McpBridge` references.
* Added `SlashCommand` structure to input content primitives to support built-in planning flows.
* Integrated CLI `Spinner` into `runInteractiveLoop` with step-by-step progress tracking via `agent.conversation.receiveSteps()`.
* Enhanced policy engine with a 9-level priority model supporting prefix wildcards and custom MCP policy validators.
* Added `AntigravityCancelledException` and `AntigravityExecutionException` for robust error handling.

## 0.0.1

* Initial release of the Antigravity Dart SDK.
