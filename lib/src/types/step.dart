import 'package:dart_mappable/dart_mappable.dart';

import 'tool_call.dart';

part 'step.mapper.dart';

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

  UsageMetadata({
    this.promptTokenCount,
    this.cachedContentTokenCount,
    this.candidatesTokenCount,
    this.thoughtsTokenCount,
    this.totalTokenCount,
  });

  factory UsageMetadata.fromMap(Map<String, dynamic> map) =>
      UsageMetadataMapper.fromMap(map);
  factory UsageMetadata.fromJson(String json) =>
      UsageMetadataMapper.fromJson(json);
}

@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class Step with StepMappable {
  final String id;
  final int stepIndex;
  final String cascadeId;
  final String trajectoryId;

  final StepType type;
  final StepSource source;
  final StepTarget target;
  final StepStatus status;

  final String content;
  final String contentDelta;
  final String thinking;
  final String thinkingDelta;
  final List<ToolCall> toolCalls;
  final String error;

  final bool? isCompleteResponse;
  final dynamic structuredOutput;
  final UsageMetadata? usageMetadata;

  Step({
    this.id = '',
    this.stepIndex = 0,
    this.cascadeId = '',
    this.trajectoryId = '',
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
    final updatedMap = Map<String, dynamic>.from(map);

    // 1. Map 'text' to 'content'
    if (!updatedMap.containsKey('content') && updatedMap.containsKey('text')) {
      updatedMap['content'] = updatedMap['text'];
    }

    // 2. Map 'text_delta' to 'content_delta'
    if (!updatedMap.containsKey('content_delta') &&
        updatedMap.containsKey('text_delta')) {
      updatedMap['content_delta'] = updatedMap['text_delta'];
    }

    // 3. Extract nested error message
    if (updatedMap.containsKey('error')) {
      final errorField = updatedMap['error'];
      if (errorField is Map) {
        updatedMap['error'] = errorField['error_message'] ?? '';
      } else if (errorField is! String) {
        updatedMap['error'] = errorField.toString();
      }
    } else if (updatedMap.containsKey('error_message')) {
      updatedMap['error'] = updatedMap['error_message'];
    }

    // 4. Map 'state' to 'status'
    if (updatedMap.containsKey('state')) {
      final stateStr = updatedMap['state'].toString();
      var statusVal = 'UNKNOWN';
      if (stateStr == 'STATE_ACTIVE' || stateStr == 'ACTIVE') {
        statusVal = 'ACTIVE';
      } else if (stateStr == 'STATE_DONE' || stateStr == 'DONE') {
        statusVal = 'DONE';
      } else if (stateStr == 'STATE_WAITING_FOR_USER' ||
          stateStr == 'WAITING_FOR_USER') {
        statusVal = 'WAITING_FOR_USER';
      } else if (stateStr == 'STATE_ERROR' || stateStr == 'ERROR') {
        statusVal = 'ERROR';
      } else if (stateStr == 'STATE_CANCELED' || stateStr == 'CANCELED') {
        statusVal = 'CANCELED';
      }
      updatedMap['status'] = statusVal;
    }

    // 5. Map 'source'
    if (updatedMap.containsKey('source')) {
      final sourceStr = updatedMap['source'].toString();
      var sourceVal = 'UNKNOWN';
      if (sourceStr == 'SOURCE_SYSTEM' || sourceStr == 'SYSTEM') {
        sourceVal = 'SYSTEM';
      } else if (sourceStr == 'SOURCE_USER' || sourceStr == 'USER') {
        sourceVal = 'USER';
      } else if (sourceStr == 'SOURCE_MODEL' || sourceStr == 'MODEL') {
        sourceVal = 'MODEL';
      }
      updatedMap['source'] = sourceVal;
    }

    // 6. Parse tool calls
    const toolFields = {
      'create_file': 'create_file',
      'edit_file': 'edit_file',
      'find_file': 'find_file',
      'list_directory': 'list_directory',
      'run_command': 'run_command',
      'search_directory': 'search_directory',
      'view_file': 'view_file',
      'invoke_subagent': 'invoke_subagent',
      'generate_image': 'generate_image',
      'finish': 'finish',
    };

    final toolCalls = <Map<String, dynamic>>[];
    for (final entry in toolFields.entries) {
      final protoField = entry.key;
      final toolName = entry.value;
      if (updatedMap.containsKey(protoField) && updatedMap[protoField] is Map) {
        final rawArgs = Map<String, dynamic>.from(
          updatedMap[protoField] as Map,
        );

        // Normalize file paths
        String? canonicalPath;
        const pathKeys = ['path', 'file_path', 'TargetFile', 'directory_path'];
        for (final pathKey in pathKeys) {
          if (rawArgs.containsKey(pathKey) && rawArgs[pathKey] is String) {
            final normalized = _normalizeWirePath(rawArgs[pathKey] as String);
            rawArgs[pathKey] = normalized;
            canonicalPath = normalized;
          }
        }

        final trajId = updatedMap['trajectory_id'] ?? '';
        final stepIdx = updatedMap['step_index'] ?? 0;
        final callId = trajId.isNotEmpty ? '$trajId:$stepIdx' : '$stepIdx';

        toolCalls.add({
          'id': callId,
          'name': toolName,
          'arguments_json': rawArgs,
          'arguments': rawArgs,
          'canonical_path': canonicalPath,
        });
      }
    }
    if (toolCalls.isNotEmpty) {
      updatedMap['tool_calls'] = toolCalls;
    }

    // 7. Determine StepType type
    if (!updatedMap.containsKey('type') ||
        updatedMap['type'] == null ||
        updatedMap['type'] == 'UNKNOWN') {
      var typeVal = 'UNKNOWN';
      if (updatedMap['compaction'] != null) {
        typeVal = 'COMPACTION';
      } else if (updatedMap['finish'] != null) {
        typeVal = 'FINISH';
      } else if (toolCalls.isNotEmpty) {
        typeVal = 'TOOL_CALL';
      } else if (updatedMap['text'] != null &&
          updatedMap['text'].toString().isNotEmpty) {
        typeVal = 'TEXT_RESPONSE';
      }
      updatedMap['type'] = typeVal;
    }

    return StepMapper.fromMap(updatedMap);
  }

  static String _normalizeWirePath(String path) {
    final uri = Uri.tryParse(path);
    if (uri != null && uri.scheme == 'file') {
      return Uri.decodeComponent(uri.path);
    }
    return path;
  }

  factory Step.fromJson(String json) => StepMapper.fromJson(json);
}
