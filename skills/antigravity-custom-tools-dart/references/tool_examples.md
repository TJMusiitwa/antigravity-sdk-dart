# Custom Tools & MCP Integration Examples

This disclosed reference contains code patterns for defining custom tools and bridging Model Context Protocol (MCP) servers in Dart.

## 1. Stateless Custom Tool Definition

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
    
    // Core execution logic...
    return "Found files: ...";
  },
);
```

## 2. Robust Parameter Extraction & Error Handling

```dart
handler: (args, _) async {
  try {
    final targetPath = args['path'] as String?;
    if (targetPath == null || targetPath.isEmpty) {
      return "Error: Missing required argument 'path'.";
    }
    // Perform operation...
    return "Success";
  } catch (e) {
    // Return human-readable error output for agent self-correction
    return "Error executing tool: $e. Please verify arguments and try again.";
  }
}
```

## 3. Registering MCP Servers

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
