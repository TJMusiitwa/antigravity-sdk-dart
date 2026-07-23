---
name: antigravity-custom-tools-dart
description: "Use when defining stateless/stateful custom tools, validating Tool JSON schemas, or bridging MCP (Model Context Protocol) servers in Dart."
---

# Dart Custom Tools & MCP Integration

Development workflow for exposing custom tools to an Antigravity agent and bridging Model Context Protocol (MCP) servers.

## 1. Defining Custom Tools

1.  **Schema Specification**: Use standard JSON schema maps for tool parameters (`properties`, `type`, `required`).
2.  **Type Extraction**: Explicitly validate incoming argument types and handle missing optional keys gracefully.
3.  **Error Handling**: Catch all exceptions inside the tool handler and return human-readable error strings so the agent can self-correct.

For detailed code patterns, inspect [`references/tool_examples.md`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/skills/antigravity-custom-tools-dart/references/tool_examples.md).

## 2. Model Context Protocol (MCP) Integration

- Configure `McpServerConfig` instances inside `LocalAgentConfig(mcpServers: [...])`.
- On startup, `McpBridge` queries server tools and maps them dynamically to native `Tool` instances.

For complete MCP setup code, read [`references/tool_examples.md`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/skills/antigravity-custom-tools-dart/references/tool_examples.md).

## Completion Criteria

- [ ] Tool parameters map accurately to JSON schemas with explicit required field declarations.
- [ ] Tool handlers wrap execution in try-catch blocks and return stringified error messages on failure.
- [ ] `McpBridge` server paths and environment variables are verified before launch.
