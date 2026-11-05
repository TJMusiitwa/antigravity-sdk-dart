import 'dart:convert';

import 'package:dart_mappable/dart_mappable.dart';

import 'capabilities.dart';

part 'tool_call.mapper.dart';

/// A request to execute a tool.
@MappableClass(ignoreNull: true)
class ToolCall with ToolCallMappable {
  /// An optional unique identifier for the call, often assigned by the
  /// backend.
  final String? id;

  /// An optional call correlation ID (wire key `call_id`).
  ///
  /// Takes precedence over [id] in [effectiveCallId].
  @MappableField(key: 'call_id')
  final String? callId;

  /// An optional ID correlating this call with its step in the trajectory
  /// (wire key `step_id`).
  @MappableField(key: 'step_id')
  final String? stepId;

  /// The tool name.
  ///
  /// For builtin tools (no [serverName]), the deprecated `start_subagent`
  /// name is normalized to `invoke_subagent`.
  final String name;

  /// The tool arguments as a JSON-compatible map.
  ///
  /// Encoded as a JSON string under the `arguments_json` key. Defaults to an
  /// empty map.
  @MappableField(key: 'arguments_json', hook: ArgumentsHook())
  final Map<String, dynamic> args;

  /// An optional normalized filesystem path for file-related tools (wire key
  /// `canonical_path`).
  @MappableField(key: 'canonical_path')
  final String? canonicalPath;

  /// The server name (e.g. MCP server name) associated with this tool call.
  @MappableField(key: 'server_name')
  final String? serverName;

  /// Creates a [ToolCall].
  ///
  /// Builtin tool names are normalized, and [args] defaults to an empty map.
  ToolCall({
    String name = '',
    Map<String, dynamic>? args,
    this.id,
    this.callId,
    this.stepId,
    this.canonicalPath,
    this.serverName,
  }) : name = normalizeBuiltinToolName(name, serverName: serverName),
       args = args ?? {};

  /// Returns effective correlation ID (either [callId] or [id]).
  String? get effectiveCallId => callId ?? id;

  /// Decodes a [ToolCall] from a map.
  ///
  /// Falls back to the `arguments` key when `arguments_json` is absent.
  factory ToolCall.fromMap(Map<String, dynamic> map) {
    if (!map.containsKey('arguments_json') && map.containsKey('arguments')) {
      final copy = Map<String, dynamic>.from(map);
      copy['arguments_json'] = copy['arguments'];
      return ToolCallMapper.fromMap(copy);
    }
    return ToolCallMapper.fromMap(map);
  }

  /// Decodes a [ToolCall] from a JSON string.
  factory ToolCall.fromJson(String json) => ToolCallMapper.fromJson(json);
}

/// A mapping hook that decodes tool arguments from a JSON string and
/// encodes them back to one.
///
/// Invalid JSON or a non-map value decodes to an empty map.
class ArgumentsHook extends MappingHook {
  /// Creates an [ArgumentsHook].
  const ArgumentsHook();

  @override
  Object? beforeDecode(Object? value) {
    if (value is String) {
      try {
        return jsonDecode(value);
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    if (value is Map) {
      return value;
    }
    return <String, dynamic>{};
  }

  @override
  Object? afterEncode(Object? value) {
    if (value is Map) {
      return jsonEncode(value);
    }
    return value;
  }
}

/// The result of a single tool execution.
@MappableClass(ignoreNull: true)
class ToolResult with ToolResultMappable {
  /// An optional ID correlating this result with a [ToolCall.id].
  final String? id;

  /// An optional call correlation ID (wire key `call_id`).
  ///
  /// Takes precedence over [id] in [effectiveCallId].
  @MappableField(key: 'call_id')
  final String? callId;

  /// An optional ID correlating this result with a step (wire key `step_id`).
  @MappableField(key: 'step_id')
  final String? stepId;

  /// The server name (e.g. MCP server name) associated with this tool result.
  @MappableField(key: 'server_name')
  final String? serverName;

  /// The tool name, normalized the same way as [ToolCall.name].
  final String name;

  /// The tool's return value; any JSON-serializable value.
  final dynamic result;

  /// An error message if execution failed, or null on success.
  final String? error;

  /// The original exception if execution failed.
  ///
  /// Not serialized.
  @MappableField(hook: UnmappedHook())
  final Exception? exception;

  /// Creates a [ToolResult] for the tool [name].
  ToolResult({
    required String name,
    this.id,
    this.callId,
    this.stepId,
    this.serverName,
    this.result,
    this.error,
    this.exception,
  }) : name = normalizeBuiltinToolName(name, serverName: serverName);

  /// Returns effective correlation ID (either [callId] or [id]).
  String? get effectiveCallId => callId ?? id;

  /// Decodes a [ToolResult] from a map.
  factory ToolResult.fromMap(Map<String, dynamic> map) =>
      ToolResultMapper.fromMap(map);

  /// Decodes a [ToolResult] from a JSON string.
  factory ToolResult.fromJson(String json) => ToolResultMapper.fromJson(json);
}

/// A mapping hook that excludes a field from serialization.
///
/// The field always decodes and encodes as null.
class UnmappedHook extends MappingHook {
  /// Creates an [UnmappedHook].
  const UnmappedHook();
  @override
  Object? beforeDecode(Object? value) => null;
  @override
  Object? beforeEncode(Object? value) => null;
}
