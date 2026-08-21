import 'dart:convert';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:logging/logging.dart';

import '../models.dart';
import 'tool_call.dart';

part 'step.mapper.dart';

final _logger = Logger('antigravity.step');

@MappableEnum(caseStyle: CaseStyle.upperCase, defaultValue: StepType.unknown)
enum StepType {
  @MappableValue('TEXT_RESPONSE')
  textResponse('TEXT_RESPONSE'),
  @MappableValue('TOOL_CALL')
  toolCall('TOOL_CALL'),
  @MappableValue('SYSTEM_MESSAGE')
  systemMessage('SYSTEM_MESSAGE'),
  @MappableValue('COMPACTION')
  compaction('COMPACTION'),
  @MappableValue('FINISH')
  finish('FINISH'),
  @MappableValue('THINKING')
  thinking('THINKING'),
  unknown('UNKNOWN');

  final String value;
  const StepType(this.value);

  static StepType fromString(String val) {
    final res = StepTypeMapper.fromValue(val);
    if (res == StepType.unknown && val != 'UNKNOWN' && val != 'unknown') {
      return StepType.values.firstWhere(
        (e) => e.name == val,
        orElse: () => StepType.unknown,
      );
    }
    return res;
  }
}

@MappableEnum(caseStyle: CaseStyle.upperCase, defaultValue: StepSource.unknown)
enum StepSource {
  @MappableValue('SYSTEM')
  system('SYSTEM'),
  @MappableValue('USER')
  user('USER'),
  @MappableValue('MODEL')
  model('MODEL'),
  unknown('UNKNOWN');

  final String value;
  const StepSource(this.value);

  static StepSource fromString(String val) {
    final res = StepSourceMapper.fromValue(val);
    if (res == StepSource.unknown && val != 'UNKNOWN' && val != 'unknown') {
      return StepSource.values.firstWhere(
        (e) => e.name == val,
        orElse: () => StepSource.unknown,
      );
    }
    return res;
  }
}

@MappableEnum(caseStyle: CaseStyle.upperCase, defaultValue: StepTarget.unknown)
enum StepTarget {
  @MappableValue('TARGET_USER')
  user('TARGET_USER'),
  @MappableValue('TARGET_ENVIRONMENT')
  environment('TARGET_ENVIRONMENT'),
  @MappableValue('TARGET_UNSPECIFIED')
  unspecified('TARGET_UNSPECIFIED'),
  unknown('UNKNOWN');

  final String value;
  const StepTarget(this.value);

  static StepTarget fromString(String val) {
    final res = StepTargetMapper.fromValue(val);
    if (res == StepTarget.unknown && val != 'UNKNOWN' && val != 'unknown') {
      return StepTarget.values.firstWhere(
        (e) => e.name == val,
        orElse: () => StepTarget.unknown,
      );
    }
    return res;
  }
}

@MappableEnum(caseStyle: CaseStyle.upperCase, defaultValue: StepStatus.unknown)
enum StepStatus {
  @MappableValue('ACTIVE')
  active('ACTIVE'),
  @MappableValue('DONE')
  done('DONE'),
  @MappableValue('WAITING_FOR_USER')
  waitingForUser('WAITING_FOR_USER'),
  @MappableValue('ERROR')
  error('ERROR'),
  @MappableValue('CANCELED')
  canceled('CANCELED'),
  unknown('UNKNOWN');

  final String value;
  const StepStatus(this.value);

  static StepStatus fromString(String val) {
    final res = StepStatusMapper.fromValue(val);
    if (res == StepStatus.unknown && val != 'UNKNOWN' && val != 'unknown') {
      return StepStatus.values.firstWhere(
        (e) => e.name == val,
        orElse: () => StepStatus.unknown,
      );
    }
    return res;
  }
}

@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class UsageMetadata with UsageMetadataMappable {
  final int? promptTokenCount;
  final int? cachedContentTokenCount;
  final int? candidatesTokenCount;
  final int? thoughtsTokenCount;
  final int? totalTokenCount;
  final ServiceTier? serviceTier;

  UsageMetadata({
    this.promptTokenCount,
    this.cachedContentTokenCount,
    this.candidatesTokenCount,
    this.thoughtsTokenCount,
    this.totalTokenCount,
    this.serviceTier,
  });

  factory UsageMetadata.fromMap(Map<String, dynamic> map) =>
      UsageMetadataMapper.fromMap(map);
  factory UsageMetadata.fromJson(String json) =>
      UsageMetadataMapper.fromJson(json);

  /// Combines two [UsageMetadata] instances by summing their token counts.
  UsageMetadata operator +(UsageMetadata other) {
    ServiceTier? mergedTier;
    if (serviceTier == other.serviceTier) {
      mergedTier = serviceTier;
    } else if (serviceTier == null || other.serviceTier == null) {
      mergedTier = serviceTier ?? other.serviceTier;
    } else {
      mergedTier = ServiceTier.standard;
    }
    return UsageMetadata(
      promptTokenCount: (promptTokenCount ?? 0) + (other.promptTokenCount ?? 0),
      cachedContentTokenCount:
          (cachedContentTokenCount ?? 0) + (other.cachedContentTokenCount ?? 0),
      candidatesTokenCount:
          (candidatesTokenCount ?? 0) + (other.candidatesTokenCount ?? 0),
      thoughtsTokenCount:
          (thoughtsTokenCount ?? 0) + (other.thoughtsTokenCount ?? 0),
      totalTokenCount: (totalTokenCount ?? 0) + (other.totalTokenCount ?? 0),
      serviceTier: mergedTier,
    );
  }

  /// Computes the difference between two [UsageMetadata] instances by subtracting their token counts.
  UsageMetadata operator -(UsageMetadata other) {
    return UsageMetadata(
      promptTokenCount: (promptTokenCount ?? 0) - (other.promptTokenCount ?? 0),
      cachedContentTokenCount:
          (cachedContentTokenCount ?? 0) - (other.cachedContentTokenCount ?? 0),
      candidatesTokenCount:
          (candidatesTokenCount ?? 0) - (other.candidatesTokenCount ?? 0),
      thoughtsTokenCount:
          (thoughtsTokenCount ?? 0) - (other.thoughtsTokenCount ?? 0),
      totalTokenCount: (totalTokenCount ?? 0) - (other.totalTokenCount ?? 0),
      serviceTier: serviceTier ?? other.serviceTier,
    );
  }
}

/// Represents a single execution step or lifecycle event emitted during an agent trajectory.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class Step with StepMappable {
  /// Unique identifier of the step.
  final String id;

  /// 0-indexed step position within the trajectory sequence.
  final int stepIndex;

  /// Root conversation identifier.
  final String cascadeId;

  /// Identifier of the specific trajectory execution.
  final String trajectoryId;

  /// Trajectory identifier of the parent agent when invoked as a subagent.
  final String parentTrajectoryId;

  /// Nesting depth of subagent invocation (0 for root agent).
  final int depth;

  /// The category or classification of this step.
  final StepType type;

  /// Originator of the step (system, user, or model).
  final StepSource source;

  /// Intended recipient/target for the step event.
  final StepTarget target;

  /// Lifecycle or execution status of the step.
  final StepStatus status;

  /// Accumulated text content associated with this step.
  final String content;

  /// Incremental token delta for streaming text responses.
  final String contentDelta;

  /// Accumulated reasoning/thinking content for models supporting extended thinking.
  final String thinking;

  /// Incremental token delta for streaming reasoning thoughts.
  final String thinkingDelta;

  /// Tool invocations requested or completed in this step.
  final List<ToolCall> toolCalls;

  /// Error message if step execution failed.
  final String error;

  /// Whether this step constitutes the complete terminal response for the turn.
  final bool? isCompleteResponse;

  /// Structured JSON output extracted from finish payload, if schema enforcement was enabled.
  final dynamic structuredOutput;

  /// Token usage metadata associated with this step.
  final UsageMetadata? usageMetadata;

  Step({
    this.id = '',
    this.stepIndex = 0,
    this.cascadeId = '',
    this.trajectoryId = '',
    this.parentTrajectoryId = '',
    this.depth = 0,
    this.type = StepType.unknown,
    this.source = StepSource.unknown,
    this.target = StepTarget.unknown,
    this.status = StepStatus.unknown,
    this.content = '',
    this.contentDelta = '',
    this.thinking = '',
    this.thinkingDelta = '',
    this.toolCalls = const [],
    this.error = '',
    this.isCompleteResponse,
    this.structuredOutput,
    this.usageMetadata,
  });

  factory Step.fromMap(Map<String, dynamic> map) {
    final updatedMap = _normalizeStepKeys(map);
    _normalizeContentFields(updatedMap);
    _normalizeError(updatedMap);
    _normalizeStatusAndSource(updatedMap);
    _normalizeUsageMetadata(updatedMap);

    final toolCalls = _extractToolCalls(updatedMap);
    if (toolCalls.isNotEmpty) {
      updatedMap['tool_calls'] = toolCalls;
    }

    _determineStepType(updatedMap, toolCalls.isNotEmpty);
    _extractStructuredOutput(updatedMap);
    _determineIsCompleteResponse(updatedMap);

    return StepMapper.fromMap(updatedMap);
  }

  static Map<String, dynamic> _normalizeStepKeys(Map<String, dynamic> map) {
    final updatedMap = <String, dynamic>{};
    map.forEach((key, val) {
      updatedMap[_toSnakeCase(key)] = val;
    });
    if (updatedMap.containsKey('depth')) {
      updatedMap['depth'] = int.tryParse(updatedMap['depth'].toString()) ?? 0;
    }
    return updatedMap;
  }

  static void _normalizeContentFields(Map<String, dynamic> map) {
    if (!map.containsKey('content') && map.containsKey('text')) {
      map['content'] = map['text'];
    }
    if (!map.containsKey('content_delta') && map.containsKey('text_delta')) {
      map['content_delta'] = map['text_delta'];
    }
  }

  static void _normalizeError(Map<String, dynamic> map) {
    if (map.containsKey('error')) {
      final err = map['error'];
      map['error'] = err is Map
          ? (err['error_message'] ?? err['errorMessage'] ?? '').toString()
          : err.toString();
    } else if (map.containsKey('error_message')) {
      map['error'] = map['error_message'];
    }
  }

  static void _normalizeStatusAndSource(Map<String, dynamic> map) {
    if (map.containsKey('state')) {
      map['status'] = switch (map['state'].toString()) {
        'STATE_ACTIVE' || 'ACTIVE' => 'ACTIVE',
        'STATE_DONE' || 'DONE' => 'DONE',
        'STATE_WAITING_FOR_USER' || 'WAITING_FOR_USER' => 'WAITING_FOR_USER',
        'STATE_ERROR' || 'ERROR' => 'ERROR',
        'STATE_CANCELED' || 'CANCELED' => 'CANCELED',
        _ => 'UNKNOWN',
      };
    }
    if (map.containsKey('source')) {
      map['source'] = switch (map['source'].toString()) {
        'SOURCE_SYSTEM' || 'SYSTEM' => 'SYSTEM',
        'SOURCE_USER' || 'USER' => 'USER',
        'SOURCE_MODEL' || 'MODEL' => 'MODEL',
        _ => 'UNKNOWN',
      };
    }
  }

  static void _normalizeUsageMetadata(Map<String, dynamic> map) {
    final raw = map['usage_metadata'];
    if (raw is! Map) return;
    final normalized = <String, dynamic>{};
    raw.forEach((k, v) {
      if (v != null) {
        final snakeKey = _toSnakeCase(k.toString());
        normalized[snakeKey] = v is num ? v.toInt() : int.tryParse(v.toString());
      }
    });
    map['usage_metadata'] = normalized;
  }

  static const _toolFields = {
    'create_file': 'create_file',
    'edit_file': 'edit_file',
    'find_file': 'find_file',
    'list_directory': 'list_directory',
    'run_command': 'run_command',
    'search_directory': 'search_directory',
    'view_file': 'view_file',
    'invoke_subagent': 'invoke_subagent',
    'generate_image': 'generate_image',
    'search_web': 'search_web',
    'read_url_content': 'read_url_content',
    'finish': 'finish',
  };

  static List<Map<String, dynamic>> _extractToolCalls(Map<String, dynamic> map) {
    final singleCall = _extractSingleActiveTool(map);
    if (singleCall != null) {
      return [singleCall];
    }
    final rawList = map['tool_calls'] ?? map['toolCalls'];
    if (rawList is List) {
      return _parseRawToolCalls(rawList);
    }
    return const [];
  }

  static Map<String, dynamic>? _extractSingleActiveTool(Map<String, dynamic> map) {
    final detected =
        _findBuiltinTool(map) ?? _findMcpTool(map) ?? _findCustomTool(map);

    if (detected == null) return null;

    final canonicalPath = _normalizeToolPathArgs(detected.args);
    final trajId = map['trajectory_id']?.toString() ?? '';
    final stepIdx = map['step_index'] ?? 0;
    final stepId = trajId.isNotEmpty ? '$trajId:$stepIdx' : '$stepIdx';
    final callId = detected.id ?? stepId;

    return {
      'id': callId,
      'step_id': stepId,
      'name': detected.name,
      'arguments_json': detected.args,
      'arguments': detected.args,
      'canonical_path': canonicalPath,
      if (detected.serverName != null && detected.serverName!.isNotEmpty)
        'server_name': detected.serverName,
    };
  }

  static ({String name, Map<String, dynamic> args, String? serverName, String? id})? _findBuiltinTool(
    Map<String, dynamic> map,
  ) {
    for (final entry in _toolFields.entries) {
      final protoField = entry.key;
      final camel = _toCamelCase(protoField);
      final key = map.containsKey(protoField)
          ? protoField
          : (map.containsKey(camel) ? camel : null);

      if (key != null && map[key] is Map) {
        return (
          name: entry.value,
          args: Map<String, dynamic>.from(map[key] as Map),
          serverName: null,
          id: null,
        );
      }
    }
    return null;
  }

  static ({String name, Map<String, dynamic> args, String? serverName, String? id})? _findMcpTool(
    Map<String, dynamic> map,
  ) {
    final mcpKey = map.containsKey('mcp_tool')
        ? 'mcp_tool'
        : (map.containsKey('mcpTool') ? 'mcpTool' : null);
    if (mcpKey == null || map[mcpKey] is! Map) return null;

    final dict = Map<String, dynamic>.from(map[mcpKey] as Map);
    final serverName = (dict['server_name'] ?? dict['serverName'] ?? '').toString();
    final toolName = (dict['tool_name'] ?? dict['toolName'] ?? '').toString();
    final argsJson = dict['arguments_json'] ?? dict['argumentsJson'] ?? '{}';
    final args = _decodeToolArguments(argsJson);

    return (name: toolName, args: args, serverName: serverName, id: null);
  }

  static ({String name, Map<String, dynamic> args, String? serverName, String? id})? _findCustomTool(
    Map<String, dynamic> map,
  ) {
    final customKey = map.containsKey('custom_tool')
        ? 'custom_tool'
        : (map.containsKey('customTool') ? 'customTool' : null);
    if (customKey == null || map[customKey] is! Map) return null;

    final ctDict = Map<String, dynamic>.from(map[customKey] as Map);
    final tcKey = ctDict.containsKey('tool_call')
        ? 'tool_call'
        : (ctDict.containsKey('toolCall') ? 'toolCall' : null);
    if (tcKey == null || ctDict[tcKey] is! Map) return null;

    final tcDict = Map<String, dynamic>.from(ctDict[tcKey] as Map);
    final name = tcDict['name']?.toString();
    if (name == null || name.isEmpty) return null;

    final argsJson = tcDict['arguments_json'] ?? tcDict['argumentsJson'] ?? '{}';
    final args = _decodeToolArguments(argsJson);

    return (name: name, args: args, serverName: null, id: tcDict['id']?.toString());
  }

  static Map<String, dynamic> _decodeToolArguments(dynamic argsJson) {
    try {
      if (argsJson is String) {
        return Map<String, dynamic>.from(jsonDecode(argsJson) as Map);
      }
      if (argsJson is Map) {
        return Map<String, dynamic>.from(argsJson);
      }
    } catch (e) {
      _logger.warning('Failed to parse tool arguments_json: $e');
    }
    return <String, dynamic>{};
  }

  static const _pathKeys = [
    'path',
    'file_path',
    'TargetFile',
    'directory_path',
    'output_path',
  ];

  static String? _normalizeToolPathArgs(Map<String, dynamic> args) {
    String? canonicalPath;
    for (final pathKey in _pathKeys) {
      final snakeKey = _toSnakeCase(pathKey);
      final key = args.containsKey(pathKey)
          ? pathKey
          : (args.containsKey(snakeKey) ? snakeKey : null);
      if (key != null && args[key] is String) {
        final normalized = _normalizeWirePath(args[key] as String);
        args[key] = normalized;
        canonicalPath ??= normalized;
      }
    }
    return canonicalPath;
  }

  static List<Map<String, dynamic>> _parseRawToolCalls(List rawCalls) {
    final toolCalls = <Map<String, dynamic>>[];
    for (final rawCall in rawCalls) {
      if (rawCall is! Map) continue;
      final callMap = Map<String, dynamic>.from(rawCall);
      final args = _decodeToolArguments(callMap['arguments_json'] ?? callMap['arguments']);
      final canonicalPath = _normalizeToolPathArgs(args) ?? callMap['canonical_path']?.toString();

      callMap['arguments'] = args;
      callMap['arguments_json'] = args;
      callMap['canonical_path'] = canonicalPath;
      toolCalls.add(callMap);
    }
    return toolCalls;
  }

  static void _determineStepType(Map<String, dynamic> map, bool hasToolCalls) {
    if (map['type'] != null && map['type'] != 'UNKNOWN') return;

    if (map['compaction'] != null) {
      map['type'] = 'COMPACTION';
    } else if (map['finish'] != null) {
      map['type'] = 'FINISH';
    } else if (hasToolCalls) {
      map['type'] = 'TOOL_CALL';
    } else if (map['thinking'] != null && map['thinking'].toString().isNotEmpty) {
      map['type'] = 'THINKING';
    } else if (map['text'] != null && map['text'].toString().isNotEmpty) {
      map['type'] = 'TEXT_RESPONSE';
    } else {
      map['type'] = 'UNKNOWN';
    }
  }

  static void _extractStructuredOutput(Map<String, dynamic> map) {
    final finish = map['finish'];
    if (finish is! Map) return;
    final outputString = finish['output_string'] ?? finish['outputString'];
    if (outputString != null && outputString.toString().isNotEmpty) {
      try {
        map['structured_output'] = jsonDecode(outputString.toString());
      } catch (e) {
        _logger.warning('Failed to parse structured output JSON: $e');
      }
    }
  }

  static void _determineIsCompleteResponse(Map<String, dynamic> map) {
    final isFromModel = map['source'] == 'MODEL';
    final isDone = map['status'] == 'DONE';
    final hasText = map['content'] != null && map['content'].toString().isNotEmpty;
    final isTargetUser = map['target'] == 'TARGET_USER' || map['target'] == 'user';
    map['is_complete_response'] = isFromModel && isDone && hasText && isTargetUser;
  }

  static String _normalizeWirePath(String path) {
    final uri = Uri.tryParse(path);
    if (uri != null && uri.scheme == 'file') {
      return Uri.decodeComponent(uri.path);
    }
    return path;
  }

  static String _toSnakeCase(String camel) {
    final exp = RegExp('(?<=[a-z0-9])[A-Z]');
    return camel.replaceAllMapped(exp, (m) => '_${m.group(0)}').toLowerCase();
  }

  static String _toCamelCase(String snake) {
    final exp = RegExp('_(.)');
    return snake.replaceAllMapped(exp, (m) => m.group(1)!.toUpperCase());
  }

  factory Step.fromJson(String json) => StepMapper.fromJson(json);
}

/// Extension methods for [StepSource] providing idiomatic boolean checks.
extension StepSourceX on StepSource {
  /// Returns true if this step originated from the user.
  bool get isUser => this == StepSource.user;

  /// Returns true if this step originated from the model agent.
  bool get isModel => this == StepSource.model;

  /// Returns true if this step originated from the system.
  bool get isSystem => this == StepSource.system;
}

/// Extension methods for [StepStatus] providing idiomatic boolean checks.
extension StepStatusX on StepStatus {
  /// Returns true if the step has completed execution successfully.
  bool get isDone => this == StepStatus.done;

  /// Returns true if the step is currently executing.
  bool get isActive => this == StepStatus.active;

  /// Returns true if the step was canceled.
  bool get isCanceled => this == StepStatus.canceled;

  /// Returns true if the step encountered an error.
  bool get isError => this == StepStatus.error;
}

/// Extension methods for [Step] providing idiomatic turn and state checks.
extension StepX on Step {
  /// Returns true if this step is a user turn.
  bool get isUserTurn => source.isUser;

  /// Returns true if this step is a model turn.
  bool get isModelTurn => source.isModel;

  /// Returns true if this step is finished (done, canceled, or error).
  bool get isFinished => status.isDone || status.isCanceled || status.isError;
}
