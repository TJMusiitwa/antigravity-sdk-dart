## 0.2.0

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
