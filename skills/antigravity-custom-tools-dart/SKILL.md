---
name: antigravity-custom-tools-dart
description: "Define stateless/stateful custom tools, validate JSON parameter schemas, or bridge MCP servers in Dart."
---

# Dart Custom Tools & MCP Integration

Development workflow for exposing custom tools to a Google Antigravity SDK agent and bridging Model Context Protocol (MCP) servers.

## 1. Custom Tool Execution Steps

1. **Schema Specification**: Declare parameter maps with standard JSON schema keys (`type`, `properties`, `required`).
2. **Defensive Extraction & Correlation**: Validate incoming arguments explicitly, track `callId` correlation IDs across turns, and handle missing optional keys gracefully.
3. **Self-Correcting Error Handling & Supplemental Media**: Wrap execution in a try-catch block to return descriptive stringified errors or `MediaContent` assets (images, audio, files) directly in tool responses.

For detailed implementations, read [`references/tool_examples.md`](file://references/tool_examples.md).

## 2. Model Context Protocol (MCP) Integration

- Configure `McpServerConfig` instances inside `LocalAgentConfig(mcpServers: [...])`.
- On session startup, `McpBridge` queries active server tools and dynamically constructs native `Tool` instances.

For complete MCP setup code, consult [`references/tool_examples.md`](file://references/tool_examples.md).

## Completion Criteria

- [ ] Tool parameters map accurately to JSON schemas with explicit `required` field declarations.
- [ ] Tool handlers wrap execution in try-catch blocks returning `ToolExecutionException` metadata or stringified error messages on failure.
- [ ] Supplemental media outputs attach valid `MediaContent` buffers (`bytes`, `mimeType`).
- [ ] `McpServerConfig` executable paths and environment variables are verified prior to launch.


