// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'config.dart';

/// @nodoc

class BudgetScopeMapper extends EnumMapper<BudgetScope> {
  BudgetScopeMapper._();

  static BudgetScopeMapper? _instance;
  static BudgetScopeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = BudgetScopeMapper._());
    }
    return _instance!;
  }

  static BudgetScope fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  BudgetScope decode(dynamic value) {
    switch (value) {
      case 'LIFETIME':
        return BudgetScope.lifetime;
      case 'FORWARD_LOOKING':
        return BudgetScope.forwardLooking;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(BudgetScope self) {
    switch (self) {
      case BudgetScope.lifetime:
        return 'LIFETIME';
      case BudgetScope.forwardLooking:
        return 'FORWARD_LOOKING';
    }
  }
}

/// @nodoc

extension BudgetScopeMapperExtension on BudgetScope {
  dynamic toValue() {
    BudgetScopeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<BudgetScope>(this);
  }
}

/// @nodoc

class StopReasonMapper extends EnumMapper<StopReason> {
  StopReasonMapper._();

  static StopReasonMapper? _instance;
  static StopReasonMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = StopReasonMapper._());
    }
    return _instance!;
  }

  static StopReason fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  StopReason decode(dynamic value) {
    switch (value) {
      case 'UNSPECIFIED':
        return StopReason.unspecified;
      case 'MAX_MODEL_CALLS_EXCEEDED':
        return StopReason.maxModelCallsExceeded;
      case 'MAX_TOOL_CALLS_EXCEEDED':
        return StopReason.maxToolCallsExceeded;
      case 'MAX_INPUT_TOKENS_EXCEEDED':
        return StopReason.maxInputTokensExceeded;
      case 'MAX_OUTPUT_TOKENS_EXCEEDED':
        return StopReason.maxOutputTokensExceeded;
      case 'MAX_TOTAL_TOKENS_EXCEEDED':
        return StopReason.maxTotalTokensExceeded;
      case 'QUOTA_EXHAUSTED':
        return StopReason.quotaExhausted;
      default:
        return StopReason.values[0];
    }
  }

  @override
  dynamic encode(StopReason self) {
    switch (self) {
      case StopReason.unspecified:
        return 'UNSPECIFIED';
      case StopReason.maxModelCallsExceeded:
        return 'MAX_MODEL_CALLS_EXCEEDED';
      case StopReason.maxToolCallsExceeded:
        return 'MAX_TOOL_CALLS_EXCEEDED';
      case StopReason.maxInputTokensExceeded:
        return 'MAX_INPUT_TOKENS_EXCEEDED';
      case StopReason.maxOutputTokensExceeded:
        return 'MAX_OUTPUT_TOKENS_EXCEEDED';
      case StopReason.maxTotalTokensExceeded:
        return 'MAX_TOTAL_TOKENS_EXCEEDED';
      case StopReason.quotaExhausted:
        return 'QUOTA_EXHAUSTED';
    }
  }
}

/// @nodoc

extension StopReasonMapperExtension on StopReason {
  dynamic toValue() {
    StopReasonMapper.ensureInitialized();
    return MapperContainer.globals.toValue<StopReason>(this);
  }
}

/// @nodoc

class SessionContinuationModeMapper
    extends EnumMapper<SessionContinuationMode> {
  SessionContinuationModeMapper._();

  static SessionContinuationModeMapper? _instance;
  static SessionContinuationModeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = SessionContinuationModeMapper._(),
      );
    }
    return _instance!;
  }

  static SessionContinuationMode fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  SessionContinuationMode decode(dynamic value) {
    switch (value) {
      case 'RESUME':
        return SessionContinuationMode.resume;
      case 'CREATE_OR_RESUME':
        return SessionContinuationMode.createOrResume;
      case 'CREATE_ONLY':
        return SessionContinuationMode.createOnly;
      case 'SESSION_CONTINUATION_MODE_UNSPECIFIED':
        return SessionContinuationMode.unspecified;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(SessionContinuationMode self) {
    switch (self) {
      case SessionContinuationMode.resume:
        return 'RESUME';
      case SessionContinuationMode.createOrResume:
        return 'CREATE_OR_RESUME';
      case SessionContinuationMode.createOnly:
        return 'CREATE_ONLY';
      case SessionContinuationMode.unspecified:
        return 'SESSION_CONTINUATION_MODE_UNSPECIFIED';
    }
  }
}

/// @nodoc

extension SessionContinuationModeMapperExtension on SessionContinuationMode {
  dynamic toValue() {
    SessionContinuationModeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<SessionContinuationMode>(this);
  }
}

/// @nodoc
class SubagentCapabilitiesMapper extends ClassMapperBase<SubagentCapabilities> {
  SubagentCapabilitiesMapper._();

  static SubagentCapabilitiesMapper? _instance;
  static SubagentCapabilitiesMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SubagentCapabilitiesMapper._());
      AgentBehaviorMapper.ensureInitialized();
      BuiltinToolsMapper.ensureInitialized();
      RunCommandConfigMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SubagentCapabilities';

  static AgentBehavior _$agentBehavior(SubagentCapabilities v) =>
      v.agentBehavior;
  static const Field<SubagentCapabilities, AgentBehavior> _f$agentBehavior =
      Field(
    'agentBehavior',
    _$agentBehavior,
    key: r'agent_behavior',
    opt: true,
  );
  static AgentBehavior _$agentMode(SubagentCapabilities v) => v.agentMode;
  static const Field<SubagentCapabilities, AgentBehavior> _f$agentMode = Field(
    'agentMode',
    _$agentMode,
    key: r'agent_mode',
    opt: true,
  );
  static List<BuiltinTools>? _$enabledTools(SubagentCapabilities v) =>
      v.enabledTools;
  static const Field<SubagentCapabilities, List<BuiltinTools>> _f$enabledTools =
      Field('enabledTools', _$enabledTools, key: r'enabled_tools', opt: true);
  static List<BuiltinTools>? _$disabledTools(SubagentCapabilities v) =>
      v.disabledTools;
  static const Field<SubagentCapabilities, List<BuiltinTools>>
      _f$disabledTools = Field(
    'disabledTools',
    _$disabledTools,
    key: r'disabled_tools',
    opt: true,
  );
  static List<String>? _$allowedSubagents(SubagentCapabilities v) =>
      v.allowedSubagents;
  static const Field<SubagentCapabilities, List<String>> _f$allowedSubagents =
      Field(
    'allowedSubagents',
    _$allowedSubagents,
    key: r'allowed_subagents',
    opt: true,
  );
  static RunCommandConfig? _$runCommandConfig(SubagentCapabilities v) =>
      v.runCommandConfig;
  static const Field<SubagentCapabilities, RunCommandConfig>
      _f$runCommandConfig = Field(
    'runCommandConfig',
    _$runCommandConfig,
    key: r'run_command_config',
    opt: true,
  );

  @override
  final MappableFields<SubagentCapabilities> fields = const {
    #agentBehavior: _f$agentBehavior,
    #agentMode: _f$agentMode,
    #enabledTools: _f$enabledTools,
    #disabledTools: _f$disabledTools,
    #allowedSubagents: _f$allowedSubagents,
    #runCommandConfig: _f$runCommandConfig,
  };
  @override
  final bool ignoreNull = true;

  static SubagentCapabilities _instantiate(DecodingData data) {
    return SubagentCapabilities(
      agentBehavior: data.dec(_f$agentBehavior),
      agentMode: data.dec(_f$agentMode),
      enabledTools: data.dec(_f$enabledTools),
      disabledTools: data.dec(_f$disabledTools),
      allowedSubagents: data.dec(_f$allowedSubagents),
      runCommandConfig: data.dec(_f$runCommandConfig),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SubagentCapabilities fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SubagentCapabilities>(map);
  }

  static SubagentCapabilities fromJson(String json) {
    return ensureInitialized().decodeJson<SubagentCapabilities>(json);
  }
}

/// @nodoc
mixin SubagentCapabilitiesMappable {
  String toJson() {
    return SubagentCapabilitiesMapper.ensureInitialized()
        .encodeJson<SubagentCapabilities>(this as SubagentCapabilities);
  }

  Map<String, dynamic> toMap() {
    return SubagentCapabilitiesMapper.ensureInitialized()
        .encodeMap<SubagentCapabilities>(this as SubagentCapabilities);
  }

  SubagentCapabilitiesCopyWith<SubagentCapabilities, SubagentCapabilities,
      SubagentCapabilities> get copyWith => _SubagentCapabilitiesCopyWithImpl<
          SubagentCapabilities, SubagentCapabilities>(
      this as SubagentCapabilities, $identity, $identity);
  @override
  String toString() {
    return SubagentCapabilitiesMapper.ensureInitialized().stringifyValue(
      this as SubagentCapabilities,
    );
  }

  @override
  bool operator ==(Object other) {
    return SubagentCapabilitiesMapper.ensureInitialized().equalsValue(
      this as SubagentCapabilities,
      other,
    );
  }

  @override
  int get hashCode {
    return SubagentCapabilitiesMapper.ensureInitialized().hashValue(
      this as SubagentCapabilities,
    );
  }
}

/// @nodoc
extension SubagentCapabilitiesValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SubagentCapabilities, $Out> {
  SubagentCapabilitiesCopyWith<$R, SubagentCapabilities, $Out>
      get $asSubagentCapabilities => $base.as(
            (v, t, t2) => _SubagentCapabilitiesCopyWithImpl<$R, $Out>(v, t, t2),
          );
}

/// @nodoc
abstract class SubagentCapabilitiesCopyWith<
    $R,
    $In extends SubagentCapabilities,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, BuiltinTools,
      ObjectCopyWith<$R, BuiltinTools, BuiltinTools>>? get enabledTools;
  ListCopyWith<$R, BuiltinTools,
      ObjectCopyWith<$R, BuiltinTools, BuiltinTools>>? get disabledTools;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
      get allowedSubagents;
  RunCommandConfigCopyWith<$R, RunCommandConfig, RunCommandConfig>?
      get runCommandConfig;
  $R call({
    AgentBehavior? agentBehavior,
    AgentBehavior? agentMode,
    List<BuiltinTools>? enabledTools,
    List<BuiltinTools>? disabledTools,
    List<String>? allowedSubagents,
    RunCommandConfig? runCommandConfig,
  });
  SubagentCapabilitiesCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

/// @nodoc
class _SubagentCapabilitiesCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SubagentCapabilities, $Out>
    implements SubagentCapabilitiesCopyWith<$R, SubagentCapabilities, $Out> {
  _SubagentCapabilitiesCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SubagentCapabilities> $mapper =
      SubagentCapabilitiesMapper.ensureInitialized();
  @override
  ListCopyWith<$R, BuiltinTools,
          ObjectCopyWith<$R, BuiltinTools, BuiltinTools>>?
      get enabledTools => $value.enabledTools != null
          ? ListCopyWith(
              $value.enabledTools!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(enabledTools: v),
            )
          : null;
  @override
  ListCopyWith<$R, BuiltinTools,
          ObjectCopyWith<$R, BuiltinTools, BuiltinTools>>?
      get disabledTools => $value.disabledTools != null
          ? ListCopyWith(
              $value.disabledTools!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(disabledTools: v),
            )
          : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
      get allowedSubagents => $value.allowedSubagents != null
          ? ListCopyWith(
              $value.allowedSubagents!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(allowedSubagents: v),
            )
          : null;
  @override
  RunCommandConfigCopyWith<$R, RunCommandConfig, RunCommandConfig>?
      get runCommandConfig => $value.runCommandConfig?.copyWith.$chain(
            (v) => call(runCommandConfig: v),
          );
  @override
  $R call({
    Object? agentBehavior = $none,
    Object? agentMode = $none,
    Object? enabledTools = $none,
    Object? disabledTools = $none,
    Object? allowedSubagents = $none,
    Object? runCommandConfig = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (agentBehavior != $none) #agentBehavior: agentBehavior,
          if (agentMode != $none) #agentMode: agentMode,
          if (enabledTools != $none) #enabledTools: enabledTools,
          if (disabledTools != $none) #disabledTools: disabledTools,
          if (allowedSubagents != $none) #allowedSubagents: allowedSubagents,
          if (runCommandConfig != $none) #runCommandConfig: runCommandConfig,
        }),
      );
  @override
  SubagentCapabilities $make(CopyWithData data) => SubagentCapabilities(
        agentBehavior: data.get(#agentBehavior, or: $value.agentBehavior),
        agentMode: data.get(#agentMode, or: $value.agentMode),
        enabledTools: data.get(#enabledTools, or: $value.enabledTools),
        disabledTools: data.get(#disabledTools, or: $value.disabledTools),
        allowedSubagents:
            data.get(#allowedSubagents, or: $value.allowedSubagents),
        runCommandConfig:
            data.get(#runCommandConfig, or: $value.runCommandConfig),
      );

  @override
  SubagentCapabilitiesCopyWith<$R2, SubagentCapabilities, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _SubagentCapabilitiesCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

/// @nodoc
class BudgetConfigMapper extends ClassMapperBase<BudgetConfig> {
  BudgetConfigMapper._();

  static BudgetConfigMapper? _instance;
  static BudgetConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = BudgetConfigMapper._());
      BudgetScopeMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'BudgetConfig';

  static BudgetScope _$scope(BudgetConfig v) => v.scope;
  static const Field<BudgetConfig, BudgetScope> _f$scope = Field(
    'scope',
    _$scope,
    opt: true,
    def: BudgetScope.lifetime,
  );
  static int? _$maxModelCalls(BudgetConfig v) => v.maxModelCalls;
  static const Field<BudgetConfig, int> _f$maxModelCalls = Field(
    'maxModelCalls',
    _$maxModelCalls,
    key: r'max_model_calls',
    opt: true,
  );
  static int? _$maxToolCalls(BudgetConfig v) => v.maxToolCalls;
  static const Field<BudgetConfig, int> _f$maxToolCalls = Field(
    'maxToolCalls',
    _$maxToolCalls,
    key: r'max_tool_calls',
    opt: true,
  );
  static int? _$maxInputTokens(BudgetConfig v) => v.maxInputTokens;
  static const Field<BudgetConfig, int> _f$maxInputTokens = Field(
    'maxInputTokens',
    _$maxInputTokens,
    key: r'max_input_tokens',
    opt: true,
  );
  static int? _$maxOutputTokens(BudgetConfig v) => v.maxOutputTokens;
  static const Field<BudgetConfig, int> _f$maxOutputTokens = Field(
    'maxOutputTokens',
    _$maxOutputTokens,
    key: r'max_output_tokens',
    opt: true,
  );
  static int? _$maxTotalTokens(BudgetConfig v) => v.maxTotalTokens;
  static const Field<BudgetConfig, int> _f$maxTotalTokens = Field(
    'maxTotalTokens',
    _$maxTotalTokens,
    key: r'max_total_tokens',
    opt: true,
  );

  @override
  final MappableFields<BudgetConfig> fields = const {
    #scope: _f$scope,
    #maxModelCalls: _f$maxModelCalls,
    #maxToolCalls: _f$maxToolCalls,
    #maxInputTokens: _f$maxInputTokens,
    #maxOutputTokens: _f$maxOutputTokens,
    #maxTotalTokens: _f$maxTotalTokens,
  };
  @override
  final bool ignoreNull = true;

  static BudgetConfig _instantiate(DecodingData data) {
    return BudgetConfig(
      scope: data.dec(_f$scope),
      maxModelCalls: data.dec(_f$maxModelCalls),
      maxToolCalls: data.dec(_f$maxToolCalls),
      maxInputTokens: data.dec(_f$maxInputTokens),
      maxOutputTokens: data.dec(_f$maxOutputTokens),
      maxTotalTokens: data.dec(_f$maxTotalTokens),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static BudgetConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<BudgetConfig>(map);
  }

  static BudgetConfig fromJson(String json) {
    return ensureInitialized().decodeJson<BudgetConfig>(json);
  }
}

/// @nodoc
mixin BudgetConfigMappable {
  String toJson() {
    return BudgetConfigMapper.ensureInitialized().encodeJson<BudgetConfig>(
      this as BudgetConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return BudgetConfigMapper.ensureInitialized().encodeMap<BudgetConfig>(
      this as BudgetConfig,
    );
  }

  BudgetConfigCopyWith<BudgetConfig, BudgetConfig, BudgetConfig> get copyWith =>
      _BudgetConfigCopyWithImpl<BudgetConfig, BudgetConfig>(
        this as BudgetConfig,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return BudgetConfigMapper.ensureInitialized().stringifyValue(
      this as BudgetConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return BudgetConfigMapper.ensureInitialized().equalsValue(
      this as BudgetConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return BudgetConfigMapper.ensureInitialized().hashValue(
      this as BudgetConfig,
    );
  }
}

/// @nodoc
extension BudgetConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, BudgetConfig, $Out> {
  BudgetConfigCopyWith<$R, BudgetConfig, $Out> get $asBudgetConfig =>
      $base.as((v, t, t2) => _BudgetConfigCopyWithImpl<$R, $Out>(v, t, t2));
}

/// @nodoc
abstract class BudgetConfigCopyWith<$R, $In extends BudgetConfig, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    BudgetScope? scope,
    int? maxModelCalls,
    int? maxToolCalls,
    int? maxInputTokens,
    int? maxOutputTokens,
    int? maxTotalTokens,
  });
  BudgetConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

/// @nodoc
class _BudgetConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, BudgetConfig, $Out>
    implements BudgetConfigCopyWith<$R, BudgetConfig, $Out> {
  _BudgetConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<BudgetConfig> $mapper =
      BudgetConfigMapper.ensureInitialized();
  @override
  $R call({
    BudgetScope? scope,
    Object? maxModelCalls = $none,
    Object? maxToolCalls = $none,
    Object? maxInputTokens = $none,
    Object? maxOutputTokens = $none,
    Object? maxTotalTokens = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (scope != null) #scope: scope,
          if (maxModelCalls != $none) #maxModelCalls: maxModelCalls,
          if (maxToolCalls != $none) #maxToolCalls: maxToolCalls,
          if (maxInputTokens != $none) #maxInputTokens: maxInputTokens,
          if (maxOutputTokens != $none) #maxOutputTokens: maxOutputTokens,
          if (maxTotalTokens != $none) #maxTotalTokens: maxTotalTokens,
        }),
      );
  @override
  BudgetConfig $make(CopyWithData data) => BudgetConfig(
        scope: data.get(#scope, or: $value.scope),
        maxModelCalls: data.get(#maxModelCalls, or: $value.maxModelCalls),
        maxToolCalls: data.get(#maxToolCalls, or: $value.maxToolCalls),
        maxInputTokens: data.get(#maxInputTokens, or: $value.maxInputTokens),
        maxOutputTokens: data.get(#maxOutputTokens, or: $value.maxOutputTokens),
        maxTotalTokens: data.get(#maxTotalTokens, or: $value.maxTotalTokens),
      );

  @override
  BudgetConfigCopyWith<$R2, BudgetConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _BudgetConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

/// @nodoc
class InlineSkillMapper extends ClassMapperBase<InlineSkill> {
  InlineSkillMapper._();

  static InlineSkillMapper? _instance;
  static InlineSkillMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = InlineSkillMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'InlineSkill';

  static String _$name(InlineSkill v) => v.name;
  static const Field<InlineSkill, String> _f$name = Field('name', _$name);
  static String _$description(InlineSkill v) => v.description;
  static const Field<InlineSkill, String> _f$description = Field(
    'description',
    _$description,
  );
  static String _$content(InlineSkill v) => v.content;
  static const Field<InlineSkill, String> _f$content = Field(
    'content',
    _$content,
  );
  static List<String> _$allowedTools(InlineSkill v) => v.allowedTools;
  static const Field<InlineSkill, List<String>> _f$allowedTools = Field(
    'allowedTools',
    _$allowedTools,
    key: r'allowed_tools',
    opt: true,
    def: const [],
  );
  static List<String> _$dependentTools(InlineSkill v) => v.dependentTools;
  static const Field<InlineSkill, List<String>> _f$dependentTools = Field(
    'dependentTools',
    _$dependentTools,
    key: r'dependent_tools',
    opt: true,
    def: const [],
  );
  static List<String> _$dependentSkills(InlineSkill v) => v.dependentSkills;
  static const Field<InlineSkill, List<String>> _f$dependentSkills = Field(
    'dependentSkills',
    _$dependentSkills,
    key: r'dependent_skills',
    opt: true,
    def: const [],
  );
  static Map<String, String> _$metadata(InlineSkill v) => v.metadata;
  static const Field<InlineSkill, Map<String, String>> _f$metadata = Field(
    'metadata',
    _$metadata,
    opt: true,
    def: const {},
  );

  @override
  final MappableFields<InlineSkill> fields = const {
    #name: _f$name,
    #description: _f$description,
    #content: _f$content,
    #allowedTools: _f$allowedTools,
    #dependentTools: _f$dependentTools,
    #dependentSkills: _f$dependentSkills,
    #metadata: _f$metadata,
  };
  @override
  final bool ignoreNull = true;

  static InlineSkill _instantiate(DecodingData data) {
    return InlineSkill(
      name: data.dec(_f$name),
      description: data.dec(_f$description),
      content: data.dec(_f$content),
      allowedTools: data.dec(_f$allowedTools),
      dependentTools: data.dec(_f$dependentTools),
      dependentSkills: data.dec(_f$dependentSkills),
      metadata: data.dec(_f$metadata),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static InlineSkill fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<InlineSkill>(map);
  }

  static InlineSkill fromJson(String json) {
    return ensureInitialized().decodeJson<InlineSkill>(json);
  }
}

/// @nodoc
mixin InlineSkillMappable {
  String toJson() {
    return InlineSkillMapper.ensureInitialized().encodeJson<InlineSkill>(
      this as InlineSkill,
    );
  }

  Map<String, dynamic> toMap() {
    return InlineSkillMapper.ensureInitialized().encodeMap<InlineSkill>(
      this as InlineSkill,
    );
  }

  InlineSkillCopyWith<InlineSkill, InlineSkill, InlineSkill> get copyWith =>
      _InlineSkillCopyWithImpl<InlineSkill, InlineSkill>(
        this as InlineSkill,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return InlineSkillMapper.ensureInitialized().stringifyValue(
      this as InlineSkill,
    );
  }

  @override
  bool operator ==(Object other) {
    return InlineSkillMapper.ensureInitialized().equalsValue(
      this as InlineSkill,
      other,
    );
  }

  @override
  int get hashCode {
    return InlineSkillMapper.ensureInitialized().hashValue(this as InlineSkill);
  }
}

/// @nodoc
extension InlineSkillValueCopy<$R, $Out>
    on ObjectCopyWith<$R, InlineSkill, $Out> {
  InlineSkillCopyWith<$R, InlineSkill, $Out> get $asInlineSkill =>
      $base.as((v, t, t2) => _InlineSkillCopyWithImpl<$R, $Out>(v, t, t2));
}

/// @nodoc
abstract class InlineSkillCopyWith<$R, $In extends InlineSkill, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get allowedTools;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get dependentTools;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get dependentSkills;
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>
      get metadata;
  $R call({
    String? name,
    String? description,
    String? content,
    List<String>? allowedTools,
    List<String>? dependentTools,
    List<String>? dependentSkills,
    Map<String, String>? metadata,
  });
  InlineSkillCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

/// @nodoc
class _InlineSkillCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, InlineSkill, $Out>
    implements InlineSkillCopyWith<$R, InlineSkill, $Out> {
  _InlineSkillCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<InlineSkill> $mapper =
      InlineSkillMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get allowedTools => ListCopyWith(
            $value.allowedTools,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(allowedTools: v),
          );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get dependentTools => ListCopyWith(
            $value.dependentTools,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(dependentTools: v),
          );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get dependentSkills => ListCopyWith(
            $value.dependentSkills,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(dependentSkills: v),
          );
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>
      get metadata => MapCopyWith(
            $value.metadata,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(metadata: v),
          );
  @override
  $R call({
    String? name,
    String? description,
    String? content,
    List<String>? allowedTools,
    List<String>? dependentTools,
    List<String>? dependentSkills,
    Map<String, String>? metadata,
  }) =>
      $apply(
        FieldCopyWithData({
          if (name != null) #name: name,
          if (description != null) #description: description,
          if (content != null) #content: content,
          if (allowedTools != null) #allowedTools: allowedTools,
          if (dependentTools != null) #dependentTools: dependentTools,
          if (dependentSkills != null) #dependentSkills: dependentSkills,
          if (metadata != null) #metadata: metadata,
        }),
      );
  @override
  InlineSkill $make(CopyWithData data) => InlineSkill(
        name: data.get(#name, or: $value.name),
        description: data.get(#description, or: $value.description),
        content: data.get(#content, or: $value.content),
        allowedTools: data.get(#allowedTools, or: $value.allowedTools),
        dependentTools: data.get(#dependentTools, or: $value.dependentTools),
        dependentSkills: data.get(#dependentSkills, or: $value.dependentSkills),
        metadata: data.get(#metadata, or: $value.metadata),
      );

  @override
  InlineSkillCopyWith<$R2, InlineSkill, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _InlineSkillCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

/// @nodoc
class SubagentSkillsConfigMapper extends ClassMapperBase<SubagentSkillsConfig> {
  SubagentSkillsConfigMapper._();

  static SubagentSkillsConfigMapper? _instance;
  static SubagentSkillsConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SubagentSkillsConfigMapper._());
      SubagentInheritSkillsConfigMapper.ensureInitialized();
      SubagentNoneSkillsConfigMapper.ensureInitialized();
      SubagentOverrideSkillsConfigMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SubagentSkillsConfig';

  static SubagentInheritSkillsConfig? _$inheritConfig(SubagentSkillsConfig v) =>
      v.inheritConfig;
  static const Field<SubagentSkillsConfig, SubagentInheritSkillsConfig>
      _f$inheritConfig = Field(
    'inheritConfig',
    _$inheritConfig,
    key: r'inherit_config',
    opt: true,
  );
  static SubagentNoneSkillsConfig? _$noneConfig(SubagentSkillsConfig v) =>
      v.noneConfig;
  static const Field<SubagentSkillsConfig, SubagentNoneSkillsConfig>
      _f$noneConfig = Field(
    'noneConfig',
    _$noneConfig,
    key: r'none_config',
    opt: true,
  );
  static SubagentOverrideSkillsConfig? _$overrideConfig(
    SubagentSkillsConfig v,
  ) =>
      v.overrideConfig;
  static const Field<SubagentSkillsConfig, SubagentOverrideSkillsConfig>
      _f$overrideConfig = Field(
    'overrideConfig',
    _$overrideConfig,
    key: r'override_config',
    opt: true,
  );

  @override
  final MappableFields<SubagentSkillsConfig> fields = const {
    #inheritConfig: _f$inheritConfig,
    #noneConfig: _f$noneConfig,
    #overrideConfig: _f$overrideConfig,
  };
  @override
  final bool ignoreNull = true;

  static SubagentSkillsConfig _instantiate(DecodingData data) {
    return SubagentSkillsConfig(
      inheritConfig: data.dec(_f$inheritConfig),
      noneConfig: data.dec(_f$noneConfig),
      overrideConfig: data.dec(_f$overrideConfig),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SubagentSkillsConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SubagentSkillsConfig>(map);
  }

  static SubagentSkillsConfig fromJson(String json) {
    return ensureInitialized().decodeJson<SubagentSkillsConfig>(json);
  }
}

/// @nodoc
mixin SubagentSkillsConfigMappable {
  String toJson() {
    return SubagentSkillsConfigMapper.ensureInitialized()
        .encodeJson<SubagentSkillsConfig>(this as SubagentSkillsConfig);
  }

  Map<String, dynamic> toMap() {
    return SubagentSkillsConfigMapper.ensureInitialized()
        .encodeMap<SubagentSkillsConfig>(this as SubagentSkillsConfig);
  }

  SubagentSkillsConfigCopyWith<SubagentSkillsConfig, SubagentSkillsConfig,
      SubagentSkillsConfig> get copyWith => _SubagentSkillsConfigCopyWithImpl<
          SubagentSkillsConfig, SubagentSkillsConfig>(
      this as SubagentSkillsConfig, $identity, $identity);
  @override
  String toString() {
    return SubagentSkillsConfigMapper.ensureInitialized().stringifyValue(
      this as SubagentSkillsConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return SubagentSkillsConfigMapper.ensureInitialized().equalsValue(
      this as SubagentSkillsConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return SubagentSkillsConfigMapper.ensureInitialized().hashValue(
      this as SubagentSkillsConfig,
    );
  }
}

/// @nodoc
extension SubagentSkillsConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SubagentSkillsConfig, $Out> {
  SubagentSkillsConfigCopyWith<$R, SubagentSkillsConfig, $Out>
      get $asSubagentSkillsConfig => $base.as(
            (v, t, t2) => _SubagentSkillsConfigCopyWithImpl<$R, $Out>(v, t, t2),
          );
}

/// @nodoc
abstract class SubagentSkillsConfigCopyWith<
    $R,
    $In extends SubagentSkillsConfig,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  SubagentInheritSkillsConfigCopyWith<$R, SubagentInheritSkillsConfig,
      SubagentInheritSkillsConfig>? get inheritConfig;
  SubagentNoneSkillsConfigCopyWith<$R, SubagentNoneSkillsConfig,
      SubagentNoneSkillsConfig>? get noneConfig;
  SubagentOverrideSkillsConfigCopyWith<$R, SubagentOverrideSkillsConfig,
      SubagentOverrideSkillsConfig>? get overrideConfig;
  $R call({
    SubagentInheritSkillsConfig? inheritConfig,
    SubagentNoneSkillsConfig? noneConfig,
    SubagentOverrideSkillsConfig? overrideConfig,
  });
  SubagentSkillsConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

/// @nodoc
class _SubagentSkillsConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SubagentSkillsConfig, $Out>
    implements SubagentSkillsConfigCopyWith<$R, SubagentSkillsConfig, $Out> {
  _SubagentSkillsConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SubagentSkillsConfig> $mapper =
      SubagentSkillsConfigMapper.ensureInitialized();
  @override
  SubagentInheritSkillsConfigCopyWith<$R, SubagentInheritSkillsConfig,
          SubagentInheritSkillsConfig>?
      get inheritConfig =>
          $value.inheritConfig?.copyWith.$chain((v) => call(inheritConfig: v));
  @override
  SubagentNoneSkillsConfigCopyWith<$R, SubagentNoneSkillsConfig,
          SubagentNoneSkillsConfig>?
      get noneConfig =>
          $value.noneConfig?.copyWith.$chain((v) => call(noneConfig: v));
  @override
  SubagentOverrideSkillsConfigCopyWith<$R, SubagentOverrideSkillsConfig,
          SubagentOverrideSkillsConfig>?
      get overrideConfig => $value.overrideConfig?.copyWith
          .$chain((v) => call(overrideConfig: v));
  @override
  $R call({
    Object? inheritConfig = $none,
    Object? noneConfig = $none,
    Object? overrideConfig = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (inheritConfig != $none) #inheritConfig: inheritConfig,
          if (noneConfig != $none) #noneConfig: noneConfig,
          if (overrideConfig != $none) #overrideConfig: overrideConfig,
        }),
      );
  @override
  SubagentSkillsConfig $make(CopyWithData data) => SubagentSkillsConfig(
        inheritConfig: data.get(#inheritConfig, or: $value.inheritConfig),
        noneConfig: data.get(#noneConfig, or: $value.noneConfig),
        overrideConfig: data.get(#overrideConfig, or: $value.overrideConfig),
      );

  @override
  SubagentSkillsConfigCopyWith<$R2, SubagentSkillsConfig, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _SubagentSkillsConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

/// @nodoc
class SubagentInheritSkillsConfigMapper
    extends ClassMapperBase<SubagentInheritSkillsConfig> {
  SubagentInheritSkillsConfigMapper._();

  static SubagentInheritSkillsConfigMapper? _instance;
  static SubagentInheritSkillsConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = SubagentInheritSkillsConfigMapper._(),
      );
    }
    return _instance!;
  }

  @override
  final String id = 'SubagentInheritSkillsConfig';

  static List<String> _$skillNames(SubagentInheritSkillsConfig v) =>
      v.skillNames;
  static const Field<SubagentInheritSkillsConfig, List<String>> _f$skillNames =
      Field(
    'skillNames',
    _$skillNames,
    key: r'skill_names',
    opt: true,
    def: const [],
  );
  static List<String> _$extraSkillsPaths(SubagentInheritSkillsConfig v) =>
      v.extraSkillsPaths;
  static const Field<SubagentInheritSkillsConfig, List<String>>
      _f$extraSkillsPaths = Field(
    'extraSkillsPaths',
    _$extraSkillsPaths,
    key: r'extra_skills_paths',
    opt: true,
    def: const [],
  );

  @override
  final MappableFields<SubagentInheritSkillsConfig> fields = const {
    #skillNames: _f$skillNames,
    #extraSkillsPaths: _f$extraSkillsPaths,
  };
  @override
  final bool ignoreNull = true;

  static SubagentInheritSkillsConfig _instantiate(DecodingData data) {
    return SubagentInheritSkillsConfig(
      skillNames: data.dec(_f$skillNames),
      extraSkillsPaths: data.dec(_f$extraSkillsPaths),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SubagentInheritSkillsConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SubagentInheritSkillsConfig>(map);
  }

  static SubagentInheritSkillsConfig fromJson(String json) {
    return ensureInitialized().decodeJson<SubagentInheritSkillsConfig>(json);
  }
}

/// @nodoc
mixin SubagentInheritSkillsConfigMappable {
  String toJson() {
    return SubagentInheritSkillsConfigMapper.ensureInitialized()
        .encodeJson<SubagentInheritSkillsConfig>(
      this as SubagentInheritSkillsConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return SubagentInheritSkillsConfigMapper.ensureInitialized()
        .encodeMap<SubagentInheritSkillsConfig>(
      this as SubagentInheritSkillsConfig,
    );
  }

  SubagentInheritSkillsConfigCopyWith<SubagentInheritSkillsConfig,
          SubagentInheritSkillsConfig, SubagentInheritSkillsConfig>
      get copyWith => _SubagentInheritSkillsConfigCopyWithImpl<
              SubagentInheritSkillsConfig, SubagentInheritSkillsConfig>(
          this as SubagentInheritSkillsConfig, $identity, $identity);
  @override
  String toString() {
    return SubagentInheritSkillsConfigMapper.ensureInitialized().stringifyValue(
      this as SubagentInheritSkillsConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return SubagentInheritSkillsConfigMapper.ensureInitialized().equalsValue(
      this as SubagentInheritSkillsConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return SubagentInheritSkillsConfigMapper.ensureInitialized().hashValue(
      this as SubagentInheritSkillsConfig,
    );
  }
}

/// @nodoc
extension SubagentInheritSkillsConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SubagentInheritSkillsConfig, $Out> {
  SubagentInheritSkillsConfigCopyWith<$R, SubagentInheritSkillsConfig, $Out>
      get $asSubagentInheritSkillsConfig => $base.as(
            (v, t, t2) =>
                _SubagentInheritSkillsConfigCopyWithImpl<$R, $Out>(v, t, t2),
          );
}

/// @nodoc
abstract class SubagentInheritSkillsConfigCopyWith<
    $R,
    $In extends SubagentInheritSkillsConfig,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get skillNames;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get extraSkillsPaths;
  $R call({List<String>? skillNames, List<String>? extraSkillsPaths});
  SubagentInheritSkillsConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

/// @nodoc
class _SubagentInheritSkillsConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SubagentInheritSkillsConfig, $Out>
    implements
        SubagentInheritSkillsConfigCopyWith<$R, SubagentInheritSkillsConfig,
            $Out> {
  _SubagentInheritSkillsConfigCopyWithImpl(
    super.value,
    super.then,
    super.then2,
  );

  @override
  late final ClassMapperBase<SubagentInheritSkillsConfig> $mapper =
      SubagentInheritSkillsConfigMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get skillNames =>
      ListCopyWith(
        $value.skillNames,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(skillNames: v),
      );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get extraSkillsPaths => ListCopyWith(
            $value.extraSkillsPaths,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(extraSkillsPaths: v),
          );
  @override
  $R call({List<String>? skillNames, List<String>? extraSkillsPaths}) => $apply(
        FieldCopyWithData({
          if (skillNames != null) #skillNames: skillNames,
          if (extraSkillsPaths != null) #extraSkillsPaths: extraSkillsPaths,
        }),
      );
  @override
  SubagentInheritSkillsConfig $make(CopyWithData data) =>
      SubagentInheritSkillsConfig(
        skillNames: data.get(#skillNames, or: $value.skillNames),
        extraSkillsPaths: data.get(
          #extraSkillsPaths,
          or: $value.extraSkillsPaths,
        ),
      );

  @override
  SubagentInheritSkillsConfigCopyWith<$R2, SubagentInheritSkillsConfig, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _SubagentInheritSkillsConfigCopyWithImpl<$R2, $Out2>(
              $value, $cast, t);
}

/// @nodoc
class SubagentNoneSkillsConfigMapper
    extends ClassMapperBase<SubagentNoneSkillsConfig> {
  SubagentNoneSkillsConfigMapper._();

  static SubagentNoneSkillsConfigMapper? _instance;
  static SubagentNoneSkillsConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = SubagentNoneSkillsConfigMapper._(),
      );
    }
    return _instance!;
  }

  @override
  final String id = 'SubagentNoneSkillsConfig';

  @override
  final MappableFields<SubagentNoneSkillsConfig> fields = const {};
  @override
  final bool ignoreNull = true;

  static SubagentNoneSkillsConfig _instantiate(DecodingData data) {
    return SubagentNoneSkillsConfig();
  }

  @override
  final Function instantiate = _instantiate;

  static SubagentNoneSkillsConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SubagentNoneSkillsConfig>(map);
  }

  static SubagentNoneSkillsConfig fromJson(String json) {
    return ensureInitialized().decodeJson<SubagentNoneSkillsConfig>(json);
  }
}

/// @nodoc
mixin SubagentNoneSkillsConfigMappable {
  String toJson() {
    return SubagentNoneSkillsConfigMapper.ensureInitialized()
        .encodeJson<SubagentNoneSkillsConfig>(this as SubagentNoneSkillsConfig);
  }

  Map<String, dynamic> toMap() {
    return SubagentNoneSkillsConfigMapper.ensureInitialized()
        .encodeMap<SubagentNoneSkillsConfig>(this as SubagentNoneSkillsConfig);
  }

  SubagentNoneSkillsConfigCopyWith<SubagentNoneSkillsConfig,
          SubagentNoneSkillsConfig, SubagentNoneSkillsConfig>
      get copyWith => _SubagentNoneSkillsConfigCopyWithImpl<
              SubagentNoneSkillsConfig, SubagentNoneSkillsConfig>(
          this as SubagentNoneSkillsConfig, $identity, $identity);
  @override
  String toString() {
    return SubagentNoneSkillsConfigMapper.ensureInitialized().stringifyValue(
      this as SubagentNoneSkillsConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return SubagentNoneSkillsConfigMapper.ensureInitialized().equalsValue(
      this as SubagentNoneSkillsConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return SubagentNoneSkillsConfigMapper.ensureInitialized().hashValue(
      this as SubagentNoneSkillsConfig,
    );
  }
}

/// @nodoc
extension SubagentNoneSkillsConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SubagentNoneSkillsConfig, $Out> {
  SubagentNoneSkillsConfigCopyWith<$R, SubagentNoneSkillsConfig, $Out>
      get $asSubagentNoneSkillsConfig => $base.as(
            (v, t, t2) =>
                _SubagentNoneSkillsConfigCopyWithImpl<$R, $Out>(v, t, t2),
          );
}

/// @nodoc
abstract class SubagentNoneSkillsConfigCopyWith<
    $R,
    $In extends SubagentNoneSkillsConfig,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call();
  SubagentNoneSkillsConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

/// @nodoc
class _SubagentNoneSkillsConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SubagentNoneSkillsConfig, $Out>
    implements
        SubagentNoneSkillsConfigCopyWith<$R, SubagentNoneSkillsConfig, $Out> {
  _SubagentNoneSkillsConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SubagentNoneSkillsConfig> $mapper =
      SubagentNoneSkillsConfigMapper.ensureInitialized();
  @override
  $R call() => $apply(FieldCopyWithData({}));
  @override
  SubagentNoneSkillsConfig $make(CopyWithData data) =>
      SubagentNoneSkillsConfig();

  @override
  SubagentNoneSkillsConfigCopyWith<$R2, SubagentNoneSkillsConfig, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _SubagentNoneSkillsConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

/// @nodoc
class SubagentOverrideSkillsConfigMapper
    extends ClassMapperBase<SubagentOverrideSkillsConfig> {
  SubagentOverrideSkillsConfigMapper._();

  static SubagentOverrideSkillsConfigMapper? _instance;
  static SubagentOverrideSkillsConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = SubagentOverrideSkillsConfigMapper._(),
      );
      InlineSkillMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SubagentOverrideSkillsConfig';

  static List<String> _$skillsPaths(SubagentOverrideSkillsConfig v) =>
      v.skillsPaths;
  static const Field<SubagentOverrideSkillsConfig, List<String>>
      _f$skillsPaths = Field(
    'skillsPaths',
    _$skillsPaths,
    key: r'skills_paths',
    opt: true,
    def: const [],
  );
  static List<InlineSkill> _$inlineSkills(SubagentOverrideSkillsConfig v) =>
      v.inlineSkills;
  static const Field<SubagentOverrideSkillsConfig, List<InlineSkill>>
      _f$inlineSkills = Field(
    'inlineSkills',
    _$inlineSkills,
    key: r'inline_skills',
    opt: true,
    def: const [],
  );

  @override
  final MappableFields<SubagentOverrideSkillsConfig> fields = const {
    #skillsPaths: _f$skillsPaths,
    #inlineSkills: _f$inlineSkills,
  };
  @override
  final bool ignoreNull = true;

  static SubagentOverrideSkillsConfig _instantiate(DecodingData data) {
    return SubagentOverrideSkillsConfig(
      skillsPaths: data.dec(_f$skillsPaths),
      inlineSkills: data.dec(_f$inlineSkills),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SubagentOverrideSkillsConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SubagentOverrideSkillsConfig>(map);
  }

  static SubagentOverrideSkillsConfig fromJson(String json) {
    return ensureInitialized().decodeJson<SubagentOverrideSkillsConfig>(json);
  }
}

/// @nodoc
mixin SubagentOverrideSkillsConfigMappable {
  String toJson() {
    return SubagentOverrideSkillsConfigMapper.ensureInitialized()
        .encodeJson<SubagentOverrideSkillsConfig>(
      this as SubagentOverrideSkillsConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return SubagentOverrideSkillsConfigMapper.ensureInitialized()
        .encodeMap<SubagentOverrideSkillsConfig>(
      this as SubagentOverrideSkillsConfig,
    );
  }

  SubagentOverrideSkillsConfigCopyWith<SubagentOverrideSkillsConfig,
          SubagentOverrideSkillsConfig, SubagentOverrideSkillsConfig>
      get copyWith => _SubagentOverrideSkillsConfigCopyWithImpl<
              SubagentOverrideSkillsConfig, SubagentOverrideSkillsConfig>(
          this as SubagentOverrideSkillsConfig, $identity, $identity);
  @override
  String toString() {
    return SubagentOverrideSkillsConfigMapper.ensureInitialized()
        .stringifyValue(this as SubagentOverrideSkillsConfig);
  }

  @override
  bool operator ==(Object other) {
    return SubagentOverrideSkillsConfigMapper.ensureInitialized().equalsValue(
      this as SubagentOverrideSkillsConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return SubagentOverrideSkillsConfigMapper.ensureInitialized().hashValue(
      this as SubagentOverrideSkillsConfig,
    );
  }
}

/// @nodoc
extension SubagentOverrideSkillsConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SubagentOverrideSkillsConfig, $Out> {
  SubagentOverrideSkillsConfigCopyWith<$R, SubagentOverrideSkillsConfig, $Out>
      get $asSubagentOverrideSkillsConfig => $base.as(
            (v, t, t2) =>
                _SubagentOverrideSkillsConfigCopyWithImpl<$R, $Out>(v, t, t2),
          );
}

/// @nodoc
abstract class SubagentOverrideSkillsConfigCopyWith<
    $R,
    $In extends SubagentOverrideSkillsConfig,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get skillsPaths;
  ListCopyWith<$R, InlineSkill,
      InlineSkillCopyWith<$R, InlineSkill, InlineSkill>> get inlineSkills;
  $R call({List<String>? skillsPaths, List<InlineSkill>? inlineSkills});
  SubagentOverrideSkillsConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

/// @nodoc
class _SubagentOverrideSkillsConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SubagentOverrideSkillsConfig, $Out>
    implements
        SubagentOverrideSkillsConfigCopyWith<$R, SubagentOverrideSkillsConfig,
            $Out> {
  _SubagentOverrideSkillsConfigCopyWithImpl(
    super.value,
    super.then,
    super.then2,
  );

  @override
  late final ClassMapperBase<SubagentOverrideSkillsConfig> $mapper =
      SubagentOverrideSkillsConfigMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get skillsPaths => ListCopyWith(
            $value.skillsPaths,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(skillsPaths: v),
          );
  @override
  ListCopyWith<$R, InlineSkill,
          InlineSkillCopyWith<$R, InlineSkill, InlineSkill>>
      get inlineSkills => ListCopyWith(
            $value.inlineSkills,
            (v, t) => v.copyWith.$chain(t),
            (v) => call(inlineSkills: v),
          );
  @override
  $R call({List<String>? skillsPaths, List<InlineSkill>? inlineSkills}) =>
      $apply(
        FieldCopyWithData({
          if (skillsPaths != null) #skillsPaths: skillsPaths,
          if (inlineSkills != null) #inlineSkills: inlineSkills,
        }),
      );
  @override
  SubagentOverrideSkillsConfig $make(CopyWithData data) =>
      SubagentOverrideSkillsConfig(
        skillsPaths: data.get(#skillsPaths, or: $value.skillsPaths),
        inlineSkills: data.get(#inlineSkills, or: $value.inlineSkills),
      );

  @override
  SubagentOverrideSkillsConfigCopyWith<$R2, SubagentOverrideSkillsConfig, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _SubagentOverrideSkillsConfigCopyWithImpl<$R2, $Out2>(
              $value, $cast, t);
}

/// @nodoc
class SubagentConfigMapper extends ClassMapperBase<SubagentConfig> {
  SubagentConfigMapper._();

  static SubagentConfigMapper? _instance;
  static SubagentConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SubagentConfigMapper._());
      SubagentCapabilitiesMapper.ensureInitialized();
      SubagentSkillsConfigMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SubagentConfig';

  static String _$name(SubagentConfig v) => v.name;
  static const Field<SubagentConfig, String> _f$name = Field('name', _$name);
  static String _$description(SubagentConfig v) => v.description;
  static const Field<SubagentConfig, String> _f$description = Field(
    'description',
    _$description,
  );
  static dynamic _$systemInstructions(SubagentConfig v) => v.systemInstructions;
  static const Field<SubagentConfig, dynamic> _f$systemInstructions = Field(
    'systemInstructions',
    _$systemInstructions,
    key: r'system_instructions',
    opt: true,
  );
  static SubagentCapabilities? _$capabilities(SubagentConfig v) =>
      v.capabilities;
  static const Field<SubagentConfig, SubagentCapabilities> _f$capabilities =
      Field('capabilities', _$capabilities, opt: true);
  static List<Object> _$tools(SubagentConfig v) => v.tools;
  static const Field<SubagentConfig, List<Object>> _f$tools = Field(
    'tools',
    _$tools,
    opt: true,
  );
  static String? _$model(SubagentConfig v) => v.model;
  static const Field<SubagentConfig, String> _f$model = Field(
    'model',
    _$model,
    opt: true,
  );
  static SubagentSkillsConfig? _$skillsConfig(SubagentConfig v) =>
      v.skillsConfig;
  static const Field<SubagentConfig, SubagentSkillsConfig> _f$skillsConfig =
      Field('skillsConfig', _$skillsConfig, key: r'skills_config', opt: true);

  @override
  final MappableFields<SubagentConfig> fields = const {
    #name: _f$name,
    #description: _f$description,
    #systemInstructions: _f$systemInstructions,
    #capabilities: _f$capabilities,
    #tools: _f$tools,
    #model: _f$model,
    #skillsConfig: _f$skillsConfig,
  };
  @override
  final bool ignoreNull = true;

  static SubagentConfig _instantiate(DecodingData data) {
    return SubagentConfig.raw(
      name: data.dec(_f$name),
      description: data.dec(_f$description),
      systemInstructions: data.dec(_f$systemInstructions),
      capabilities: data.dec(_f$capabilities),
      tools: data.dec(_f$tools),
      model: data.dec(_f$model),
      skillsConfig: data.dec(_f$skillsConfig),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SubagentConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SubagentConfig>(map);
  }

  static SubagentConfig fromJson(String json) {
    return ensureInitialized().decodeJson<SubagentConfig>(json);
  }
}

/// @nodoc
mixin SubagentConfigMappable {
  String toJson() {
    return SubagentConfigMapper.ensureInitialized().encodeJson<SubagentConfig>(
      this as SubagentConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return SubagentConfigMapper.ensureInitialized().encodeMap<SubagentConfig>(
      this as SubagentConfig,
    );
  }

  SubagentConfigCopyWith<SubagentConfig, SubagentConfig, SubagentConfig>
      get copyWith =>
          _SubagentConfigCopyWithImpl<SubagentConfig, SubagentConfig>(
            this as SubagentConfig,
            $identity,
            $identity,
          );
  @override
  String toString() {
    return SubagentConfigMapper.ensureInitialized().stringifyValue(
      this as SubagentConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return SubagentConfigMapper.ensureInitialized().equalsValue(
      this as SubagentConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return SubagentConfigMapper.ensureInitialized().hashValue(
      this as SubagentConfig,
    );
  }
}

/// @nodoc
extension SubagentConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SubagentConfig, $Out> {
  SubagentConfigCopyWith<$R, SubagentConfig, $Out> get $asSubagentConfig =>
      $base.as((v, t, t2) => _SubagentConfigCopyWithImpl<$R, $Out>(v, t, t2));
}

/// @nodoc
abstract class SubagentConfigCopyWith<$R, $In extends SubagentConfig, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  SubagentCapabilitiesCopyWith<$R, SubagentCapabilities, SubagentCapabilities>?
      get capabilities;
  ListCopyWith<$R, Object, ObjectCopyWith<$R, Object, Object>> get tools;
  SubagentSkillsConfigCopyWith<$R, SubagentSkillsConfig, SubagentSkillsConfig>?
      get skillsConfig;
  $R call({
    String? name,
    String? description,
    dynamic systemInstructions,
    SubagentCapabilities? capabilities,
    List<Object>? tools,
    String? model,
    SubagentSkillsConfig? skillsConfig,
  });
  SubagentConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

/// @nodoc
class _SubagentConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SubagentConfig, $Out>
    implements SubagentConfigCopyWith<$R, SubagentConfig, $Out> {
  _SubagentConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SubagentConfig> $mapper =
      SubagentConfigMapper.ensureInitialized();
  @override
  SubagentCapabilitiesCopyWith<$R, SubagentCapabilities, SubagentCapabilities>?
      get capabilities =>
          $value.capabilities?.copyWith.$chain((v) => call(capabilities: v));
  @override
  ListCopyWith<$R, Object, ObjectCopyWith<$R, Object, Object>> get tools =>
      ListCopyWith(
        $value.tools,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(tools: v),
      );
  @override
  SubagentSkillsConfigCopyWith<$R, SubagentSkillsConfig, SubagentSkillsConfig>?
      get skillsConfig =>
          $value.skillsConfig?.copyWith.$chain((v) => call(skillsConfig: v));
  @override
  $R call({
    String? name,
    String? description,
    Object? systemInstructions = $none,
    Object? capabilities = $none,
    Object? tools = $none,
    Object? model = $none,
    Object? skillsConfig = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (name != null) #name: name,
          if (description != null) #description: description,
          if (systemInstructions != $none)
            #systemInstructions: systemInstructions,
          if (capabilities != $none) #capabilities: capabilities,
          if (tools != $none) #tools: tools,
          if (model != $none) #model: model,
          if (skillsConfig != $none) #skillsConfig: skillsConfig,
        }),
      );
  @override
  SubagentConfig $make(CopyWithData data) => SubagentConfig.raw(
        name: data.get(#name, or: $value.name),
        description: data.get(#description, or: $value.description),
        systemInstructions: data.get(
          #systemInstructions,
          or: $value.systemInstructions,
        ),
        capabilities: data.get(#capabilities, or: $value.capabilities),
        tools: data.get(#tools, or: $value.tools),
        model: data.get(#model, or: $value.model),
        skillsConfig: data.get(#skillsConfig, or: $value.skillsConfig),
      );

  @override
  SubagentConfigCopyWith<$R2, SubagentConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _SubagentConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

/// @nodoc
class ModelAPIRetryConfigMapper extends ClassMapperBase<ModelAPIRetryConfig> {
  ModelAPIRetryConfigMapper._();

  static ModelAPIRetryConfigMapper? _instance;
  static ModelAPIRetryConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModelAPIRetryConfigMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ModelAPIRetryConfig';

  static int? _$maxRetries(ModelAPIRetryConfig v) => v.maxRetries;
  static const Field<ModelAPIRetryConfig, int> _f$maxRetries = Field(
    'maxRetries',
    _$maxRetries,
    key: r'max_retries',
    opt: true,
  );
  static int? _$initialSleepDurationMs(ModelAPIRetryConfig v) =>
      v.initialSleepDurationMs;
  static const Field<ModelAPIRetryConfig, int> _f$initialSleepDurationMs =
      Field(
    'initialSleepDurationMs',
    _$initialSleepDurationMs,
    key: r'initial_sleep_duration_ms',
    opt: true,
  );
  static double? _$exponentialMultiplier(ModelAPIRetryConfig v) =>
      v.exponentialMultiplier;
  static const Field<ModelAPIRetryConfig, double> _f$exponentialMultiplier =
      Field(
    'exponentialMultiplier',
    _$exponentialMultiplier,
    key: r'exponential_multiplier',
    opt: true,
  );
  static double? _$jitterRange(ModelAPIRetryConfig v) => v.jitterRange;
  static const Field<ModelAPIRetryConfig, double> _f$jitterRange = Field(
    'jitterRange',
    _$jitterRange,
    key: r'jitter_range',
    opt: true,
  );

  @override
  final MappableFields<ModelAPIRetryConfig> fields = const {
    #maxRetries: _f$maxRetries,
    #initialSleepDurationMs: _f$initialSleepDurationMs,
    #exponentialMultiplier: _f$exponentialMultiplier,
    #jitterRange: _f$jitterRange,
  };
  @override
  final bool ignoreNull = true;

  static ModelAPIRetryConfig _instantiate(DecodingData data) {
    return ModelAPIRetryConfig.raw(
      maxRetries: data.dec(_f$maxRetries),
      initialSleepDurationMs: data.dec(_f$initialSleepDurationMs),
      exponentialMultiplier: data.dec(_f$exponentialMultiplier),
      jitterRange: data.dec(_f$jitterRange),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModelAPIRetryConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModelAPIRetryConfig>(map);
  }

  static ModelAPIRetryConfig fromJson(String json) {
    return ensureInitialized().decodeJson<ModelAPIRetryConfig>(json);
  }
}

/// @nodoc
mixin ModelAPIRetryConfigMappable {
  String toJson() {
    return ModelAPIRetryConfigMapper.ensureInitialized()
        .encodeJson<ModelAPIRetryConfig>(this as ModelAPIRetryConfig);
  }

  Map<String, dynamic> toMap() {
    return ModelAPIRetryConfigMapper.ensureInitialized()
        .encodeMap<ModelAPIRetryConfig>(this as ModelAPIRetryConfig);
  }

  ModelAPIRetryConfigCopyWith<ModelAPIRetryConfig, ModelAPIRetryConfig,
      ModelAPIRetryConfig> get copyWith => _ModelAPIRetryConfigCopyWithImpl<
          ModelAPIRetryConfig, ModelAPIRetryConfig>(
      this as ModelAPIRetryConfig, $identity, $identity);
  @override
  String toString() {
    return ModelAPIRetryConfigMapper.ensureInitialized().stringifyValue(
      this as ModelAPIRetryConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModelAPIRetryConfigMapper.ensureInitialized().equalsValue(
      this as ModelAPIRetryConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return ModelAPIRetryConfigMapper.ensureInitialized().hashValue(
      this as ModelAPIRetryConfig,
    );
  }
}

/// @nodoc
extension ModelAPIRetryConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModelAPIRetryConfig, $Out> {
  ModelAPIRetryConfigCopyWith<$R, ModelAPIRetryConfig, $Out>
      get $asModelAPIRetryConfig => $base.as(
            (v, t, t2) => _ModelAPIRetryConfigCopyWithImpl<$R, $Out>(v, t, t2),
          );
}

/// @nodoc
abstract class ModelAPIRetryConfigCopyWith<$R, $In extends ModelAPIRetryConfig,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    int? maxRetries,
    int? initialSleepDurationMs,
    double? exponentialMultiplier,
    double? jitterRange,
  });
  ModelAPIRetryConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

/// @nodoc
class _ModelAPIRetryConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModelAPIRetryConfig, $Out>
    implements ModelAPIRetryConfigCopyWith<$R, ModelAPIRetryConfig, $Out> {
  _ModelAPIRetryConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModelAPIRetryConfig> $mapper =
      ModelAPIRetryConfigMapper.ensureInitialized();
  @override
  $R call({
    Object? maxRetries = $none,
    Object? initialSleepDurationMs = $none,
    Object? exponentialMultiplier = $none,
    Object? jitterRange = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (maxRetries != $none) #maxRetries: maxRetries,
          if (initialSleepDurationMs != $none)
            #initialSleepDurationMs: initialSleepDurationMs,
          if (exponentialMultiplier != $none)
            #exponentialMultiplier: exponentialMultiplier,
          if (jitterRange != $none) #jitterRange: jitterRange,
        }),
      );
  @override
  ModelAPIRetryConfig $make(CopyWithData data) => ModelAPIRetryConfig.raw(
        maxRetries: data.get(#maxRetries, or: $value.maxRetries),
        initialSleepDurationMs: data.get(
          #initialSleepDurationMs,
          or: $value.initialSleepDurationMs,
        ),
        exponentialMultiplier: data.get(
          #exponentialMultiplier,
          or: $value.exponentialMultiplier,
        ),
        jitterRange: data.get(#jitterRange, or: $value.jitterRange),
      );

  @override
  ModelAPIRetryConfigCopyWith<$R2, ModelAPIRetryConfig, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _ModelAPIRetryConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

/// @nodoc
class ModelOutputRetryConfigMapper
    extends ClassMapperBase<ModelOutputRetryConfig> {
  ModelOutputRetryConfigMapper._();

  static ModelOutputRetryConfigMapper? _instance;
  static ModelOutputRetryConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModelOutputRetryConfigMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ModelOutputRetryConfig';

  static int? _$maxRetries(ModelOutputRetryConfig v) => v.maxRetries;
  static const Field<ModelOutputRetryConfig, int> _f$maxRetries = Field(
    'maxRetries',
    _$maxRetries,
    key: r'max_retries',
    opt: true,
  );

  @override
  final MappableFields<ModelOutputRetryConfig> fields = const {
    #maxRetries: _f$maxRetries,
  };
  @override
  final bool ignoreNull = true;

  static ModelOutputRetryConfig _instantiate(DecodingData data) {
    return ModelOutputRetryConfig(maxRetries: data.dec(_f$maxRetries));
  }

  @override
  final Function instantiate = _instantiate;

  static ModelOutputRetryConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModelOutputRetryConfig>(map);
  }

  static ModelOutputRetryConfig fromJson(String json) {
    return ensureInitialized().decodeJson<ModelOutputRetryConfig>(json);
  }
}

/// @nodoc
mixin ModelOutputRetryConfigMappable {
  String toJson() {
    return ModelOutputRetryConfigMapper.ensureInitialized()
        .encodeJson<ModelOutputRetryConfig>(this as ModelOutputRetryConfig);
  }

  Map<String, dynamic> toMap() {
    return ModelOutputRetryConfigMapper.ensureInitialized()
        .encodeMap<ModelOutputRetryConfig>(this as ModelOutputRetryConfig);
  }

  ModelOutputRetryConfigCopyWith<ModelOutputRetryConfig, ModelOutputRetryConfig,
          ModelOutputRetryConfig>
      get copyWith => _ModelOutputRetryConfigCopyWithImpl<
              ModelOutputRetryConfig, ModelOutputRetryConfig>(
          this as ModelOutputRetryConfig, $identity, $identity);
  @override
  String toString() {
    return ModelOutputRetryConfigMapper.ensureInitialized().stringifyValue(
      this as ModelOutputRetryConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModelOutputRetryConfigMapper.ensureInitialized().equalsValue(
      this as ModelOutputRetryConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return ModelOutputRetryConfigMapper.ensureInitialized().hashValue(
      this as ModelOutputRetryConfig,
    );
  }
}

/// @nodoc
extension ModelOutputRetryConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModelOutputRetryConfig, $Out> {
  ModelOutputRetryConfigCopyWith<$R, ModelOutputRetryConfig, $Out>
      get $asModelOutputRetryConfig => $base.as(
            (v, t, t2) =>
                _ModelOutputRetryConfigCopyWithImpl<$R, $Out>(v, t, t2),
          );
}

/// @nodoc
abstract class ModelOutputRetryConfigCopyWith<
    $R,
    $In extends ModelOutputRetryConfig,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? maxRetries});
  ModelOutputRetryConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

/// @nodoc
class _ModelOutputRetryConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModelOutputRetryConfig, $Out>
    implements
        ModelOutputRetryConfigCopyWith<$R, ModelOutputRetryConfig, $Out> {
  _ModelOutputRetryConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModelOutputRetryConfig> $mapper =
      ModelOutputRetryConfigMapper.ensureInitialized();
  @override
  $R call({Object? maxRetries = $none}) => $apply(
        FieldCopyWithData({if (maxRetries != $none) #maxRetries: maxRetries}),
      );
  @override
  ModelOutputRetryConfig $make(CopyWithData data) => ModelOutputRetryConfig(
        maxRetries: data.get(#maxRetries, or: $value.maxRetries),
      );

  @override
  ModelOutputRetryConfigCopyWith<$R2, ModelOutputRetryConfig, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _ModelOutputRetryConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

/// @nodoc
class RetryConfigMapper extends ClassMapperBase<RetryConfig> {
  RetryConfigMapper._();

  static RetryConfigMapper? _instance;
  static RetryConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RetryConfigMapper._());
      ModelAPIRetryConfigMapper.ensureInitialized();
      ModelOutputRetryConfigMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'RetryConfig';

  static ModelAPIRetryConfig? _$apiRetry(RetryConfig v) => v.apiRetry;
  static const Field<RetryConfig, ModelAPIRetryConfig> _f$apiRetry = Field(
    'apiRetry',
    _$apiRetry,
    key: r'api_retry',
    opt: true,
  );
  static ModelOutputRetryConfig? _$modelOutputRetry(RetryConfig v) =>
      v.modelOutputRetry;
  static const Field<RetryConfig, ModelOutputRetryConfig> _f$modelOutputRetry =
      Field(
    'modelOutputRetry',
    _$modelOutputRetry,
    key: r'model_output_retry',
    opt: true,
  );

  @override
  final MappableFields<RetryConfig> fields = const {
    #apiRetry: _f$apiRetry,
    #modelOutputRetry: _f$modelOutputRetry,
  };
  @override
  final bool ignoreNull = true;

  static RetryConfig _instantiate(DecodingData data) {
    return RetryConfig(
      apiRetry: data.dec(_f$apiRetry),
      modelOutputRetry: data.dec(_f$modelOutputRetry),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static RetryConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<RetryConfig>(map);
  }

  static RetryConfig fromJson(String json) {
    return ensureInitialized().decodeJson<RetryConfig>(json);
  }
}

/// @nodoc
mixin RetryConfigMappable {
  String toJson() {
    return RetryConfigMapper.ensureInitialized().encodeJson<RetryConfig>(
      this as RetryConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return RetryConfigMapper.ensureInitialized().encodeMap<RetryConfig>(
      this as RetryConfig,
    );
  }

  RetryConfigCopyWith<RetryConfig, RetryConfig, RetryConfig> get copyWith =>
      _RetryConfigCopyWithImpl<RetryConfig, RetryConfig>(
        this as RetryConfig,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return RetryConfigMapper.ensureInitialized().stringifyValue(
      this as RetryConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return RetryConfigMapper.ensureInitialized().equalsValue(
      this as RetryConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return RetryConfigMapper.ensureInitialized().hashValue(this as RetryConfig);
  }
}

/// @nodoc
extension RetryConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, RetryConfig, $Out> {
  RetryConfigCopyWith<$R, RetryConfig, $Out> get $asRetryConfig =>
      $base.as((v, t, t2) => _RetryConfigCopyWithImpl<$R, $Out>(v, t, t2));
}

/// @nodoc
abstract class RetryConfigCopyWith<$R, $In extends RetryConfig, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ModelAPIRetryConfigCopyWith<$R, ModelAPIRetryConfig, ModelAPIRetryConfig>?
      get apiRetry;
  ModelOutputRetryConfigCopyWith<$R, ModelOutputRetryConfig,
      ModelOutputRetryConfig>? get modelOutputRetry;
  $R call({
    ModelAPIRetryConfig? apiRetry,
    ModelOutputRetryConfig? modelOutputRetry,
  });
  RetryConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

/// @nodoc
class _RetryConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, RetryConfig, $Out>
    implements RetryConfigCopyWith<$R, RetryConfig, $Out> {
  _RetryConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<RetryConfig> $mapper =
      RetryConfigMapper.ensureInitialized();
  @override
  ModelAPIRetryConfigCopyWith<$R, ModelAPIRetryConfig, ModelAPIRetryConfig>?
      get apiRetry =>
          $value.apiRetry?.copyWith.$chain((v) => call(apiRetry: v));
  @override
  ModelOutputRetryConfigCopyWith<$R, ModelOutputRetryConfig,
          ModelOutputRetryConfig>?
      get modelOutputRetry => $value.modelOutputRetry?.copyWith.$chain(
            (v) => call(modelOutputRetry: v),
          );
  @override
  $R call({Object? apiRetry = $none, Object? modelOutputRetry = $none}) =>
      $apply(
        FieldCopyWithData({
          if (apiRetry != $none) #apiRetry: apiRetry,
          if (modelOutputRetry != $none) #modelOutputRetry: modelOutputRetry,
        }),
      );
  @override
  RetryConfig $make(CopyWithData data) => RetryConfig(
        apiRetry: data.get(#apiRetry, or: $value.apiRetry),
        modelOutputRetry:
            data.get(#modelOutputRetry, or: $value.modelOutputRetry),
      );

  @override
  RetryConfigCopyWith<$R2, RetryConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _RetryConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
