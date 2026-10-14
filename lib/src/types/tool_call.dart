import 'dart:convert';
import 'package:dart_mappable/dart_mappable.dart';

import 'capabilities.dart';

part 'tool_call.mapper.dart';

@MappableClass(ignoreNull: true)
class ToolCall with ToolCallMappable {
  final String? id;

  @MappableField(key: 'call_id')
  final String? callId;

  @MappableField(key: 'step_id')
  final String? stepId;

  /// The tool name.
  ///
  /// For builtin tools (no [serverName]), the deprecated `start_subagent`
  /// name is normalized to `invoke_subagent`.
  final String name;

  @MappableField(key: 'arguments_json', hook: ArgumentsHook())
  final Map<String, dynamic> args;

  @MappableField(key: 'canonical_path')
  final String? canonicalPath;

  /// The server name (e.g. MCP server name) associated with this tool call.
  @MappableField(key: 'server_name')
  final String? serverName;

  ToolCall({
    String name = '',
    Map<String, dynamic>? args,
    this.id,
    this.callId,
    this.stepId,
    this.canonicalPath,
    this.serverName,
  })  : name = normalizeBuiltinToolName(name, serverName: serverName),
        args = args ?? {};

  /// Returns effective correlation ID (either [callId] or [id]).
  String? get effectiveCallId => callId ?? id;

  factory ToolCall.fromMap(Map<String, dynamic> map) {
    if (!map.containsKey('arguments_json') && map.containsKey('arguments')) {
      final copy = Map<String, dynamic>.from(map);
      copy['arguments_json'] = copy['arguments'];
      return ToolCallMapper.fromMap(copy);
    }
    return ToolCallMapper.fromMap(map);
  }

  factory ToolCall.fromJson(String json) => ToolCallMapper.fromJson(json);
}

class ArgumentsHook extends MappingHook {
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

@MappableClass(ignoreNull: true)
class ToolResult with ToolResultMappable {
  final String? id;

  @MappableField(key: 'call_id')
  final String? callId;

  @MappableField(key: 'step_id')
  final String? stepId;

  /// The server name (e.g. MCP server name) associated with this tool result.
  @MappableField(key: 'server_name')
  final String? serverName;

  /// The tool name, normalized the same way as [ToolCall.name].
  final String name;
  final dynamic result;
  final String? error;

  @MappableField(hook: UnmappedHook())
  final Exception? exception;

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

  factory ToolResult.fromMap(Map<String, dynamic> map) =>
      ToolResultMapper.fromMap(map);
  factory ToolResult.fromJson(String json) => ToolResultMapper.fromJson(json);
}

class UnmappedHook extends MappingHook {
  const UnmappedHook();
  @override
  Object? beforeDecode(Object? value) => null;
  @override
  Object? beforeEncode(Object? value) => null;
}
