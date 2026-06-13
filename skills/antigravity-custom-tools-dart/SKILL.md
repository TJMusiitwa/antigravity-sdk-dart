---
name: antigravity-custom-tools-dart
description: "Instructions for implementing stateless and stateful tools in Dart and bridging with MCP servers."
---

# Dart Custom Tools & MCP Integration

This skill defines the development workflow for exposing custom functionality to your Antigravity agent, validating schemas, and connecting to Model Context Protocol (MCP) servers.

## 1. Defining Stateless Custom Tools

Custom tools must be registered inside the agent's configuration. Use standard JSON schema maps for specifying tool arguments.

### Example Tool Definition
```dart
import 'package:antigravity/antigravity.dart';

final listDirectoryTool = Tool(
  name: 'list_directory_files',
  description: 'Lists files in the target workspace directory.',
  schema: {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string', 
        'description': 'The absolute path to the directory.'
      },
      'recursive': {
        'type': 'boolean', 
        'description': 'Whether to search subdirectories recursively.'
      }
    },
    'required': ['path']
  },
  handler: (args, context) async {
    final path = args['path'] as String;
    final recursive = (args['recursive'] as bool?) ?? false;
    
    // Core logic here...
    return "Found files: ...";
  },
);
```

---

## 2. Parameter Validation & Error Handling

To prevent the agentic loop from crashing due to bad inputs or system exceptions, follow these rules:

1.  **Robust Type Extraction**: Explicitly validate arguments and handle missing optional keys gracefully.
2.  **Graceful Tool Failures**: Catch all exceptions inside the handler, format them into human-readable strings, and return them as the tool result. The agent will read the error output and correct its next step.
    ```dart
    handler: (args, _) async {
      try {
        // execute task
      } catch (e) {
        return "Error executing tool: $e. Please verify arguments and try again.";
      }
    }
    ```

---

## 3. Integrating Model Context Protocol (MCP) Servers

The Antigravity Dart SDK can act as an MCP client and pull tools dynamically from external MCP servers.

### Registering MCP Servers
Configure the `McpBridge` inside the agent session initialization:

```dart
final config = LocalAgentConfig(
  mcpServers: [
    McpServerConfig(
      name: 'filesystem-server',
      command: 'node',
      args: ['/path/to/mcp-fs-server/index.js'],
      env: {'ALLOWED_DIRS': '/Users/user/workspace'},
    ),
  ],
);
```

### Dynamic Tool Mapping
When the agent starts up:
1.  The SDK establishes JSON-RPC channels with configured MCP servers.
2.  It queries available tools on the server.
3.  It maps their parameters and metadata automatically to native `Tool` instances and appends them to the agent's capabilities configuration.
