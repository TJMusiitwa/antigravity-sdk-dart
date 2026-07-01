// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'step.dart';

class StepTypeMapper extends EnumMapper<StepType> {
  StepTypeMapper._();

  static StepTypeMapper? _instance;
  static StepTypeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = StepTypeMapper._());
    }
    return _instance!;
  }

  static StepType fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  StepType decode(dynamic value) {
    switch (value) {
      case 'TEXT_RESPONSE':
        return StepType.textResponse;
      case 'TOOL_CALL':
        return StepType.toolCall;
      case 'SYSTEM_MESSAGE':
        return StepType.systemMessage;
      case 'COMPACTION':
        return StepType.compaction;
      case 'FINISH':
        return StepType.finish;
      case 'THINKING':
        return StepType.thinking;
      case r'UNKNOWN':
        return StepType.unknown;
      default:
        return StepType.values[6];
    }
  }

  @override
  dynamic encode(StepType self) {
    switch (self) {
      case StepType.textResponse:
        return 'TEXT_RESPONSE';
      case StepType.toolCall:
        return 'TOOL_CALL';
      case StepType.systemMessage:
        return 'SYSTEM_MESSAGE';
      case StepType.compaction:
        return 'COMPACTION';
      case StepType.finish:
        return 'FINISH';
      case StepType.thinking:
        return 'THINKING';
      case StepType.unknown:
        return r'UNKNOWN';
    }
  }
}

extension StepTypeMapperExtension on StepType {
  dynamic toValue() {
    StepTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<StepType>(this);
  }
}

class StepSourceMapper extends EnumMapper<StepSource> {
  StepSourceMapper._();

  static StepSourceMapper? _instance;
  static StepSourceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = StepSourceMapper._());
    }
    return _instance!;
  }

  static StepSource fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  StepSource decode(dynamic value) {
    switch (value) {
      case 'SYSTEM':
        return StepSource.system;
      case 'USER':
        return StepSource.user;
      case 'MODEL':
        return StepSource.model;
      case r'UNKNOWN':
        return StepSource.unknown;
      default:
        return StepSource.values[3];
    }
  }

  @override
  dynamic encode(StepSource self) {
    switch (self) {
      case StepSource.system:
        return 'SYSTEM';
      case StepSource.user:
        return 'USER';
      case StepSource.model:
        return 'MODEL';
      case StepSource.unknown:
        return r'UNKNOWN';
    }
  }
}

extension StepSourceMapperExtension on StepSource {
  dynamic toValue() {
    StepSourceMapper.ensureInitialized();
    return MapperContainer.globals.toValue<StepSource>(this);
  }
}

class StepTargetMapper extends EnumMapper<StepTarget> {
  StepTargetMapper._();

  static StepTargetMapper? _instance;
  static StepTargetMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = StepTargetMapper._());
    }
    return _instance!;
  }

  static StepTarget fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  StepTarget decode(dynamic value) {
    switch (value) {
      case 'TARGET_USER':
        return StepTarget.user;
      case 'TARGET_ENVIRONMENT':
        return StepTarget.environment;
      case 'TARGET_UNSPECIFIED':
        return StepTarget.unspecified;
      case r'UNKNOWN':
        return StepTarget.unknown;
      default:
        return StepTarget.values[3];
    }
  }

  @override
  dynamic encode(StepTarget self) {
    switch (self) {
      case StepTarget.user:
        return 'TARGET_USER';
      case StepTarget.environment:
        return 'TARGET_ENVIRONMENT';
      case StepTarget.unspecified:
        return 'TARGET_UNSPECIFIED';
      case StepTarget.unknown:
        return r'UNKNOWN';
    }
  }
}

extension StepTargetMapperExtension on StepTarget {
  dynamic toValue() {
    StepTargetMapper.ensureInitialized();
    return MapperContainer.globals.toValue<StepTarget>(this);
  }
}

class StepStatusMapper extends EnumMapper<StepStatus> {
  StepStatusMapper._();

  static StepStatusMapper? _instance;
  static StepStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = StepStatusMapper._());
    }
    return _instance!;
  }

  static StepStatus fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  StepStatus decode(dynamic value) {
    switch (value) {
      case 'ACTIVE':
        return StepStatus.active;
      case 'DONE':
        return StepStatus.done;
      case 'WAITING_FOR_USER':
        return StepStatus.waitingForUser;
      case 'ERROR':
        return StepStatus.error;
      case 'CANCELED':
        return StepStatus.canceled;
      case r'UNKNOWN':
        return StepStatus.unknown;
      default:
        return StepStatus.values[5];
    }
  }

  @override
  dynamic encode(StepStatus self) {
    switch (self) {
      case StepStatus.active:
        return 'ACTIVE';
      case StepStatus.done:
        return 'DONE';
      case StepStatus.waitingForUser:
        return 'WAITING_FOR_USER';
      case StepStatus.error:
        return 'ERROR';
      case StepStatus.canceled:
        return 'CANCELED';
      case StepStatus.unknown:
        return r'UNKNOWN';
    }
  }
}

extension StepStatusMapperExtension on StepStatus {
  dynamic toValue() {
    StepStatusMapper.ensureInitialized();
    return MapperContainer.globals.toValue<StepStatus>(this);
  }
}

class UsageMetadataMapper extends ClassMapperBase<UsageMetadata> {
  UsageMetadataMapper._();

  static UsageMetadataMapper? _instance;
  static UsageMetadataMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = UsageMetadataMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'UsageMetadata';

  static int? _$promptTokenCount(UsageMetadata v) => v.promptTokenCount;
  static const Field<UsageMetadata, int> _f$promptTokenCount = Field(
    'promptTokenCount',
    _$promptTokenCount,
    key: r'prompt_token_count',
    opt: true,
  );
  static int? _$cachedContentTokenCount(UsageMetadata v) =>
      v.cachedContentTokenCount;
  static const Field<UsageMetadata, int> _f$cachedContentTokenCount = Field(
    'cachedContentTokenCount',
    _$cachedContentTokenCount,
    key: r'cached_content_token_count',
    opt: true,
  );
  static int? _$candidatesTokenCount(UsageMetadata v) => v.candidatesTokenCount;
  static const Field<UsageMetadata, int> _f$candidatesTokenCount = Field(
    'candidatesTokenCount',
    _$candidatesTokenCount,
    key: r'candidates_token_count',
    opt: true,
  );
  static int? _$thoughtsTokenCount(UsageMetadata v) => v.thoughtsTokenCount;
  static const Field<UsageMetadata, int> _f$thoughtsTokenCount = Field(
    'thoughtsTokenCount',
    _$thoughtsTokenCount,
    key: r'thoughts_token_count',
    opt: true,
  );
  static int? _$totalTokenCount(UsageMetadata v) => v.totalTokenCount;
  static const Field<UsageMetadata, int> _f$totalTokenCount = Field(
    'totalTokenCount',
    _$totalTokenCount,
    key: r'total_token_count',
    opt: true,
  );

  @override
  final MappableFields<UsageMetadata> fields = const {
    #promptTokenCount: _f$promptTokenCount,
    #cachedContentTokenCount: _f$cachedContentTokenCount,
    #candidatesTokenCount: _f$candidatesTokenCount,
    #thoughtsTokenCount: _f$thoughtsTokenCount,
    #totalTokenCount: _f$totalTokenCount,
  };
  @override
  final bool ignoreNull = true;

  static UsageMetadata _instantiate(DecodingData data) {
    return UsageMetadata(
      promptTokenCount: data.dec(_f$promptTokenCount),
      cachedContentTokenCount: data.dec(_f$cachedContentTokenCount),
      candidatesTokenCount: data.dec(_f$candidatesTokenCount),
      thoughtsTokenCount: data.dec(_f$thoughtsTokenCount),
      totalTokenCount: data.dec(_f$totalTokenCount),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static UsageMetadata fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<UsageMetadata>(map);
  }

  static UsageMetadata fromJson(String json) {
    return ensureInitialized().decodeJson<UsageMetadata>(json);
  }
}

mixin UsageMetadataMappable {
  String toJson() {
    return UsageMetadataMapper.ensureInitialized().encodeJson<UsageMetadata>(
      this as UsageMetadata,
    );
  }

  Map<String, dynamic> toMap() {
    return UsageMetadataMapper.ensureInitialized().encodeMap<UsageMetadata>(
      this as UsageMetadata,
    );
  }

  UsageMetadataCopyWith<UsageMetadata, UsageMetadata, UsageMetadata>
  get copyWith => _UsageMetadataCopyWithImpl<UsageMetadata, UsageMetadata>(
    this as UsageMetadata,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return UsageMetadataMapper.ensureInitialized().stringifyValue(
      this as UsageMetadata,
    );
  }

  @override
  bool operator ==(Object other) {
    return UsageMetadataMapper.ensureInitialized().equalsValue(
      this as UsageMetadata,
      other,
    );
  }

  @override
  int get hashCode {
    return UsageMetadataMapper.ensureInitialized().hashValue(
      this as UsageMetadata,
    );
  }
}

extension UsageMetadataValueCopy<$R, $Out>
    on ObjectCopyWith<$R, UsageMetadata, $Out> {
  UsageMetadataCopyWith<$R, UsageMetadata, $Out> get $asUsageMetadata =>
      $base.as((v, t, t2) => _UsageMetadataCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class UsageMetadataCopyWith<$R, $In extends UsageMetadata, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    int? promptTokenCount,
    int? cachedContentTokenCount,
    int? candidatesTokenCount,
    int? thoughtsTokenCount,
    int? totalTokenCount,
  });
  UsageMetadataCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _UsageMetadataCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, UsageMetadata, $Out>
    implements UsageMetadataCopyWith<$R, UsageMetadata, $Out> {
  _UsageMetadataCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<UsageMetadata> $mapper =
      UsageMetadataMapper.ensureInitialized();
  @override
  $R call({
    Object? promptTokenCount = $none,
    Object? cachedContentTokenCount = $none,
    Object? candidatesTokenCount = $none,
    Object? thoughtsTokenCount = $none,
    Object? totalTokenCount = $none,
  }) => $apply(
    FieldCopyWithData({
      if (promptTokenCount != $none) #promptTokenCount: promptTokenCount,
      if (cachedContentTokenCount != $none)
        #cachedContentTokenCount: cachedContentTokenCount,
      if (candidatesTokenCount != $none)
        #candidatesTokenCount: candidatesTokenCount,
      if (thoughtsTokenCount != $none) #thoughtsTokenCount: thoughtsTokenCount,
      if (totalTokenCount != $none) #totalTokenCount: totalTokenCount,
    }),
  );
  @override
  UsageMetadata $make(CopyWithData data) => UsageMetadata(
    promptTokenCount: data.get(#promptTokenCount, or: $value.promptTokenCount),
    cachedContentTokenCount: data.get(
      #cachedContentTokenCount,
      or: $value.cachedContentTokenCount,
    ),
    candidatesTokenCount: data.get(
      #candidatesTokenCount,
      or: $value.candidatesTokenCount,
    ),
    thoughtsTokenCount: data.get(
      #thoughtsTokenCount,
      or: $value.thoughtsTokenCount,
    ),
    totalTokenCount: data.get(#totalTokenCount, or: $value.totalTokenCount),
  );

  @override
  UsageMetadataCopyWith<$R2, UsageMetadata, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _UsageMetadataCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class StepMapper extends ClassMapperBase<Step> {
  StepMapper._();

  static StepMapper? _instance;
  static StepMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = StepMapper._());
      StepTypeMapper.ensureInitialized();
      StepSourceMapper.ensureInitialized();
      StepTargetMapper.ensureInitialized();
      StepStatusMapper.ensureInitialized();
      ToolCallMapper.ensureInitialized();
      UsageMetadataMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Step';

  static String _$id(Step v) => v.id;
  static const Field<Step, String> _f$id = Field(
    'id',
    _$id,
    opt: true,
    def: '',
  );
  static int _$stepIndex(Step v) => v.stepIndex;
  static const Field<Step, int> _f$stepIndex = Field(
    'stepIndex',
    _$stepIndex,
    key: r'step_index',
    opt: true,
    def: 0,
  );
  static String _$cascadeId(Step v) => v.cascadeId;
  static const Field<Step, String> _f$cascadeId = Field(
    'cascadeId',
    _$cascadeId,
    key: r'cascade_id',
    opt: true,
    def: '',
  );
  static String _$trajectoryId(Step v) => v.trajectoryId;
  static const Field<Step, String> _f$trajectoryId = Field(
    'trajectoryId',
    _$trajectoryId,
    key: r'trajectory_id',
    opt: true,
    def: '',
  );
  static StepType _$type(Step v) => v.type;
  static const Field<Step, StepType> _f$type = Field(
    'type',
    _$type,
    opt: true,
    def: StepType.unknown,
  );
  static StepSource _$source(Step v) => v.source;
  static const Field<Step, StepSource> _f$source = Field(
    'source',
    _$source,
    opt: true,
    def: StepSource.unknown,
  );
  static StepTarget _$target(Step v) => v.target;
  static const Field<Step, StepTarget> _f$target = Field(
    'target',
    _$target,
    opt: true,
    def: StepTarget.unknown,
  );
  static StepStatus _$status(Step v) => v.status;
  static const Field<Step, StepStatus> _f$status = Field(
    'status',
    _$status,
    opt: true,
    def: StepStatus.unknown,
  );
  static String _$content(Step v) => v.content;
  static const Field<Step, String> _f$content = Field(
    'content',
    _$content,
    opt: true,
    def: '',
  );
  static String _$contentDelta(Step v) => v.contentDelta;
  static const Field<Step, String> _f$contentDelta = Field(
    'contentDelta',
    _$contentDelta,
    key: r'content_delta',
    opt: true,
    def: '',
  );
  static String _$thinking(Step v) => v.thinking;
  static const Field<Step, String> _f$thinking = Field(
    'thinking',
    _$thinking,
    opt: true,
    def: '',
  );
  static String _$thinkingDelta(Step v) => v.thinkingDelta;
  static const Field<Step, String> _f$thinkingDelta = Field(
    'thinkingDelta',
    _$thinkingDelta,
    key: r'thinking_delta',
    opt: true,
    def: '',
  );
  static List<ToolCall> _$toolCalls(Step v) => v.toolCalls;
  static const Field<Step, List<ToolCall>> _f$toolCalls = Field(
    'toolCalls',
    _$toolCalls,
    key: r'tool_calls',
    opt: true,
    def: const [],
  );
  static String _$error(Step v) => v.error;
  static const Field<Step, String> _f$error = Field(
    'error',
    _$error,
    opt: true,
    def: '',
  );
  static bool? _$isCompleteResponse(Step v) => v.isCompleteResponse;
  static const Field<Step, bool> _f$isCompleteResponse = Field(
    'isCompleteResponse',
    _$isCompleteResponse,
    key: r'is_complete_response',
    opt: true,
  );
  static dynamic _$structuredOutput(Step v) => v.structuredOutput;
  static const Field<Step, dynamic> _f$structuredOutput = Field(
    'structuredOutput',
    _$structuredOutput,
    key: r'structured_output',
    opt: true,
  );
  static UsageMetadata? _$usageMetadata(Step v) => v.usageMetadata;
  static const Field<Step, UsageMetadata> _f$usageMetadata = Field(
    'usageMetadata',
    _$usageMetadata,
    key: r'usage_metadata',
    opt: true,
  );

  @override
  final MappableFields<Step> fields = const {
    #id: _f$id,
    #stepIndex: _f$stepIndex,
    #cascadeId: _f$cascadeId,
    #trajectoryId: _f$trajectoryId,
    #type: _f$type,
    #source: _f$source,
    #target: _f$target,
    #status: _f$status,
    #content: _f$content,
    #contentDelta: _f$contentDelta,
    #thinking: _f$thinking,
    #thinkingDelta: _f$thinkingDelta,
    #toolCalls: _f$toolCalls,
    #error: _f$error,
    #isCompleteResponse: _f$isCompleteResponse,
    #structuredOutput: _f$structuredOutput,
    #usageMetadata: _f$usageMetadata,
  };
  @override
  final bool ignoreNull = true;

  static Step _instantiate(DecodingData data) {
    return Step(
      id: data.dec(_f$id),
      stepIndex: data.dec(_f$stepIndex),
      cascadeId: data.dec(_f$cascadeId),
      trajectoryId: data.dec(_f$trajectoryId),
      type: data.dec(_f$type),
      source: data.dec(_f$source),
      target: data.dec(_f$target),
      status: data.dec(_f$status),
      content: data.dec(_f$content),
      contentDelta: data.dec(_f$contentDelta),
      thinking: data.dec(_f$thinking),
      thinkingDelta: data.dec(_f$thinkingDelta),
      toolCalls: data.dec(_f$toolCalls),
      error: data.dec(_f$error),
      isCompleteResponse: data.dec(_f$isCompleteResponse),
      structuredOutput: data.dec(_f$structuredOutput),
      usageMetadata: data.dec(_f$usageMetadata),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Step fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Step>(map);
  }

  static Step fromJson(String json) {
    return ensureInitialized().decodeJson<Step>(json);
  }
}

mixin StepMappable {
  String toJson() {
    return StepMapper.ensureInitialized().encodeJson<Step>(this as Step);
  }

  Map<String, dynamic> toMap() {
    return StepMapper.ensureInitialized().encodeMap<Step>(this as Step);
  }

  StepCopyWith<Step, Step, Step> get copyWith =>
      _StepCopyWithImpl<Step, Step>(this as Step, $identity, $identity);
  @override
  String toString() {
    return StepMapper.ensureInitialized().stringifyValue(this as Step);
  }

  @override
  bool operator ==(Object other) {
    return StepMapper.ensureInitialized().equalsValue(this as Step, other);
  }

  @override
  int get hashCode {
    return StepMapper.ensureInitialized().hashValue(this as Step);
  }
}

extension StepValueCopy<$R, $Out> on ObjectCopyWith<$R, Step, $Out> {
  StepCopyWith<$R, Step, $Out> get $asStep =>
      $base.as((v, t, t2) => _StepCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class StepCopyWith<$R, $In extends Step, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, ToolCall, ToolCallCopyWith<$R, ToolCall, ToolCall>>
  get toolCalls;
  UsageMetadataCopyWith<$R, UsageMetadata, UsageMetadata>? get usageMetadata;
  $R call({
    String? id,
    int? stepIndex,
    String? cascadeId,
    String? trajectoryId,
    StepType? type,
    StepSource? source,
    StepTarget? target,
    StepStatus? status,
    String? content,
    String? contentDelta,
    String? thinking,
    String? thinkingDelta,
    List<ToolCall>? toolCalls,
    String? error,
    bool? isCompleteResponse,
    dynamic structuredOutput,
    UsageMetadata? usageMetadata,
  });
  StepCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _StepCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Step, $Out>
    implements StepCopyWith<$R, Step, $Out> {
  _StepCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Step> $mapper = StepMapper.ensureInitialized();
  @override
  ListCopyWith<$R, ToolCall, ToolCallCopyWith<$R, ToolCall, ToolCall>>
  get toolCalls => ListCopyWith(
    $value.toolCalls,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(toolCalls: v),
  );
  @override
  UsageMetadataCopyWith<$R, UsageMetadata, UsageMetadata>? get usageMetadata =>
      $value.usageMetadata?.copyWith.$chain((v) => call(usageMetadata: v));
  @override
  $R call({
    String? id,
    int? stepIndex,
    String? cascadeId,
    String? trajectoryId,
    StepType? type,
    StepSource? source,
    StepTarget? target,
    StepStatus? status,
    String? content,
    String? contentDelta,
    String? thinking,
    String? thinkingDelta,
    List<ToolCall>? toolCalls,
    String? error,
    Object? isCompleteResponse = $none,
    Object? structuredOutput = $none,
    Object? usageMetadata = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (stepIndex != null) #stepIndex: stepIndex,
      if (cascadeId != null) #cascadeId: cascadeId,
      if (trajectoryId != null) #trajectoryId: trajectoryId,
      if (type != null) #type: type,
      if (source != null) #source: source,
      if (target != null) #target: target,
      if (status != null) #status: status,
      if (content != null) #content: content,
      if (contentDelta != null) #contentDelta: contentDelta,
      if (thinking != null) #thinking: thinking,
      if (thinkingDelta != null) #thinkingDelta: thinkingDelta,
      if (toolCalls != null) #toolCalls: toolCalls,
      if (error != null) #error: error,
      if (isCompleteResponse != $none) #isCompleteResponse: isCompleteResponse,
      if (structuredOutput != $none) #structuredOutput: structuredOutput,
      if (usageMetadata != $none) #usageMetadata: usageMetadata,
    }),
  );
  @override
  Step $make(CopyWithData data) => Step(
    id: data.get(#id, or: $value.id),
    stepIndex: data.get(#stepIndex, or: $value.stepIndex),
    cascadeId: data.get(#cascadeId, or: $value.cascadeId),
    trajectoryId: data.get(#trajectoryId, or: $value.trajectoryId),
    type: data.get(#type, or: $value.type),
    source: data.get(#source, or: $value.source),
    target: data.get(#target, or: $value.target),
    status: data.get(#status, or: $value.status),
    content: data.get(#content, or: $value.content),
    contentDelta: data.get(#contentDelta, or: $value.contentDelta),
    thinking: data.get(#thinking, or: $value.thinking),
    thinkingDelta: data.get(#thinkingDelta, or: $value.thinkingDelta),
    toolCalls: data.get(#toolCalls, or: $value.toolCalls),
    error: data.get(#error, or: $value.error),
    isCompleteResponse: data.get(
      #isCompleteResponse,
      or: $value.isCompleteResponse,
    ),
    structuredOutput: data.get(#structuredOutput, or: $value.structuredOutput),
    usageMetadata: data.get(#usageMetadata, or: $value.usageMetadata),
  );

  @override
  StepCopyWith<$R2, Step, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _StepCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

