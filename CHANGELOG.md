# 0.10.0

* **Sync with Python SDK v0.1.13**:
  - **Pre-Tool Hook Argument Modification**:
    - Pre-tool lifecycle hooks can now inspect, sanitize, and modify tool input arguments prior to execution by returning `HookResult(allow: true, modifiedArgs: {...})`.
    - Added sequential argument modification chaining across registered `PreToolCallDecideHook` instances in `HookRunner.dispatchPreToolCall`.
    - Updated `HookRouter` to emit `modified_arguments_json` in `PreToolResult` for harness-side tool authorization.
  - **Tool Lifecycle Step Correlation (`stepId`)**:
    - Added `stepId` (`@MappableField(key: 'step_id')`) to `ToolCall` and `ToolResult`.
    - Added `stepId` parameter and property to `ToolExecutionException`.
    - Updated `HookRouter` to extract and correlate `stepId` (`trajectory_id:step_index`) across pre-tool, post-tool, and on-tool-error lifecycle hooks.
  - **Structured Command Execution Configuration (`RunCommandConfig`)**:
    - Introduced `RunCommandConfig` to configure execution timeouts (`timeoutSeconds`) and authorize background daemon commands (`enableDaemons`).
    - Added `runCommandConfig` property to `CapabilitiesConfig` and `SubagentCapabilities`.
    - Mapped `RunCommandConfig` to `localharness` `harness_side_tools.run_command` configuration (`enable_daemon_commands` and `max_timeout_ms`).
  - **Vertex AI Custom Base URL Support**:
    - Updated `VertexEndpoint` to avoid hydrating ambient `GOOGLE_CLOUD_PROJECT` and `GOOGLE_CLOUD_LOCATION` environment variables when a custom `baseUrl` is specified.
  - **Harness & Binary Discovery**:
    - Updated default `localharness` binary download version in `HarnessDownloader` to `0.1.13`.

# 0.9.2
 
* **Fix `RetryConfig` Serialization**:
  - `ModelAPIRetryConfig.toMap()`/`toJson()` (and any `RetryConfig` containing one) threw `MapperException: Unknown type Duration` and emitted a spurious `initial_sleep_duration` key that `localharness` rejects. The `initialSleepDuration` `Duration` is a convenience argument, not a wire field, but was being generated as one.
  - Added `ModelAPIRetryConfig.raw()` as the `@MappableConstructor()`, so only the integer `initialSleepDurationMs` is serialized. The unnamed constructor still accepts either `initialSleepDurationMs` or `initialSleepDuration`.
* **Fix Subagent Tool Protobuf Naming**:
  - Corrected `harness_side_tools` field names for subagents in `LocalConnectionStrategy` (`"file_edit"` and `"write_to_file"`, matching `localharness.proto`), resolving `unknown field "edit_file"` errors when launching static subagents.
* **CI & Example Automation**:
  - Added non-interactive terminal fallback (`stdin.hasTerminal`) to `example/getting_started/human_in_the_loop.dart` to prevent test runs from blocking on headless standard input.

# 0.9.1
 
* **Critical Bug Fixes for Local Harness Execution**:
  - **Trajectory Idle State Recognition**: Added support for `STATE_FULLY_IDLE` (and `FULLY_IDLE`) in `LocalConnection` trajectory state updates, properly emitting the `idle_sentinel` step and preventing `agent.chat()` / `response.text()` from hanging at turn completion.
  - **Tool Authorization Handshake**: Added handler for `LIFECYCLE_HOOK_PRE_TOOL` / `PRE_TOOL` in `HookRouter`, returning valid `pre_tool_result` decisions (`ALLOW` / `DENY`) to the harness and resolving tool execution deadlocks.
  - **Wire Path Normalization**: Added wire-format URI normalization (`file:///`, `cns://`) for tool call arguments in `HookRouter` to support path-based safety policies and canonical workspace containment.

# 0.9.0

* **Sync with Python SDK v0.1.11**:
  - **Default Model Upgrade to Gemini 3.7 Flash**: Updated default generative text model in `lib/src/models.dart` to `gemini-3.7-flash`.
  - **Session Budget Enforcement (`BudgetConfig`) & Stop Reasons (`StopReason`)**:
    - Introduced `BudgetConfig` to configure session-level caps: `maxModelCalls`, `maxToolCalls`, `maxInputTokens`, `maxOutputTokens`, `maxTotalTokens`.
    - Added `StopReason` enum (`unspecified`, `maxModelCallsExceeded`, `maxToolCallsExceeded`, `maxInputTokensExceeded`, `maxOutputTokensExceeded`, `maxTotalTokensExceeded`, `quotaExhausted`).
    - Exposed `ChatResponse.stopReason`, `ChatResponse.usage`, and `Conversation.lastTurnStopReason`.
  - **Vertex AI Express Mode (`apiKey`)**:
    - Added `apiKey` support to `VertexEndpoint` for Vertex AI Express Mode authentication.
    - Implemented mutual exclusivity validation: rejects configurations passing both `apiKey` (Express Mode) and `project`/`location` (Standard Mode).
  - **Agent Behavior Standard (`AgentBehavior`)**:
    - Renamed `AgentMode` enum to `AgentBehavior` (`autonomous`, `interactive`), mapping to `AGENT_BEHAVIOR_AUTONOMOUS` and `AGENT_BEHAVIOR_INTERACTIVE` protobuf values.
    - Provided `typedef AgentMode = AgentBehavior` and constructor/getter aliases for backward compatibility.
  - **Hierarchical & Nested Subagent Controls**:
    - Added `maxSubagentDepth` and `allowedSubagents` allowlist configuration on `CapabilitiesConfig` and `SubagentCapabilities`.
    - Enabled `BuiltinTools.startSubagent` on custom subagents when configured in their capability toolsets.
    - Validated that `maxSubagentDepth` and `allowedSubagents` cannot be set when subagents are disabled.
    - Added subagent allowlist validation on `BaseLocalAgentConfig` ensuring all referenced subagent names exist in the configured `subagents` list.
  - **Step Metadata & Image Artifact Paths**:
    - Added `parentTrajectoryId` and `depth` fields to `Step` and updated `Step.fromMap` parser.
    - Added `outputPath` to `GenerateImageResult` and updated `toString()` to return `outputPath` when non-empty.
  - **Policy Enhancements**:
    - Made `handler` optional in `askUser` policy builder for host platform delegation compatibility.
  - **New Example & Documentation**:
    - Added `example/getting_started/budget_limits.dart` demonstrating all 5 budget limits and stop reason inspection.
    - Updated `example/getting_started/subagents.dart` showcasing dynamic self-delegation, static subagents, and nested subagent hierarchies.
  - **SDK Version Bump & Dependency Synchronization**:
    - Updated package version to `0.9.0` and MCP implementation version to `0.9.0`.

# 0.8.0

* **Sync with Python SDK v0.1.10 & Dart-Idiomatic Enhancements**:
  - **Breaking API Change**: `Conversation.lastTurnUsage` signature updated to `UsageMetadata?` (matching Python SDK v0.1.10) to return `null` when no token usage was recorded during a turn.
  - **Gemini Prioritized Inference (`ServiceTier`)**: Introduced `ServiceTier` enum (`standard`, `priority`, `flex`) and support in `GeminiModelOptions` and `UsageMetadata` to configure high-priority model execution with automated fallback.
  - **Live Token Usage Updates**: Added support for live `UsageUpdate` event streaming over WebSockets, accumulating per-trajectory token usage live during execution. Added subtraction (`-`) operator support to `UsageMetadata`.
  - **Agent Execution Modes (`AgentMode`)**: Introduced `AgentMode` enum (`autonomous`, `interactive`) in `CapabilitiesConfig` and `SubagentCapabilities` with interactive tool validation warnings (`BuiltinTools.askQuestion`).
  - **Interactive CLI Spinner**: Updated interactive CLI step spinner formatting (`formatStepSpinnerMessage`) to display all active tool names during concurrent tool calls (e.g. `Running tools 'tool_a', 'tool_b'...`).
  - **Tool Call Correlation ID**: Added `callId` correlation support across `ToolCall`, `ToolResult`, `ToolExecutionException`, and lifecycle hook payloads.
  - **Flexible Context-Aware Lifecycle Hooks**: Added `.stateless()` factory constructors to `FunctionInspectHook`, `FunctionDecideHook`, and `FunctionTransformHook` to seamlessly support both `(data)` and `(context, data)` callback signatures.
  - **ActionCompaction Handling**: Emits context window compaction events over WebSockets and dispatches registered `OnCompactionHook` handlers.
  - **Standardized System Instructions Strategy**: Plain string instructions default to an appended system instruction strategy, while `CustomSystemInstructions` completely replaces built-in instructions.
  - **LiteRT Token Output Limit**: Increased LiteRT default `maxOutputTokens` from 8192 to 16,384 tokens to prevent truncation during complex generation.

# 0.7.0

* **Sync with Python SDK v0.1.9 & Dart-Idiomatic Enhancements**:
  - **Model-Call Retry & Backoff Configuration**: Introduced `RetryConfig`, `ModelAPIRetryConfig`, and `ModelOutputRetryConfig` with `RetryConfig.benchmark()` preset for controlling exponential backoff and output retry behavior across `LocalAgentConfig`, `LocalOpenAIAgentConfig`, and `LiteRTAgentConfig`.
  - **Strongly-Typed `Duration` & Jitter Ratio Validation**: Added `Duration` support (`initialSleepDuration`, `serverTimeout`) to `ModelAPIRetryConfig` and `McpServerConfig`. Validates `jitterRange` as a ratio between `0.0` and `1.0`.
  - **Strongly-Typed Logging with `package:logging`**: `DebugConfig` accepts strongly-typed `Level` objects (`level: Level.WARNING`) or string names, validating levels and applying process-safe logger updates on `Agent.start()`.
  - **`Uri` & `Uint8List` Media Buffers**: Added `Uri` getters (`uri`, `baseUri`) on `McpStreamableHttpServer` and `ModelEndpoint`, plus `McpStreamableHttpServer.fromUri()` factory constructor. Added `Uint8List get bytes` getter on `MediaContent` and `File` object support in `fromFile()`.
  - **Step & Turn Extensions**: Added extension getters (`isUserTurn`, `isModelTurn`, `isFinished`, `isDone`) on `Step`, `StepSource`, and `StepStatus`.
  - **LiteRT Warm-up Timeout Scaling**: Dynamically scales LiteRT engine warm-up timeouts based on context size (`maxContextTokens`).
  - **Expanded Audio Payload MIME Support**: Added support for `audio/x-wav`, `audio/wave`, `audio/vnd.wave`, `audio/mp4`, `audio/webm`, and additional audio formats.
  - **Prompt Validation**: Added strict validation in `Conversation.chat()` to reject null, empty string, whitespace-only, or empty content prompts with `AntigravityValidationException`.
  - **Hybrid Exception Hierarchy**: `AntigravityValidationException` implements both `Exception` and `ArgumentError` for backwards compatibility.
  - **SDK Alignment**: Bumped SDK version to `0.7.0` aligned with Python SDK `v0.1.9` release.

# 0.6.0

* **Sync with Python SDK v0.1.8**:
  - **Default Model Upgrade to Gemini 3.6 Flash**: Updated default generative text model in `lib/src/models.dart` to `gemini-3.6-flash`.
  - **Prompt Sanitization**: Strips null bytes (`\x00`) and dangerous control characters (`DEL`, `BEL`, `C1`) from incoming string prompts at the wire boundary.
  - **Tool Execution Exception**: Introduced `ToolExecutionException` carrying `message`, `toolName`, and `serverName` metadata when tool execution fails, with updated hook routing in `HookRouter`.
  - **Subagent Custom & Templated System Instructions**: Expanded `SubagentConfig` system instructions to support `CustomSystemInstructions` and `TemplatedSystemInstructions`.
  - **SDK Version Bump & Alignment**: Bumping SDK version to 0.6.0 aligned with Python SDK v0.1.8 release updates.

# 0.5.0

* **Sync with Python SDK v0.1.7**:
  - **Hierarchical Thread-Safe State Management**: Introduced the `StateStore` class for hierarchical context state sharing and lock/reentrancy support. Retargeted `HookContext` and `ToolContext` to inherit from `StateStore`.
  - **Session Continuation Modes**: Implemented `SessionContinuationMode` to specify continuation behavior (`RESUME`, `CREATE_OR_RESUME`, `CREATE_ONLY`, `SESSION_CONTINUATION_MODE_UNSPECIFIED`) with validation checks on `AgentConfig`.
  - **Dynamic Environment Hydration**: Hydrates Vertex project and location parameters automatically from standard `GOOGLE_CLOUD_PROJECT` and `GOOGLE_CLOUD_LOCATION` environment variables when not explicitly passed, and enables Vertex mode automatically when `GOOGLE_GENAI_USE_VERTEXAI` or `GOOGLE_GENAI_USE_ENTERPRISE` is set.
  - **Websocket Retry Backoff & DNS Resolution**: Refactored websocket connections in `LocalConnectionStrategy` to retry on both `localhost` and `127.0.0.1` to ensure reliable connections in containerized sandboxes.
  - **Spinner Pause/Resume**: Enhanced CLI `Spinner` with pause and resume behaviors, and integrated them into user confirmation/question hooks to prevent prompt clobbering.
  - **Custom Tool Execution Support**: Added `custom_tool` parsing support in `Step.fromMap` and filtered out tool calls from StepUpdate if they are local custom tools to prevent client duplicate events.
  - **Addition Operator for Token Usage**: Implemented `+` addition operator on `UsageMetadata` for clean accumulation of token usage.
  - **Updated default image generation model** to `'gemini-3.1-flash-lite-image'`.
  - **Added `ThinkingLevel.extraHigh`** (`'extra_high'`) level support.

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
