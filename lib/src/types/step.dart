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
    Map<String, dynamic>? updatedMap;
    if (!map.containsKey('content_delta') && map.containsKey('text_delta')) {
      updatedMap ??= Map<String, dynamic>.from(map);
      updatedMap['content_delta'] = map['text_delta'];
    }
    if (!map.containsKey('error') && map.containsKey('error_message')) {
      updatedMap ??= Map<String, dynamic>.from(map);
      updatedMap['error'] = map['error_message'];
    }
    return StepMapper.fromMap(updatedMap ?? map);
  }
  factory Step.fromJson(String json) => StepMapper.fromJson(json);
}
