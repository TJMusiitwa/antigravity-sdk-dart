// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'connection.dart';

/// @nodoc
class AgentConfigMapper extends ClassMapperBase<AgentConfig> {
  AgentConfigMapper._();

  static AgentConfigMapper? _instance;
  static AgentConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AgentConfigMapper._());
      MapperContainer.globals.useAll([
        ToolMapper(),
        PolicyMapper(),
        HookMapper(),
        TriggerMapper(),
      ]);
      CapabilitiesConfigMapper.ensureInitialized();
      McpServerConfigMapper.ensureInitialized();
      SubagentConfigMapper.ensureInitialized();
      SessionContinuationModeMapper.ensureInitialized();
      DebugConfigMapper.ensureInitialized();
      RetryConfigMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'AgentConfig';

  static dynamic _$systemInstructions(AgentConfig v) => v.systemInstructions;
  static const Field<AgentConfig, dynamic> _f$systemInstructions = Field(
    'systemInstructions',
    _$systemInstructions,
    opt: true,
  );
  static CapabilitiesConfig _$capabilities(AgentConfig v) => v.capabilities;
  static const Field<AgentConfig, CapabilitiesConfig> _f$capabilities = Field(
    'capabilities',
    _$capabilities,
    opt: true,
  );
  static List<Tool> _$tools(AgentConfig v) => v.tools;
  static const Field<AgentConfig, List<Tool>> _f$tools = Field(
    'tools',
    _$tools,
    opt: true,
  );
  static List<Policy> _$policies(AgentConfig v) => v.policies;
  static dynamic _arg$policies(f) => f<List<Policy>>();
  static const Field<AgentConfig, List<dynamic>> _f$policies = Field(
    'policies',
    _$policies,
    opt: true,
    arg: _arg$policies,
  );
  static List<Hook> _$hooks(AgentConfig v) => v.hooks;
  static const Field<AgentConfig, List<Hook>> _f$hooks = Field(
    'hooks',
    _$hooks,
    opt: true,
  );
  static List<FutureOr<void> Function(TriggerContext)> _$triggers(
    AgentConfig v,
  ) =>
      v.triggers;
  static const Field<AgentConfig, List<FutureOr<void> Function(TriggerContext)>>
      _f$triggers = Field('triggers', _$triggers, opt: true);
  static List<McpServerConfig> _$mcpServers(AgentConfig v) => v.mcpServers;
  static const Field<AgentConfig, List<McpServerConfig>> _f$mcpServers = Field(
    'mcpServers',
    _$mcpServers,
    opt: true,
  );
  static List<SubagentConfig> _$subagents(AgentConfig v) => v.subagents;
  static const Field<AgentConfig, List<SubagentConfig>> _f$subagents = Field(
    'subagents',
    _$subagents,
    opt: true,
  );
  static List<String> _$workspaces(AgentConfig v) => v.workspaces;
  static const Field<AgentConfig, List<String>> _f$workspaces = Field(
    'workspaces',
    _$workspaces,
    opt: true,
  );
  static String? _$conversationId(AgentConfig v) => v.conversationId;
  static const Field<AgentConfig, String> _f$conversationId = Field(
    'conversationId',
    _$conversationId,
    opt: true,
  );
  static SessionContinuationMode? _$sessionContinuationMode(AgentConfig v) =>
      v.sessionContinuationMode;
  static const Field<AgentConfig, SessionContinuationMode>
      _f$sessionContinuationMode = Field(
    'sessionContinuationMode',
    _$sessionContinuationMode,
    opt: true,
  );
  static String? _$saveDir(AgentConfig v) => v.saveDir;
  static const Field<AgentConfig, String> _f$saveDir = Field(
    'saveDir',
    _$saveDir,
    opt: true,
  );
  static String? _$appDataDir(AgentConfig v) => v.appDataDir;
  static const Field<AgentConfig, String> _f$appDataDir = Field(
    'appDataDir',
    _$appDataDir,
    opt: true,
  );
  static dynamic _$responseSchema(AgentConfig v) => v.responseSchema;
  static const Field<AgentConfig, dynamic> _f$responseSchema = Field(
    'responseSchema',
    _$responseSchema,
    opt: true,
  );
  static List<String> _$skillsPaths(AgentConfig v) => v.skillsPaths;
  static const Field<AgentConfig, List<String>> _f$skillsPaths = Field(
    'skillsPaths',
    _$skillsPaths,
    opt: true,
  );
  static DebugConfig? _$debugConfig(AgentConfig v) => v.debugConfig;
  static const Field<AgentConfig, DebugConfig> _f$debugConfig = Field(
    'debugConfig',
    _$debugConfig,
    opt: true,
  );
  static RetryConfig? _$retryConfig(AgentConfig v) => v.retryConfig;
  static const Field<AgentConfig, RetryConfig> _f$retryConfig = Field(
    'retryConfig',
    _$retryConfig,
    opt: true,
  );

  @override
  final MappableFields<AgentConfig> fields = const {
    #systemInstructions: _f$systemInstructions,
    #capabilities: _f$capabilities,
    #tools: _f$tools,
    #policies: _f$policies,
    #hooks: _f$hooks,
    #triggers: _f$triggers,
    #mcpServers: _f$mcpServers,
    #subagents: _f$subagents,
    #workspaces: _f$workspaces,
    #conversationId: _f$conversationId,
    #sessionContinuationMode: _f$sessionContinuationMode,
    #saveDir: _f$saveDir,
    #appDataDir: _f$appDataDir,
    #responseSchema: _f$responseSchema,
    #skillsPaths: _f$skillsPaths,
    #debugConfig: _f$debugConfig,
    #retryConfig: _f$retryConfig,
  };

  static AgentConfig _instantiate(DecodingData data) {
    throw MapperException.missingConstructor('AgentConfig');
  }

  @override
  final Function instantiate = _instantiate;

  static AgentConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<AgentConfig>(map);
  }

  static AgentConfig fromJson(String json) {
    return ensureInitialized().decodeJson<AgentConfig>(json);
  }
}

/// @nodoc
mixin AgentConfigMappable {
  String toJson();
  Map<String, dynamic> toMap();
  AgentConfigCopyWith<AgentConfig, AgentConfig, AgentConfig> get copyWith;
}

/// @nodoc
abstract class AgentConfigCopyWith<$R, $In extends AgentConfig, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  CapabilitiesConfigCopyWith<$R, CapabilitiesConfig, CapabilitiesConfig>
      get capabilities;
  ListCopyWith<$R, Tool, ObjectCopyWith<$R, Tool, Tool>> get tools;
  ListCopyWith<$R, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?> get policies;
  ListCopyWith<$R, Hook, ObjectCopyWith<$R, Hook, Hook>> get hooks;
  ListCopyWith<
      $R,
      FutureOr<void> Function(TriggerContext),
      ObjectCopyWith<$R, FutureOr<void> Function(TriggerContext),
          FutureOr<void> Function(TriggerContext)>> get triggers;
  ListCopyWith<$R, McpServerConfig,
          McpServerConfigCopyWith<$R, McpServerConfig, McpServerConfig>>
      get mcpServers;
  ListCopyWith<$R, SubagentConfig,
      SubagentConfigCopyWith<$R, SubagentConfig, SubagentConfig>> get subagents;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get workspaces;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get skillsPaths;
  DebugConfigCopyWith<$R, DebugConfig, DebugConfig>? get debugConfig;
  RetryConfigCopyWith<$R, RetryConfig, RetryConfig>? get retryConfig;
  $R call({
    dynamic systemInstructions,
    CapabilitiesConfig? capabilities,
    List<Tool>? tools,
    List<dynamic>? policies,
    List<Hook>? hooks,
    List<FutureOr<void> Function(TriggerContext)>? triggers,
    List<McpServerConfig>? mcpServers,
    List<SubagentConfig>? subagents,
    List<String>? workspaces,
    String? conversationId,
    SessionContinuationMode? sessionContinuationMode,
    String? saveDir,
    String? appDataDir,
    dynamic responseSchema,
    List<String>? skillsPaths,
    DebugConfig? debugConfig,
    RetryConfig? retryConfig,
  });
  AgentConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

/// @nodoc
class DebugConfigMapper extends ClassMapperBase<DebugConfig> {
  DebugConfigMapper._();

  static DebugConfigMapper? _instance;
  static DebugConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DebugConfigMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'DebugConfig';

  static bool _$enableServerSideTracing(DebugConfig v) =>
      v.enableServerSideTracing;
  static const Field<DebugConfig, bool> _f$enableServerSideTracing = Field(
    'enableServerSideTracing',
    _$enableServerSideTracing,
    key: r'enable_server_side_tracing',
    opt: true,
    def: true,
  );
  static String? _$loggingLevel(DebugConfig v) => v.loggingLevel;
  static dynamic _arg$loggingLevel(f) => f<String>();
  static const Field<DebugConfig, dynamic> _f$loggingLevel = Field(
    'loggingLevel',
    _$loggingLevel,
    key: r'logging_level',
    opt: true,
    def: 'FINE',
    arg: _arg$loggingLevel,
  );
  static Level? _$level(DebugConfig v) => v.level;
  static const Field<DebugConfig, Level> _f$level = Field(
    'level',
    _$level,
    opt: true,
  );

  @override
  final MappableFields<DebugConfig> fields = const {
    #enableServerSideTracing: _f$enableServerSideTracing,
    #loggingLevel: _f$loggingLevel,
    #level: _f$level,
  };
  @override
  final bool ignoreNull = true;

  static DebugConfig _instantiate(DecodingData data) {
    return DebugConfig(
      enableServerSideTracing: data.dec(_f$enableServerSideTracing),
      loggingLevel: data.dec(_f$loggingLevel),
      level: data.dec(_f$level),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DebugConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DebugConfig>(map);
  }

  static DebugConfig fromJson(String json) {
    return ensureInitialized().decodeJson<DebugConfig>(json);
  }
}

/// @nodoc
mixin DebugConfigMappable {
  String toJson() {
    return DebugConfigMapper.ensureInitialized().encodeJson<DebugConfig>(
      this as DebugConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return DebugConfigMapper.ensureInitialized().encodeMap<DebugConfig>(
      this as DebugConfig,
    );
  }

  DebugConfigCopyWith<DebugConfig, DebugConfig, DebugConfig> get copyWith =>
      _DebugConfigCopyWithImpl<DebugConfig, DebugConfig>(
        this as DebugConfig,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return DebugConfigMapper.ensureInitialized().stringifyValue(
      this as DebugConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return DebugConfigMapper.ensureInitialized().equalsValue(
      this as DebugConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return DebugConfigMapper.ensureInitialized().hashValue(this as DebugConfig);
  }
}

/// @nodoc
extension DebugConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DebugConfig, $Out> {
  DebugConfigCopyWith<$R, DebugConfig, $Out> get $asDebugConfig =>
      $base.as((v, t, t2) => _DebugConfigCopyWithImpl<$R, $Out>(v, t, t2));
}

/// @nodoc
abstract class DebugConfigCopyWith<$R, $In extends DebugConfig, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({bool? enableServerSideTracing, dynamic loggingLevel, Level? level});
  DebugConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

/// @nodoc
class _DebugConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DebugConfig, $Out>
    implements DebugConfigCopyWith<$R, DebugConfig, $Out> {
  _DebugConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DebugConfig> $mapper =
      DebugConfigMapper.ensureInitialized();
  @override
  $R call({
    bool? enableServerSideTracing,
    Object? loggingLevel = $none,
    Object? level = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (enableServerSideTracing != null)
            #enableServerSideTracing: enableServerSideTracing,
          if (loggingLevel != $none) #loggingLevel: loggingLevel,
          if (level != $none) #level: level,
        }),
      );
  @override
  DebugConfig $make(CopyWithData data) => DebugConfig(
        enableServerSideTracing: data.get(
          #enableServerSideTracing,
          or: $value.enableServerSideTracing,
        ),
        loggingLevel: data.get(#loggingLevel, or: $value.loggingLevel),
        level: data.get(#level, or: $value.level),
      );

  @override
  DebugConfigCopyWith<$R2, DebugConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _DebugConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
