import 'dart:async';
import '../types/tool_call.dart';
import 'tool_context.dart';

/// Signature for a custom tool execution callback in the Google Antigravity SDK.
typedef ToolHandler =
    FutureOr<dynamic> Function(
      Map<String, dynamic> arguments,
      ToolContext? context,
    );

/// Represents a custom tool that can be executed by an agent in the Google Antigravity SDK.
class Tool {
  /// The unique identifier/name of the tool.
  final String name;

  /// A description of what the tool does, used by the model for selection.
  final String description;

  /// The JSON schema representing the expected arguments for the tool.
  final Map<String, dynamic> schema;

  /// The execution callback function.
  final ToolHandler handler;

  /// Creates a new [Tool] instance.
  Tool({
    required this.name,
    required this.description,
    required this.schema,
    required this.handler,
  });
}

/// Registry and executor for custom tools in the Google Antigravity SDK.
class ToolRunner {
  final Map<String, Tool> _tools = {};
  ToolContext? _context;

  /// Creates a new [ToolRunner], registering any provided [tools].
  ToolRunner({List<Tool>? tools}) {
    if (tools != null) {
      for (final tool in tools) {
        register(tool);
      }
    }
  }

  /// Sets the ToolContext for injection into tools that request it.
  void setContext(ToolContext ctx) {
    _context = ctx;
  }

  /// Registers a tool.
  void register(Tool tool) {
    if (_tools.containsKey(tool.name)) {
      throw ArgumentError("Tool '${tool.name}' is already registered.");
    }
    _tools[tool.name] = tool;
  }

  /// Removes a tool by name.
  void unregister(String name) {
    if (!_tools.containsKey(name)) {
      throw ArgumentError("Tool '$name' is not registered.");
    }
    _tools.remove(name);
  }

  /// The names of all registered tools.
  List<String> get toolNames => _tools.keys.toList();

  /// A copy of the registered tools dictionary.
  Map<String, Tool> get tools => Map.unmodifiable(_tools);

  /// Executes a registered tool by name.
  Future<dynamic> execute(String toolName, Map<String, dynamic> args) async {
    final tool = _tools[toolName];
    if (tool == null) {
      throw ArgumentError("Tool '$toolName' is not registered.");
    }
    return await tool.handler(args, _context);
  }

  /// Executes a batch of tool calls concurrently and returns structured results.
  Future<List<ToolResult>> processToolCalls(List<ToolCall> toolCalls) async {
    final futures = toolCalls.map((tc) async {
      try {
        final tool = _tools[tc.name];
        if (tool == null) {
          return ToolResult(
            name: tc.name,
            id: tc.id,
            error: "Unknown tool: '${tc.name}'",
          );
        }
        final result = await tool.handler(tc.args, _context);
        return ToolResult(name: tc.name, id: tc.id, result: result);
      } catch (e) {
        return ToolResult(name: tc.name, id: tc.id, error: e.toString());
      }
    });
    return await Future.wait(futures);
  }
}
