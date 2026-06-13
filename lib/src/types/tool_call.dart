import 'dart:convert';
import 'package:dart_mappable/dart_mappable.dart';

part 'tool_call.mapper.dart';

@MappableClass(ignoreNull: true)
class ToolCall with ToolCallMappable {
  final String? id;
  final String name;

  @MappableField(key: 'arguments_json', hook: ArgumentsHook())
  final Map<String, dynamic> args;

  @MappableField(key: 'canonical_path')
  final String? canonicalPath;

  ToolCall({
    this.name = '',
    Map<String, dynamic>? args,
    this.id,
    this.canonicalPath,
  }) : args = args ?? {};

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
  final String name;
  final dynamic result;
  final String? error;

  @MappableField(hook: UnmappedHook())
  final Exception? exception;

  ToolResult({
    required this.name,
    this.id,
    this.result,
    this.error,
    this.exception,
  });

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
