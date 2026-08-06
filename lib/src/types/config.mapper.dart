// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'config.dart';

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
      AgentModeMapper.ensureInitialized();
      BuiltinToolsMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SubagentCapabilities';

  static AgentMode _$agentMode(SubagentCapabilities v) => v.agentMode;
  static const Field<SubagentCapabilities, AgentMode> _f$agentMode = Field(
    'agentMode',
    _$agentMode,
    key: r'agent_mode',
    opt: true,
    def: AgentMode.autonomous,
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

  @override
  final MappableFields<SubagentCapabilities> fields = const {
    #agentMode: _f$agentMode,
    #enabledTools: _f$enabledTools,
    #disabledTools: _f$disabledTools,
  };
  @override
  final bool ignoreNull = true;

  static SubagentCapabilities _instantiate(DecodingData data) {
    return SubagentCapabilities(
      agentMode: data.dec(_f$agentMode),
      enabledTools: data.dec(_f$enabledTools),
      disabledTools: data.dec(_f$disabledTools),
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
  $R call({
    AgentMode? agentMode,
    List<BuiltinTools>? enabledTools,
    List<BuiltinTools>? disabledTools,
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
  $R call({
    AgentMode? agentMode,
    Object? enabledTools = $none,
    Object? disabledTools = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (agentMode != null) #agentMode: agentMode,
          if (enabledTools != $none) #enabledTools: enabledTools,
          if (disabledTools != $none) #disabledTools: disabledTools,
        }),
      );
  @override
  SubagentCapabilities $make(CopyWithData data) => SubagentCapabilities(
        agentMode: data.get(#agentMode, or: $value.agentMode),
        enabledTools: data.get(#enabledTools, or: $value.enabledTools),
        disabledTools: data.get(#disabledTools, or: $value.disabledTools),
      );

  @override
  SubagentCapabilitiesCopyWith<$R2, SubagentCapabilities, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _SubagentCapabilitiesCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

/// @nodoc
class SubagentConfigMapper extends ClassMapperBase<SubagentConfig> {
  SubagentConfigMapper._();

  static SubagentConfigMapper? _instance;
  static SubagentConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SubagentConfigMapper._());
      SubagentCapabilitiesMapper.ensureInitialized();
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
  static List<String> _$tools(SubagentConfig v) => v.tools;
  static const Field<SubagentConfig, List<String>> _f$tools = Field(
    'tools',
    _$tools,
    opt: true,
  );

  @override
  final MappableFields<SubagentConfig> fields = const {
    #name: _f$name,
    #description: _f$description,
    #systemInstructions: _f$systemInstructions,
    #capabilities: _f$capabilities,
    #tools: _f$tools,
  };
  @override
  final bool ignoreNull = true;

  static SubagentConfig _instantiate(DecodingData data) {
    return SubagentConfig(
      name: data.dec(_f$name),
      description: data.dec(_f$description),
      systemInstructions: data.dec(_f$systemInstructions),
      capabilities: data.dec(_f$capabilities),
      tools: data.dec(_f$tools),
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
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get tools;
  $R call({
    String? name,
    String? description,
    dynamic systemInstructions,
    SubagentCapabilities? capabilities,
    List<String>? tools,
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
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get tools =>
      ListCopyWith(
        $value.tools,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(tools: v),
      );
  @override
  $R call({
    String? name,
    String? description,
    Object? systemInstructions = $none,
    Object? capabilities = $none,
    Object? tools = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (name != null) #name: name,
          if (description != null) #description: description,
          if (systemInstructions != $none)
            #systemInstructions: systemInstructions,
          if (capabilities != $none) #capabilities: capabilities,
          if (tools != $none) #tools: tools,
        }),
      );
  @override
  SubagentConfig $make(CopyWithData data) => SubagentConfig(
        name: data.get(#name, or: $value.name),
        description: data.get(#description, or: $value.description),
        systemInstructions: data.get(
          #systemInstructions,
          or: $value.systemInstructions,
        ),
        capabilities: data.get(#capabilities, or: $value.capabilities),
        tools: data.get(#tools, or: $value.tools),
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
  static Duration? _$initialSleepDuration(ModelAPIRetryConfig v) =>
      v.initialSleepDuration;
  static const Field<ModelAPIRetryConfig, Duration> _f$initialSleepDuration =
      Field(
    'initialSleepDuration',
    _$initialSleepDuration,
    key: r'initial_sleep_duration',
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
    #initialSleepDuration: _f$initialSleepDuration,
    #exponentialMultiplier: _f$exponentialMultiplier,
    #jitterRange: _f$jitterRange,
  };
  @override
  final bool ignoreNull = true;

  static ModelAPIRetryConfig _instantiate(DecodingData data) {
    return ModelAPIRetryConfig(
      maxRetries: data.dec(_f$maxRetries),
      initialSleepDurationMs: data.dec(_f$initialSleepDurationMs),
      initialSleepDuration: data.dec(_f$initialSleepDuration),
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
    Duration? initialSleepDuration,
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
    Object? initialSleepDuration = $none,
    Object? exponentialMultiplier = $none,
    Object? jitterRange = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (maxRetries != $none) #maxRetries: maxRetries,
          if (initialSleepDurationMs != $none)
            #initialSleepDurationMs: initialSleepDurationMs,
          if (initialSleepDuration != $none)
            #initialSleepDuration: initialSleepDuration,
          if (exponentialMultiplier != $none)
            #exponentialMultiplier: exponentialMultiplier,
          if (jitterRange != $none) #jitterRange: jitterRange,
        }),
      );
  @override
  ModelAPIRetryConfig $make(CopyWithData data) => ModelAPIRetryConfig(
        maxRetries: data.get(#maxRetries, or: $value.maxRetries),
        initialSleepDurationMs: data.get(
          #initialSleepDurationMs,
          or: $value.initialSleepDurationMs,
        ),
        initialSleepDuration: data.get(
          #initialSleepDuration,
          or: $value.initialSleepDuration,
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
