// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'local_connection_config.dart';

/// @nodoc

class LiteRTBackendMapper extends EnumMapper<LiteRTBackend> {
  LiteRTBackendMapper._();

  static LiteRTBackendMapper? _instance;
  static LiteRTBackendMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LiteRTBackendMapper._());
    }
    return _instance!;
  }

  static LiteRTBackend fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  LiteRTBackend decode(dynamic value) {
    switch (value) {
      case r'cpu':
        return LiteRTBackend.cpu;
      case r'gpu':
        return LiteRTBackend.gpu;
      case r'npu':
        return LiteRTBackend.npu;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(LiteRTBackend self) {
    switch (self) {
      case LiteRTBackend.cpu:
        return r'cpu';
      case LiteRTBackend.gpu:
        return r'gpu';
      case LiteRTBackend.npu:
        return r'npu';
    }
  }
}

/// @nodoc

extension LiteRTBackendMapperExtension on LiteRTBackend {
  String toValue() {
    LiteRTBackendMapper.ensureInitialized();
    return MapperContainer.globals.toValue<LiteRTBackend>(this) as String;
  }
}

/// @nodoc
class BaseLocalAgentConfigMapper extends ClassMapperBase<BaseLocalAgentConfig> {
  BaseLocalAgentConfigMapper._();

  static BaseLocalAgentConfigMapper? _instance;
  static BaseLocalAgentConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = BaseLocalAgentConfigMapper._());
      AgentConfigMapper.ensureInitialized();
      LocalAgentConfigMapper.ensureInitialized();
      LocalOpenAIAgentConfigMapper.ensureInitialized();
      LiteRTAgentConfigMapper.ensureInitialized();
      CapabilitiesConfigMapper.ensureInitialized();
      McpServerConfigMapper.ensureInitialized();
      SubagentConfigMapper.ensureInitialized();
      SessionContinuationModeMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'BaseLocalAgentConfig';

  static dynamic _$systemInstructions(BaseLocalAgentConfig v) =>
      v.systemInstructions;
  static const Field<BaseLocalAgentConfig, dynamic> _f$systemInstructions =
      Field('systemInstructions', _$systemInstructions, opt: true);
  static CapabilitiesConfig _$capabilities(BaseLocalAgentConfig v) =>
      v.capabilities;
  static const Field<BaseLocalAgentConfig, CapabilitiesConfig> _f$capabilities =
      Field('capabilities', _$capabilities, opt: true);
  static List<Tool> _$tools(BaseLocalAgentConfig v) => v.tools;
  static const Field<BaseLocalAgentConfig, List<Tool>> _f$tools = Field(
    'tools',
    _$tools,
    opt: true,
  );
  static List<Policy> _$policies(BaseLocalAgentConfig v) => v.policies;
  static dynamic _arg$policies(f) => f<List<Policy>>();
  static const Field<BaseLocalAgentConfig, List<dynamic>> _f$policies = Field(
    'policies',
    _$policies,
    opt: true,
    arg: _arg$policies,
  );
  static List<Hook> _$hooks(BaseLocalAgentConfig v) => v.hooks;
  static const Field<BaseLocalAgentConfig, List<Hook>> _f$hooks = Field(
    'hooks',
    _$hooks,
    opt: true,
  );
  static List<FutureOr<void> Function(TriggerContext)> _$triggers(
    BaseLocalAgentConfig v,
  ) =>
      v.triggers;
  static const Field<BaseLocalAgentConfig,
          List<FutureOr<void> Function(TriggerContext)>> _f$triggers =
      Field('triggers', _$triggers, opt: true);
  static List<McpServerConfig> _$mcpServers(BaseLocalAgentConfig v) =>
      v.mcpServers;
  static const Field<BaseLocalAgentConfig, List<McpServerConfig>>
      _f$mcpServers = Field('mcpServers', _$mcpServers, opt: true);
  static List<SubagentConfig> _$subagents(BaseLocalAgentConfig v) =>
      v.subagents;
  static const Field<BaseLocalAgentConfig, List<SubagentConfig>> _f$subagents =
      Field('subagents', _$subagents, opt: true);
  static List<String> _$workspaces(BaseLocalAgentConfig v) => v.workspaces;
  static const Field<BaseLocalAgentConfig, List<String>> _f$workspaces = Field(
    'workspaces',
    _$workspaces,
    opt: true,
  );
  static String? _$conversationId(BaseLocalAgentConfig v) => v.conversationId;
  static const Field<BaseLocalAgentConfig, String> _f$conversationId = Field(
    'conversationId',
    _$conversationId,
    opt: true,
  );
  static SessionContinuationMode? _$sessionContinuationMode(
    BaseLocalAgentConfig v,
  ) =>
      v.sessionContinuationMode;
  static const Field<BaseLocalAgentConfig, SessionContinuationMode>
      _f$sessionContinuationMode = Field(
    'sessionContinuationMode',
    _$sessionContinuationMode,
    opt: true,
  );
  static String? _$saveDir(BaseLocalAgentConfig v) => v.saveDir;
  static const Field<BaseLocalAgentConfig, String> _f$saveDir = Field(
    'saveDir',
    _$saveDir,
    opt: true,
  );
  static String? _$appDataDir(BaseLocalAgentConfig v) => v.appDataDir;
  static const Field<BaseLocalAgentConfig, String> _f$appDataDir = Field(
    'appDataDir',
    _$appDataDir,
    opt: true,
  );
  static dynamic _$responseSchema(BaseLocalAgentConfig v) => v.responseSchema;
  static const Field<BaseLocalAgentConfig, dynamic> _f$responseSchema = Field(
    'responseSchema',
    _$responseSchema,
    opt: true,
  );
  static List<String> _$skillsPaths(BaseLocalAgentConfig v) => v.skillsPaths;
  static const Field<BaseLocalAgentConfig, List<String>> _f$skillsPaths = Field(
    'skillsPaths',
    _$skillsPaths,
    opt: true,
  );

  @override
  final MappableFields<BaseLocalAgentConfig> fields = const {
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
  };

  static BaseLocalAgentConfig _instantiate(DecodingData data) {
    throw MapperException.missingConstructor('BaseLocalAgentConfig');
  }

  @override
  final Function instantiate = _instantiate;

  static BaseLocalAgentConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<BaseLocalAgentConfig>(map);
  }

  static BaseLocalAgentConfig fromJson(String json) {
    return ensureInitialized().decodeJson<BaseLocalAgentConfig>(json);
  }
}

/// @nodoc
mixin BaseLocalAgentConfigMappable {
  String toJson();
  Map<String, dynamic> toMap();
  BaseLocalAgentConfigCopyWith<BaseLocalAgentConfig, BaseLocalAgentConfig,
      BaseLocalAgentConfig> get copyWith;
}

/// @nodoc
abstract class BaseLocalAgentConfigCopyWith<
    $R,
    $In extends BaseLocalAgentConfig,
    $Out> implements AgentConfigCopyWith<$R, $In, $Out> {
  CapabilitiesConfigCopyWith<$R, CapabilitiesConfig, CapabilitiesConfig>
      get capabilities;
  ListCopyWith<$R, Tool, ObjectCopyWith<$R, Tool, Tool>> get tools;
  @override
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
  @override
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
  });
  BaseLocalAgentConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

/// @nodoc
class LocalAgentConfigMapper extends ClassMapperBase<LocalAgentConfig> {
  LocalAgentConfigMapper._();

  static LocalAgentConfigMapper? _instance;
  static LocalAgentConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LocalAgentConfigMapper._());
      BaseLocalAgentConfigMapper.ensureInitialized();
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
      ModelTargetMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'LocalAgentConfig';

  static dynamic _$systemInstructions(LocalAgentConfig v) =>
      v.systemInstructions;
  static const Field<LocalAgentConfig, dynamic> _f$systemInstructions = Field(
    'systemInstructions',
    _$systemInstructions,
    opt: true,
  );
  static CapabilitiesConfig _$capabilities(LocalAgentConfig v) =>
      v.capabilities;
  static const Field<LocalAgentConfig, CapabilitiesConfig> _f$capabilities =
      Field('capabilities', _$capabilities, opt: true);
  static List<Tool> _$tools(LocalAgentConfig v) => v.tools;
  static const Field<LocalAgentConfig, List<Tool>> _f$tools = Field(
    'tools',
    _$tools,
    opt: true,
  );
  static List<Policy> _$policies(LocalAgentConfig v) => v.policies;
  static dynamic _arg$policies(f) => f<List<Policy>>();
  static const Field<LocalAgentConfig, List<dynamic>> _f$policies = Field(
    'policies',
    _$policies,
    opt: true,
    arg: _arg$policies,
  );
  static List<Hook> _$hooks(LocalAgentConfig v) => v.hooks;
  static const Field<LocalAgentConfig, List<Hook>> _f$hooks = Field(
    'hooks',
    _$hooks,
    opt: true,
  );
  static List<FutureOr<void> Function(TriggerContext)> _$triggers(
    LocalAgentConfig v,
  ) =>
      v.triggers;
  static const Field<LocalAgentConfig,
          List<FutureOr<void> Function(TriggerContext)>> _f$triggers =
      Field('triggers', _$triggers, opt: true);
  static List<McpServerConfig> _$mcpServers(LocalAgentConfig v) => v.mcpServers;
  static const Field<LocalAgentConfig, List<McpServerConfig>> _f$mcpServers =
      Field('mcpServers', _$mcpServers, opt: true);
  static List<SubagentConfig> _$subagents(LocalAgentConfig v) => v.subagents;
  static const Field<LocalAgentConfig, List<SubagentConfig>> _f$subagents =
      Field('subagents', _$subagents, opt: true);
  static List<String> _$workspaces(LocalAgentConfig v) => v.workspaces;
  static const Field<LocalAgentConfig, List<String>> _f$workspaces = Field(
    'workspaces',
    _$workspaces,
    opt: true,
  );
  static String? _$conversationId(LocalAgentConfig v) => v.conversationId;
  static const Field<LocalAgentConfig, String> _f$conversationId = Field(
    'conversationId',
    _$conversationId,
    opt: true,
  );
  static SessionContinuationMode? _$sessionContinuationMode(
    LocalAgentConfig v,
  ) =>
      v.sessionContinuationMode;
  static const Field<LocalAgentConfig, SessionContinuationMode>
      _f$sessionContinuationMode = Field(
    'sessionContinuationMode',
    _$sessionContinuationMode,
    opt: true,
  );
  static String? _$saveDir(LocalAgentConfig v) => v.saveDir;
  static const Field<LocalAgentConfig, String> _f$saveDir = Field(
    'saveDir',
    _$saveDir,
    opt: true,
  );
  static String? _$appDataDir(LocalAgentConfig v) => v.appDataDir;
  static const Field<LocalAgentConfig, String> _f$appDataDir = Field(
    'appDataDir',
    _$appDataDir,
    opt: true,
  );
  static dynamic _$responseSchema(LocalAgentConfig v) => v.responseSchema;
  static const Field<LocalAgentConfig, dynamic> _f$responseSchema = Field(
    'responseSchema',
    _$responseSchema,
    opt: true,
  );
  static List<String> _$skillsPaths(LocalAgentConfig v) => v.skillsPaths;
  static const Field<LocalAgentConfig, List<String>> _f$skillsPaths = Field(
    'skillsPaths',
    _$skillsPaths,
    opt: true,
  );
  static dynamic _$model(LocalAgentConfig v) => v.model;
  static const Field<LocalAgentConfig, dynamic> _f$model = Field(
    'model',
    _$model,
    opt: true,
  );
  static List<ModelTarget>? _$models(LocalAgentConfig v) => v.models;
  static const Field<LocalAgentConfig, List<ModelTarget>> _f$models = Field(
    'models',
    _$models,
    opt: true,
  );
  static String? _$apiKey(LocalAgentConfig v) => v.apiKey;
  static const Field<LocalAgentConfig, String> _f$apiKey = Field(
    'apiKey',
    _$apiKey,
    opt: true,
  );
  static bool _$vertex(LocalAgentConfig v) => v.vertex;
  static const Field<LocalAgentConfig, bool> _f$vertex = Field(
    'vertex',
    _$vertex,
    opt: true,
  );
  static String? _$project(LocalAgentConfig v) => v.project;
  static const Field<LocalAgentConfig, String> _f$project = Field(
    'project',
    _$project,
    opt: true,
  );
  static String? _$location(LocalAgentConfig v) => v.location;
  static const Field<LocalAgentConfig, String> _f$location = Field(
    'location',
    _$location,
    opt: true,
  );
  static String? _$binaryPath(LocalAgentConfig v) => v.binaryPath;
  static const Field<LocalAgentConfig, String> _f$binaryPath = Field(
    'binaryPath',
    _$binaryPath,
    opt: true,
  );

  @override
  final MappableFields<LocalAgentConfig> fields = const {
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
    #model: _f$model,
    #models: _f$models,
    #apiKey: _f$apiKey,
    #vertex: _f$vertex,
    #project: _f$project,
    #location: _f$location,
    #binaryPath: _f$binaryPath,
  };

  static LocalAgentConfig _instantiate(DecodingData data) {
    return LocalAgentConfig(
      systemInstructions: data.dec(_f$systemInstructions),
      capabilities: data.dec(_f$capabilities),
      tools: data.dec(_f$tools),
      policies: data.dec(_f$policies),
      hooks: data.dec(_f$hooks),
      triggers: data.dec(_f$triggers),
      mcpServers: data.dec(_f$mcpServers),
      subagents: data.dec(_f$subagents),
      workspaces: data.dec(_f$workspaces),
      conversationId: data.dec(_f$conversationId),
      sessionContinuationMode: data.dec(_f$sessionContinuationMode),
      saveDir: data.dec(_f$saveDir),
      appDataDir: data.dec(_f$appDataDir),
      responseSchema: data.dec(_f$responseSchema),
      skillsPaths: data.dec(_f$skillsPaths),
      model: data.dec(_f$model),
      models: data.dec(_f$models),
      apiKey: data.dec(_f$apiKey),
      vertex: data.dec(_f$vertex),
      project: data.dec(_f$project),
      location: data.dec(_f$location),
      binaryPath: data.dec(_f$binaryPath),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static LocalAgentConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LocalAgentConfig>(map);
  }

  static LocalAgentConfig fromJson(String json) {
    return ensureInitialized().decodeJson<LocalAgentConfig>(json);
  }
}

/// @nodoc
mixin LocalAgentConfigMappable {
  String toJson() {
    return LocalAgentConfigMapper.ensureInitialized()
        .encodeJson<LocalAgentConfig>(this as LocalAgentConfig);
  }

  Map<String, dynamic> toMap() {
    return LocalAgentConfigMapper.ensureInitialized()
        .encodeMap<LocalAgentConfig>(this as LocalAgentConfig);
  }

  LocalAgentConfigCopyWith<LocalAgentConfig, LocalAgentConfig, LocalAgentConfig>
      get copyWith =>
          _LocalAgentConfigCopyWithImpl<LocalAgentConfig, LocalAgentConfig>(
            this as LocalAgentConfig,
            $identity,
            $identity,
          );
  @override
  String toString() {
    return LocalAgentConfigMapper.ensureInitialized().stringifyValue(
      this as LocalAgentConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return LocalAgentConfigMapper.ensureInitialized().equalsValue(
      this as LocalAgentConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return LocalAgentConfigMapper.ensureInitialized().hashValue(
      this as LocalAgentConfig,
    );
  }
}

/// @nodoc
extension LocalAgentConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, LocalAgentConfig, $Out> {
  LocalAgentConfigCopyWith<$R, LocalAgentConfig, $Out>
      get $asLocalAgentConfig => $base
          .as((v, t, t2) => _LocalAgentConfigCopyWithImpl<$R, $Out>(v, t, t2));
}

/// @nodoc
abstract class LocalAgentConfigCopyWith<$R, $In extends LocalAgentConfig, $Out>
    implements BaseLocalAgentConfigCopyWith<$R, $In, $Out> {
  @override
  CapabilitiesConfigCopyWith<$R, CapabilitiesConfig, CapabilitiesConfig>
      get capabilities;
  @override
  ListCopyWith<$R, Tool, ObjectCopyWith<$R, Tool, Tool>> get tools;
  @override
  ListCopyWith<$R, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?> get policies;
  @override
  ListCopyWith<$R, Hook, ObjectCopyWith<$R, Hook, Hook>> get hooks;
  @override
  ListCopyWith<
      $R,
      FutureOr<void> Function(TriggerContext),
      ObjectCopyWith<$R, FutureOr<void> Function(TriggerContext),
          FutureOr<void> Function(TriggerContext)>> get triggers;
  @override
  ListCopyWith<$R, McpServerConfig,
          McpServerConfigCopyWith<$R, McpServerConfig, McpServerConfig>>
      get mcpServers;
  @override
  ListCopyWith<$R, SubagentConfig,
      SubagentConfigCopyWith<$R, SubagentConfig, SubagentConfig>> get subagents;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get workspaces;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get skillsPaths;
  ListCopyWith<$R, ModelTarget,
      ModelTargetCopyWith<$R, ModelTarget, ModelTarget>>? get models;
  @override
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
    dynamic model,
    List<ModelTarget>? models,
    String? apiKey,
    bool? vertex,
    String? project,
    String? location,
    String? binaryPath,
  });
  LocalAgentConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

/// @nodoc
class _LocalAgentConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LocalAgentConfig, $Out>
    implements LocalAgentConfigCopyWith<$R, LocalAgentConfig, $Out> {
  _LocalAgentConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LocalAgentConfig> $mapper =
      LocalAgentConfigMapper.ensureInitialized();
  @override
  CapabilitiesConfigCopyWith<$R, CapabilitiesConfig, CapabilitiesConfig>
      get capabilities => ($value.capabilities as CapabilitiesConfig)
          .copyWith
          .$chain((v) => call(capabilities: v));
  @override
  ListCopyWith<$R, Tool, ObjectCopyWith<$R, Tool, Tool>> get tools =>
      ListCopyWith(
        $value.tools,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(tools: v),
      );
  @override
  ListCopyWith<$R, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
      get policies => ListCopyWith(
            $value.policies,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(policies: v),
          );
  @override
  ListCopyWith<$R, Hook, ObjectCopyWith<$R, Hook, Hook>> get hooks =>
      ListCopyWith(
        $value.hooks,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(hooks: v),
      );
  @override
  ListCopyWith<
      $R,
      FutureOr<void> Function(TriggerContext),
      ObjectCopyWith<$R, FutureOr<void> Function(TriggerContext),
          FutureOr<void> Function(TriggerContext)>> get triggers =>
      ListCopyWith(
        $value.triggers,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(triggers: v),
      );
  @override
  ListCopyWith<$R, McpServerConfig,
          McpServerConfigCopyWith<$R, McpServerConfig, McpServerConfig>>
      get mcpServers => ListCopyWith(
            $value.mcpServers,
            (v, t) => v.copyWith.$chain(t),
            (v) => call(mcpServers: v),
          );
  @override
  ListCopyWith<$R, SubagentConfig,
          SubagentConfigCopyWith<$R, SubagentConfig, SubagentConfig>>
      get subagents => ListCopyWith(
            $value.subagents,
            (v, t) => v.copyWith.$chain(t),
            (v) => call(subagents: v),
          );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get workspaces =>
      ListCopyWith(
        $value.workspaces,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(workspaces: v),
      );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get skillsPaths => ListCopyWith(
            $value.skillsPaths,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(skillsPaths: v),
          );
  @override
  ListCopyWith<$R, ModelTarget,
          ModelTargetCopyWith<$R, ModelTarget, ModelTarget>>?
      get models => $value.models != null
          ? ListCopyWith(
              $value.models!,
              (v, t) => v.copyWith.$chain(t),
              (v) => call(models: v),
            )
          : null;
  @override
  $R call({
    Object? systemInstructions = $none,
    Object? capabilities = $none,
    Object? tools = $none,
    Object? policies = $none,
    Object? hooks = $none,
    Object? triggers = $none,
    Object? mcpServers = $none,
    Object? subagents = $none,
    Object? workspaces = $none,
    Object? conversationId = $none,
    Object? sessionContinuationMode = $none,
    Object? saveDir = $none,
    Object? appDataDir = $none,
    Object? responseSchema = $none,
    Object? skillsPaths = $none,
    Object? model = $none,
    Object? models = $none,
    Object? apiKey = $none,
    Object? vertex = $none,
    Object? project = $none,
    Object? location = $none,
    Object? binaryPath = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (systemInstructions != $none)
            #systemInstructions: systemInstructions,
          if (capabilities != $none) #capabilities: capabilities,
          if (tools != $none) #tools: tools,
          if (policies != $none) #policies: policies,
          if (hooks != $none) #hooks: hooks,
          if (triggers != $none) #triggers: triggers,
          if (mcpServers != $none) #mcpServers: mcpServers,
          if (subagents != $none) #subagents: subagents,
          if (workspaces != $none) #workspaces: workspaces,
          if (conversationId != $none) #conversationId: conversationId,
          if (sessionContinuationMode != $none)
            #sessionContinuationMode: sessionContinuationMode,
          if (saveDir != $none) #saveDir: saveDir,
          if (appDataDir != $none) #appDataDir: appDataDir,
          if (responseSchema != $none) #responseSchema: responseSchema,
          if (skillsPaths != $none) #skillsPaths: skillsPaths,
          if (model != $none) #model: model,
          if (models != $none) #models: models,
          if (apiKey != $none) #apiKey: apiKey,
          if (vertex != $none) #vertex: vertex,
          if (project != $none) #project: project,
          if (location != $none) #location: location,
          if (binaryPath != $none) #binaryPath: binaryPath,
        }),
      );
  @override
  LocalAgentConfig $make(CopyWithData data) => LocalAgentConfig(
        systemInstructions: data.get(
          #systemInstructions,
          or: $value.systemInstructions,
        ),
        capabilities: data.get(#capabilities, or: $value.capabilities),
        tools: data.get(#tools, or: $value.tools),
        policies: data.get(#policies, or: $value.policies),
        hooks: data.get(#hooks, or: $value.hooks),
        triggers: data.get(#triggers, or: $value.triggers),
        mcpServers: data.get(#mcpServers, or: $value.mcpServers),
        subagents: data.get(#subagents, or: $value.subagents),
        workspaces: data.get(#workspaces, or: $value.workspaces),
        conversationId: data.get(#conversationId, or: $value.conversationId),
        sessionContinuationMode: data.get(
          #sessionContinuationMode,
          or: $value.sessionContinuationMode,
        ),
        saveDir: data.get(#saveDir, or: $value.saveDir),
        appDataDir: data.get(#appDataDir, or: $value.appDataDir),
        responseSchema: data.get(#responseSchema, or: $value.responseSchema),
        skillsPaths: data.get(#skillsPaths, or: $value.skillsPaths),
        model: data.get(#model, or: $value.model),
        models: data.get(#models, or: $value.models),
        apiKey: data.get(#apiKey, or: $value.apiKey),
        vertex: data.get(#vertex, or: $value.vertex),
        project: data.get(#project, or: $value.project),
        location: data.get(#location, or: $value.location),
        binaryPath: data.get(#binaryPath, or: $value.binaryPath),
      );

  @override
  LocalAgentConfigCopyWith<$R2, LocalAgentConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _LocalAgentConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

/// @nodoc
class LocalOpenAIAgentConfigMapper
    extends ClassMapperBase<LocalOpenAIAgentConfig> {
  LocalOpenAIAgentConfigMapper._();

  static LocalOpenAIAgentConfigMapper? _instance;
  static LocalOpenAIAgentConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LocalOpenAIAgentConfigMapper._());
      BaseLocalAgentConfigMapper.ensureInitialized();
      CapabilitiesConfigMapper.ensureInitialized();
      McpServerConfigMapper.ensureInitialized();
      SubagentConfigMapper.ensureInitialized();
      SessionContinuationModeMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'LocalOpenAIAgentConfig';

  static dynamic _$model(LocalOpenAIAgentConfig v) => v.model;
  static const Field<LocalOpenAIAgentConfig, dynamic> _f$model = Field(
    'model',
    _$model,
    opt: true,
  );
  static String? _$baseUrl(LocalOpenAIAgentConfig v) => v.baseUrl;
  static const Field<LocalOpenAIAgentConfig, String> _f$baseUrl = Field(
    'baseUrl',
    _$baseUrl,
    opt: true,
  );
  static dynamic _$systemInstructions(LocalOpenAIAgentConfig v) =>
      v.systemInstructions;
  static const Field<LocalOpenAIAgentConfig, dynamic> _f$systemInstructions =
      Field('systemInstructions', _$systemInstructions, opt: true);
  static CapabilitiesConfig _$capabilities(LocalOpenAIAgentConfig v) =>
      v.capabilities;
  static const Field<LocalOpenAIAgentConfig, CapabilitiesConfig>
      _f$capabilities = Field('capabilities', _$capabilities, opt: true);
  static List<Tool> _$tools(LocalOpenAIAgentConfig v) => v.tools;
  static const Field<LocalOpenAIAgentConfig, List<Tool>> _f$tools = Field(
    'tools',
    _$tools,
    opt: true,
  );
  static List<Policy> _$policies(LocalOpenAIAgentConfig v) => v.policies;
  static dynamic _arg$policies(f) => f<List<Policy>>();
  static const Field<LocalOpenAIAgentConfig, List<dynamic>> _f$policies = Field(
    'policies',
    _$policies,
    opt: true,
    arg: _arg$policies,
  );
  static List<Hook> _$hooks(LocalOpenAIAgentConfig v) => v.hooks;
  static const Field<LocalOpenAIAgentConfig, List<Hook>> _f$hooks = Field(
    'hooks',
    _$hooks,
    opt: true,
  );
  static List<FutureOr<void> Function(TriggerContext)> _$triggers(
    LocalOpenAIAgentConfig v,
  ) =>
      v.triggers;
  static const Field<LocalOpenAIAgentConfig,
          List<FutureOr<void> Function(TriggerContext)>> _f$triggers =
      Field('triggers', _$triggers, opt: true);
  static List<McpServerConfig> _$mcpServers(LocalOpenAIAgentConfig v) =>
      v.mcpServers;
  static const Field<LocalOpenAIAgentConfig, List<McpServerConfig>>
      _f$mcpServers = Field('mcpServers', _$mcpServers, opt: true);
  static List<SubagentConfig> _$subagents(LocalOpenAIAgentConfig v) =>
      v.subagents;
  static const Field<LocalOpenAIAgentConfig, List<SubagentConfig>>
      _f$subagents = Field('subagents', _$subagents, opt: true);
  static List<String> _$workspaces(LocalOpenAIAgentConfig v) => v.workspaces;
  static const Field<LocalOpenAIAgentConfig, List<String>> _f$workspaces =
      Field('workspaces', _$workspaces, opt: true);
  static String? _$conversationId(LocalOpenAIAgentConfig v) => v.conversationId;
  static const Field<LocalOpenAIAgentConfig, String> _f$conversationId = Field(
    'conversationId',
    _$conversationId,
    opt: true,
  );
  static SessionContinuationMode? _$sessionContinuationMode(
    LocalOpenAIAgentConfig v,
  ) =>
      v.sessionContinuationMode;
  static const Field<LocalOpenAIAgentConfig, SessionContinuationMode>
      _f$sessionContinuationMode = Field(
    'sessionContinuationMode',
    _$sessionContinuationMode,
    opt: true,
  );
  static String? _$saveDir(LocalOpenAIAgentConfig v) => v.saveDir;
  static const Field<LocalOpenAIAgentConfig, String> _f$saveDir = Field(
    'saveDir',
    _$saveDir,
    opt: true,
  );
  static String? _$appDataDir(LocalOpenAIAgentConfig v) => v.appDataDir;
  static const Field<LocalOpenAIAgentConfig, String> _f$appDataDir = Field(
    'appDataDir',
    _$appDataDir,
    opt: true,
  );
  static dynamic _$responseSchema(LocalOpenAIAgentConfig v) => v.responseSchema;
  static const Field<LocalOpenAIAgentConfig, dynamic> _f$responseSchema = Field(
    'responseSchema',
    _$responseSchema,
    opt: true,
  );
  static List<String> _$skillsPaths(LocalOpenAIAgentConfig v) => v.skillsPaths;
  static const Field<LocalOpenAIAgentConfig, List<String>> _f$skillsPaths =
      Field('skillsPaths', _$skillsPaths, opt: true);

  @override
  final MappableFields<LocalOpenAIAgentConfig> fields = const {
    #model: _f$model,
    #baseUrl: _f$baseUrl,
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
  };

  static LocalOpenAIAgentConfig _instantiate(DecodingData data) {
    return LocalOpenAIAgentConfig(
      model: data.dec(_f$model),
      baseUrl: data.dec(_f$baseUrl),
      systemInstructions: data.dec(_f$systemInstructions),
      capabilities: data.dec(_f$capabilities),
      tools: data.dec(_f$tools),
      policies: data.dec(_f$policies),
      hooks: data.dec(_f$hooks),
      triggers: data.dec(_f$triggers),
      mcpServers: data.dec(_f$mcpServers),
      subagents: data.dec(_f$subagents),
      workspaces: data.dec(_f$workspaces),
      conversationId: data.dec(_f$conversationId),
      sessionContinuationMode: data.dec(_f$sessionContinuationMode),
      saveDir: data.dec(_f$saveDir),
      appDataDir: data.dec(_f$appDataDir),
      responseSchema: data.dec(_f$responseSchema),
      skillsPaths: data.dec(_f$skillsPaths),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static LocalOpenAIAgentConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LocalOpenAIAgentConfig>(map);
  }

  static LocalOpenAIAgentConfig fromJson(String json) {
    return ensureInitialized().decodeJson<LocalOpenAIAgentConfig>(json);
  }
}

/// @nodoc
mixin LocalOpenAIAgentConfigMappable {
  String toJson() {
    return LocalOpenAIAgentConfigMapper.ensureInitialized()
        .encodeJson<LocalOpenAIAgentConfig>(this as LocalOpenAIAgentConfig);
  }

  Map<String, dynamic> toMap() {
    return LocalOpenAIAgentConfigMapper.ensureInitialized()
        .encodeMap<LocalOpenAIAgentConfig>(this as LocalOpenAIAgentConfig);
  }

  LocalOpenAIAgentConfigCopyWith<LocalOpenAIAgentConfig, LocalOpenAIAgentConfig,
          LocalOpenAIAgentConfig>
      get copyWith => _LocalOpenAIAgentConfigCopyWithImpl<
              LocalOpenAIAgentConfig, LocalOpenAIAgentConfig>(
          this as LocalOpenAIAgentConfig, $identity, $identity);
  @override
  String toString() {
    return LocalOpenAIAgentConfigMapper.ensureInitialized().stringifyValue(
      this as LocalOpenAIAgentConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return LocalOpenAIAgentConfigMapper.ensureInitialized().equalsValue(
      this as LocalOpenAIAgentConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return LocalOpenAIAgentConfigMapper.ensureInitialized().hashValue(
      this as LocalOpenAIAgentConfig,
    );
  }
}

/// @nodoc
extension LocalOpenAIAgentConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, LocalOpenAIAgentConfig, $Out> {
  LocalOpenAIAgentConfigCopyWith<$R, LocalOpenAIAgentConfig, $Out>
      get $asLocalOpenAIAgentConfig => $base.as(
            (v, t, t2) =>
                _LocalOpenAIAgentConfigCopyWithImpl<$R, $Out>(v, t, t2),
          );
}

/// @nodoc
abstract class LocalOpenAIAgentConfigCopyWith<
    $R,
    $In extends LocalOpenAIAgentConfig,
    $Out> implements BaseLocalAgentConfigCopyWith<$R, $In, $Out> {
  @override
  CapabilitiesConfigCopyWith<$R, CapabilitiesConfig, CapabilitiesConfig>
      get capabilities;
  @override
  ListCopyWith<$R, Tool, ObjectCopyWith<$R, Tool, Tool>> get tools;
  @override
  ListCopyWith<$R, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?> get policies;
  @override
  ListCopyWith<$R, Hook, ObjectCopyWith<$R, Hook, Hook>> get hooks;
  @override
  ListCopyWith<
      $R,
      FutureOr<void> Function(TriggerContext),
      ObjectCopyWith<$R, FutureOr<void> Function(TriggerContext),
          FutureOr<void> Function(TriggerContext)>> get triggers;
  @override
  ListCopyWith<$R, McpServerConfig,
          McpServerConfigCopyWith<$R, McpServerConfig, McpServerConfig>>
      get mcpServers;
  @override
  ListCopyWith<$R, SubagentConfig,
      SubagentConfigCopyWith<$R, SubagentConfig, SubagentConfig>> get subagents;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get workspaces;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get skillsPaths;
  @override
  $R call({
    dynamic model,
    String? baseUrl,
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
  });
  LocalOpenAIAgentConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

/// @nodoc
class _LocalOpenAIAgentConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LocalOpenAIAgentConfig, $Out>
    implements
        LocalOpenAIAgentConfigCopyWith<$R, LocalOpenAIAgentConfig, $Out> {
  _LocalOpenAIAgentConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LocalOpenAIAgentConfig> $mapper =
      LocalOpenAIAgentConfigMapper.ensureInitialized();
  @override
  CapabilitiesConfigCopyWith<$R, CapabilitiesConfig, CapabilitiesConfig>
      get capabilities => ($value.capabilities as CapabilitiesConfig)
          .copyWith
          .$chain((v) => call(capabilities: v));
  @override
  ListCopyWith<$R, Tool, ObjectCopyWith<$R, Tool, Tool>> get tools =>
      ListCopyWith(
        $value.tools,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(tools: v),
      );
  @override
  ListCopyWith<$R, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
      get policies => ListCopyWith(
            $value.policies,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(policies: v),
          );
  @override
  ListCopyWith<$R, Hook, ObjectCopyWith<$R, Hook, Hook>> get hooks =>
      ListCopyWith(
        $value.hooks,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(hooks: v),
      );
  @override
  ListCopyWith<
      $R,
      FutureOr<void> Function(TriggerContext),
      ObjectCopyWith<$R, FutureOr<void> Function(TriggerContext),
          FutureOr<void> Function(TriggerContext)>> get triggers =>
      ListCopyWith(
        $value.triggers,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(triggers: v),
      );
  @override
  ListCopyWith<$R, McpServerConfig,
          McpServerConfigCopyWith<$R, McpServerConfig, McpServerConfig>>
      get mcpServers => ListCopyWith(
            $value.mcpServers,
            (v, t) => v.copyWith.$chain(t),
            (v) => call(mcpServers: v),
          );
  @override
  ListCopyWith<$R, SubagentConfig,
          SubagentConfigCopyWith<$R, SubagentConfig, SubagentConfig>>
      get subagents => ListCopyWith(
            $value.subagents,
            (v, t) => v.copyWith.$chain(t),
            (v) => call(subagents: v),
          );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get workspaces =>
      ListCopyWith(
        $value.workspaces,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(workspaces: v),
      );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get skillsPaths => ListCopyWith(
            $value.skillsPaths,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(skillsPaths: v),
          );
  @override
  $R call({
    Object? model = $none,
    Object? baseUrl = $none,
    Object? systemInstructions = $none,
    Object? capabilities = $none,
    Object? tools = $none,
    Object? policies = $none,
    Object? hooks = $none,
    Object? triggers = $none,
    Object? mcpServers = $none,
    Object? subagents = $none,
    Object? workspaces = $none,
    Object? conversationId = $none,
    Object? sessionContinuationMode = $none,
    Object? saveDir = $none,
    Object? appDataDir = $none,
    Object? responseSchema = $none,
    Object? skillsPaths = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (model != $none) #model: model,
          if (baseUrl != $none) #baseUrl: baseUrl,
          if (systemInstructions != $none)
            #systemInstructions: systemInstructions,
          if (capabilities != $none) #capabilities: capabilities,
          if (tools != $none) #tools: tools,
          if (policies != $none) #policies: policies,
          if (hooks != $none) #hooks: hooks,
          if (triggers != $none) #triggers: triggers,
          if (mcpServers != $none) #mcpServers: mcpServers,
          if (subagents != $none) #subagents: subagents,
          if (workspaces != $none) #workspaces: workspaces,
          if (conversationId != $none) #conversationId: conversationId,
          if (sessionContinuationMode != $none)
            #sessionContinuationMode: sessionContinuationMode,
          if (saveDir != $none) #saveDir: saveDir,
          if (appDataDir != $none) #appDataDir: appDataDir,
          if (responseSchema != $none) #responseSchema: responseSchema,
          if (skillsPaths != $none) #skillsPaths: skillsPaths,
        }),
      );
  @override
  LocalOpenAIAgentConfig $make(CopyWithData data) => LocalOpenAIAgentConfig(
        model: data.get(#model, or: $value.model),
        baseUrl: data.get(#baseUrl, or: $value.baseUrl),
        systemInstructions: data.get(
          #systemInstructions,
          or: $value.systemInstructions,
        ),
        capabilities: data.get(#capabilities, or: $value.capabilities),
        tools: data.get(#tools, or: $value.tools),
        policies: data.get(#policies, or: $value.policies),
        hooks: data.get(#hooks, or: $value.hooks),
        triggers: data.get(#triggers, or: $value.triggers),
        mcpServers: data.get(#mcpServers, or: $value.mcpServers),
        subagents: data.get(#subagents, or: $value.subagents),
        workspaces: data.get(#workspaces, or: $value.workspaces),
        conversationId: data.get(#conversationId, or: $value.conversationId),
        sessionContinuationMode: data.get(
          #sessionContinuationMode,
          or: $value.sessionContinuationMode,
        ),
        saveDir: data.get(#saveDir, or: $value.saveDir),
        appDataDir: data.get(#appDataDir, or: $value.appDataDir),
        responseSchema: data.get(#responseSchema, or: $value.responseSchema),
        skillsPaths: data.get(#skillsPaths, or: $value.skillsPaths),
      );

  @override
  LocalOpenAIAgentConfigCopyWith<$R2, LocalOpenAIAgentConfig, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _LocalOpenAIAgentConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

/// @nodoc
class LiteRTAgentConfigMapper extends ClassMapperBase<LiteRTAgentConfig> {
  LiteRTAgentConfigMapper._();

  static LiteRTAgentConfigMapper? _instance;
  static LiteRTAgentConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LiteRTAgentConfigMapper._());
      BaseLocalAgentConfigMapper.ensureInitialized();
      LiteRTBackendMapper.ensureInitialized();
      CapabilitiesConfigMapper.ensureInitialized();
      McpServerConfigMapper.ensureInitialized();
      SubagentConfigMapper.ensureInitialized();
      SessionContinuationModeMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'LiteRTAgentConfig';

  static String _$modelPath(LiteRTAgentConfig v) => v.modelPath;
  static const Field<LiteRTAgentConfig, String> _f$modelPath = Field(
    'modelPath',
    _$modelPath,
  );
  static LiteRTBackend _$backend(LiteRTAgentConfig v) => v.backend;
  static const Field<LiteRTAgentConfig, LiteRTBackend> _f$backend = Field(
    'backend',
    _$backend,
    opt: true,
    def: LiteRTBackend.gpu,
  );
  static bool _$enableSpeculativeDecoding(LiteRTAgentConfig v) =>
      v.enableSpeculativeDecoding;
  static const Field<LiteRTAgentConfig, bool> _f$enableSpeculativeDecoding =
      Field(
    'enableSpeculativeDecoding',
    _$enableSpeculativeDecoding,
    opt: true,
    def: false,
  );
  static String? _$cacheDir(LiteRTAgentConfig v) => v.cacheDir;
  static const Field<LiteRTAgentConfig, String> _f$cacheDir = Field(
    'cacheDir',
    _$cacheDir,
    opt: true,
  );
  static LiteRTBackend? _$audioBackend(LiteRTAgentConfig v) => v.audioBackend;
  static const Field<LiteRTAgentConfig, LiteRTBackend> _f$audioBackend = Field(
    'audioBackend',
    _$audioBackend,
    opt: true,
  );
  static LiteRTBackend? _$visionBackend(LiteRTAgentConfig v) => v.visionBackend;
  static const Field<LiteRTAgentConfig, LiteRTBackend> _f$visionBackend = Field(
    'visionBackend',
    _$visionBackend,
    opt: true,
  );
  static int _$port(LiteRTAgentConfig v) => v.port;
  static const Field<LiteRTAgentConfig, int> _f$port = Field(
    'port',
    _$port,
    opt: true,
    def: 0,
  );
  static bool _$downloadIfMissing(LiteRTAgentConfig v) => v.downloadIfMissing;
  static const Field<LiteRTAgentConfig, bool> _f$downloadIfMissing = Field(
    'downloadIfMissing',
    _$downloadIfMissing,
    opt: true,
    def: false,
  );
  static int? _$maxContextTokens(LiteRTAgentConfig v) => v.maxContextTokens;
  static const Field<LiteRTAgentConfig, int> _f$maxContextTokens = Field(
    'maxContextTokens',
    _$maxContextTokens,
    opt: true,
  );
  static dynamic _$systemInstructions(LiteRTAgentConfig v) =>
      v.systemInstructions;
  static const Field<LiteRTAgentConfig, dynamic> _f$systemInstructions = Field(
    'systemInstructions',
    _$systemInstructions,
    opt: true,
  );
  static CapabilitiesConfig _$capabilities(LiteRTAgentConfig v) =>
      v.capabilities;
  static const Field<LiteRTAgentConfig, CapabilitiesConfig> _f$capabilities =
      Field('capabilities', _$capabilities, opt: true);
  static List<Tool> _$tools(LiteRTAgentConfig v) => v.tools;
  static const Field<LiteRTAgentConfig, List<Tool>> _f$tools = Field(
    'tools',
    _$tools,
    opt: true,
  );
  static List<Policy> _$policies(LiteRTAgentConfig v) => v.policies;
  static dynamic _arg$policies(f) => f<List<Policy>>();
  static const Field<LiteRTAgentConfig, List<dynamic>> _f$policies = Field(
    'policies',
    _$policies,
    opt: true,
    arg: _arg$policies,
  );
  static List<Hook> _$hooks(LiteRTAgentConfig v) => v.hooks;
  static const Field<LiteRTAgentConfig, List<Hook>> _f$hooks = Field(
    'hooks',
    _$hooks,
    opt: true,
  );
  static List<FutureOr<void> Function(TriggerContext)> _$triggers(
    LiteRTAgentConfig v,
  ) =>
      v.triggers;
  static const Field<LiteRTAgentConfig,
          List<FutureOr<void> Function(TriggerContext)>> _f$triggers =
      Field('triggers', _$triggers, opt: true);
  static List<McpServerConfig> _$mcpServers(LiteRTAgentConfig v) =>
      v.mcpServers;
  static const Field<LiteRTAgentConfig, List<McpServerConfig>> _f$mcpServers =
      Field('mcpServers', _$mcpServers, opt: true);
  static List<SubagentConfig> _$subagents(LiteRTAgentConfig v) => v.subagents;
  static const Field<LiteRTAgentConfig, List<SubagentConfig>> _f$subagents =
      Field('subagents', _$subagents, opt: true);
  static List<String> _$workspaces(LiteRTAgentConfig v) => v.workspaces;
  static const Field<LiteRTAgentConfig, List<String>> _f$workspaces = Field(
    'workspaces',
    _$workspaces,
    opt: true,
  );
  static String? _$conversationId(LiteRTAgentConfig v) => v.conversationId;
  static const Field<LiteRTAgentConfig, String> _f$conversationId = Field(
    'conversationId',
    _$conversationId,
    opt: true,
  );
  static SessionContinuationMode? _$sessionContinuationMode(
    LiteRTAgentConfig v,
  ) =>
      v.sessionContinuationMode;
  static const Field<LiteRTAgentConfig, SessionContinuationMode>
      _f$sessionContinuationMode = Field(
    'sessionContinuationMode',
    _$sessionContinuationMode,
    opt: true,
  );
  static String? _$saveDir(LiteRTAgentConfig v) => v.saveDir;
  static const Field<LiteRTAgentConfig, String> _f$saveDir = Field(
    'saveDir',
    _$saveDir,
    opt: true,
  );
  static String? _$appDataDir(LiteRTAgentConfig v) => v.appDataDir;
  static const Field<LiteRTAgentConfig, String> _f$appDataDir = Field(
    'appDataDir',
    _$appDataDir,
    opt: true,
  );
  static dynamic _$responseSchema(LiteRTAgentConfig v) => v.responseSchema;
  static const Field<LiteRTAgentConfig, dynamic> _f$responseSchema = Field(
    'responseSchema',
    _$responseSchema,
    opt: true,
  );
  static List<String> _$skillsPaths(LiteRTAgentConfig v) => v.skillsPaths;
  static const Field<LiteRTAgentConfig, List<String>> _f$skillsPaths = Field(
    'skillsPaths',
    _$skillsPaths,
    opt: true,
  );

  @override
  final MappableFields<LiteRTAgentConfig> fields = const {
    #modelPath: _f$modelPath,
    #backend: _f$backend,
    #enableSpeculativeDecoding: _f$enableSpeculativeDecoding,
    #cacheDir: _f$cacheDir,
    #audioBackend: _f$audioBackend,
    #visionBackend: _f$visionBackend,
    #port: _f$port,
    #downloadIfMissing: _f$downloadIfMissing,
    #maxContextTokens: _f$maxContextTokens,
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
  };

  static LiteRTAgentConfig _instantiate(DecodingData data) {
    return LiteRTAgentConfig(
      modelPath: data.dec(_f$modelPath),
      backend: data.dec(_f$backend),
      enableSpeculativeDecoding: data.dec(_f$enableSpeculativeDecoding),
      cacheDir: data.dec(_f$cacheDir),
      audioBackend: data.dec(_f$audioBackend),
      visionBackend: data.dec(_f$visionBackend),
      port: data.dec(_f$port),
      downloadIfMissing: data.dec(_f$downloadIfMissing),
      maxContextTokens: data.dec(_f$maxContextTokens),
      systemInstructions: data.dec(_f$systemInstructions),
      capabilities: data.dec(_f$capabilities),
      tools: data.dec(_f$tools),
      policies: data.dec(_f$policies),
      hooks: data.dec(_f$hooks),
      triggers: data.dec(_f$triggers),
      mcpServers: data.dec(_f$mcpServers),
      subagents: data.dec(_f$subagents),
      workspaces: data.dec(_f$workspaces),
      conversationId: data.dec(_f$conversationId),
      sessionContinuationMode: data.dec(_f$sessionContinuationMode),
      saveDir: data.dec(_f$saveDir),
      appDataDir: data.dec(_f$appDataDir),
      responseSchema: data.dec(_f$responseSchema),
      skillsPaths: data.dec(_f$skillsPaths),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static LiteRTAgentConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LiteRTAgentConfig>(map);
  }

  static LiteRTAgentConfig fromJson(String json) {
    return ensureInitialized().decodeJson<LiteRTAgentConfig>(json);
  }
}

/// @nodoc
mixin LiteRTAgentConfigMappable {
  String toJson() {
    return LiteRTAgentConfigMapper.ensureInitialized()
        .encodeJson<LiteRTAgentConfig>(this as LiteRTAgentConfig);
  }

  Map<String, dynamic> toMap() {
    return LiteRTAgentConfigMapper.ensureInitialized()
        .encodeMap<LiteRTAgentConfig>(this as LiteRTAgentConfig);
  }

  LiteRTAgentConfigCopyWith<LiteRTAgentConfig, LiteRTAgentConfig,
          LiteRTAgentConfig>
      get copyWith =>
          _LiteRTAgentConfigCopyWithImpl<LiteRTAgentConfig, LiteRTAgentConfig>(
            this as LiteRTAgentConfig,
            $identity,
            $identity,
          );
  @override
  String toString() {
    return LiteRTAgentConfigMapper.ensureInitialized().stringifyValue(
      this as LiteRTAgentConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return LiteRTAgentConfigMapper.ensureInitialized().equalsValue(
      this as LiteRTAgentConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return LiteRTAgentConfigMapper.ensureInitialized().hashValue(
      this as LiteRTAgentConfig,
    );
  }
}

/// @nodoc
extension LiteRTAgentConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, LiteRTAgentConfig, $Out> {
  LiteRTAgentConfigCopyWith<$R, LiteRTAgentConfig, $Out>
      get $asLiteRTAgentConfig => $base.as(
            (v, t, t2) => _LiteRTAgentConfigCopyWithImpl<$R, $Out>(v, t, t2),
          );
}

/// @nodoc
abstract class LiteRTAgentConfigCopyWith<$R, $In extends LiteRTAgentConfig,
    $Out> implements BaseLocalAgentConfigCopyWith<$R, $In, $Out> {
  @override
  CapabilitiesConfigCopyWith<$R, CapabilitiesConfig, CapabilitiesConfig>
      get capabilities;
  @override
  ListCopyWith<$R, Tool, ObjectCopyWith<$R, Tool, Tool>> get tools;
  @override
  ListCopyWith<$R, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?> get policies;
  @override
  ListCopyWith<$R, Hook, ObjectCopyWith<$R, Hook, Hook>> get hooks;
  @override
  ListCopyWith<
      $R,
      FutureOr<void> Function(TriggerContext),
      ObjectCopyWith<$R, FutureOr<void> Function(TriggerContext),
          FutureOr<void> Function(TriggerContext)>> get triggers;
  @override
  ListCopyWith<$R, McpServerConfig,
          McpServerConfigCopyWith<$R, McpServerConfig, McpServerConfig>>
      get mcpServers;
  @override
  ListCopyWith<$R, SubagentConfig,
      SubagentConfigCopyWith<$R, SubagentConfig, SubagentConfig>> get subagents;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get workspaces;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get skillsPaths;
  @override
  $R call({
    String? modelPath,
    LiteRTBackend? backend,
    bool? enableSpeculativeDecoding,
    String? cacheDir,
    LiteRTBackend? audioBackend,
    LiteRTBackend? visionBackend,
    int? port,
    bool? downloadIfMissing,
    int? maxContextTokens,
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
  });
  LiteRTAgentConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

/// @nodoc
class _LiteRTAgentConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LiteRTAgentConfig, $Out>
    implements LiteRTAgentConfigCopyWith<$R, LiteRTAgentConfig, $Out> {
  _LiteRTAgentConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LiteRTAgentConfig> $mapper =
      LiteRTAgentConfigMapper.ensureInitialized();
  @override
  CapabilitiesConfigCopyWith<$R, CapabilitiesConfig, CapabilitiesConfig>
      get capabilities => ($value.capabilities as CapabilitiesConfig)
          .copyWith
          .$chain((v) => call(capabilities: v));
  @override
  ListCopyWith<$R, Tool, ObjectCopyWith<$R, Tool, Tool>> get tools =>
      ListCopyWith(
        $value.tools,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(tools: v),
      );
  @override
  ListCopyWith<$R, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
      get policies => ListCopyWith(
            $value.policies,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(policies: v),
          );
  @override
  ListCopyWith<$R, Hook, ObjectCopyWith<$R, Hook, Hook>> get hooks =>
      ListCopyWith(
        $value.hooks,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(hooks: v),
      );
  @override
  ListCopyWith<
      $R,
      FutureOr<void> Function(TriggerContext),
      ObjectCopyWith<$R, FutureOr<void> Function(TriggerContext),
          FutureOr<void> Function(TriggerContext)>> get triggers =>
      ListCopyWith(
        $value.triggers,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(triggers: v),
      );
  @override
  ListCopyWith<$R, McpServerConfig,
          McpServerConfigCopyWith<$R, McpServerConfig, McpServerConfig>>
      get mcpServers => ListCopyWith(
            $value.mcpServers,
            (v, t) => v.copyWith.$chain(t),
            (v) => call(mcpServers: v),
          );
  @override
  ListCopyWith<$R, SubagentConfig,
          SubagentConfigCopyWith<$R, SubagentConfig, SubagentConfig>>
      get subagents => ListCopyWith(
            $value.subagents,
            (v, t) => v.copyWith.$chain(t),
            (v) => call(subagents: v),
          );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get workspaces =>
      ListCopyWith(
        $value.workspaces,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(workspaces: v),
      );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
      get skillsPaths => ListCopyWith(
            $value.skillsPaths,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(skillsPaths: v),
          );
  @override
  $R call({
    String? modelPath,
    LiteRTBackend? backend,
    bool? enableSpeculativeDecoding,
    Object? cacheDir = $none,
    Object? audioBackend = $none,
    Object? visionBackend = $none,
    int? port,
    bool? downloadIfMissing,
    Object? maxContextTokens = $none,
    Object? systemInstructions = $none,
    Object? capabilities = $none,
    Object? tools = $none,
    Object? policies = $none,
    Object? hooks = $none,
    Object? triggers = $none,
    Object? mcpServers = $none,
    Object? subagents = $none,
    Object? workspaces = $none,
    Object? conversationId = $none,
    Object? sessionContinuationMode = $none,
    Object? saveDir = $none,
    Object? appDataDir = $none,
    Object? responseSchema = $none,
    Object? skillsPaths = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (modelPath != null) #modelPath: modelPath,
          if (backend != null) #backend: backend,
          if (enableSpeculativeDecoding != null)
            #enableSpeculativeDecoding: enableSpeculativeDecoding,
          if (cacheDir != $none) #cacheDir: cacheDir,
          if (audioBackend != $none) #audioBackend: audioBackend,
          if (visionBackend != $none) #visionBackend: visionBackend,
          if (port != null) #port: port,
          if (downloadIfMissing != null) #downloadIfMissing: downloadIfMissing,
          if (maxContextTokens != $none) #maxContextTokens: maxContextTokens,
          if (systemInstructions != $none)
            #systemInstructions: systemInstructions,
          if (capabilities != $none) #capabilities: capabilities,
          if (tools != $none) #tools: tools,
          if (policies != $none) #policies: policies,
          if (hooks != $none) #hooks: hooks,
          if (triggers != $none) #triggers: triggers,
          if (mcpServers != $none) #mcpServers: mcpServers,
          if (subagents != $none) #subagents: subagents,
          if (workspaces != $none) #workspaces: workspaces,
          if (conversationId != $none) #conversationId: conversationId,
          if (sessionContinuationMode != $none)
            #sessionContinuationMode: sessionContinuationMode,
          if (saveDir != $none) #saveDir: saveDir,
          if (appDataDir != $none) #appDataDir: appDataDir,
          if (responseSchema != $none) #responseSchema: responseSchema,
          if (skillsPaths != $none) #skillsPaths: skillsPaths,
        }),
      );
  @override
  LiteRTAgentConfig $make(CopyWithData data) => LiteRTAgentConfig(
        modelPath: data.get(#modelPath, or: $value.modelPath),
        backend: data.get(#backend, or: $value.backend),
        enableSpeculativeDecoding: data.get(
          #enableSpeculativeDecoding,
          or: $value.enableSpeculativeDecoding,
        ),
        cacheDir: data.get(#cacheDir, or: $value.cacheDir),
        audioBackend: data.get(#audioBackend, or: $value.audioBackend),
        visionBackend: data.get(#visionBackend, or: $value.visionBackend),
        port: data.get(#port, or: $value.port),
        downloadIfMissing: data.get(
          #downloadIfMissing,
          or: $value.downloadIfMissing,
        ),
        maxContextTokens:
            data.get(#maxContextTokens, or: $value.maxContextTokens),
        systemInstructions: data.get(
          #systemInstructions,
          or: $value.systemInstructions,
        ),
        capabilities: data.get(#capabilities, or: $value.capabilities),
        tools: data.get(#tools, or: $value.tools),
        policies: data.get(#policies, or: $value.policies),
        hooks: data.get(#hooks, or: $value.hooks),
        triggers: data.get(#triggers, or: $value.triggers),
        mcpServers: data.get(#mcpServers, or: $value.mcpServers),
        subagents: data.get(#subagents, or: $value.subagents),
        workspaces: data.get(#workspaces, or: $value.workspaces),
        conversationId: data.get(#conversationId, or: $value.conversationId),
        sessionContinuationMode: data.get(
          #sessionContinuationMode,
          or: $value.sessionContinuationMode,
        ),
        saveDir: data.get(#saveDir, or: $value.saveDir),
        appDataDir: data.get(#appDataDir, or: $value.appDataDir),
        responseSchema: data.get(#responseSchema, or: $value.responseSchema),
        skillsPaths: data.get(#skillsPaths, or: $value.skillsPaths),
      );

  @override
  LiteRTAgentConfigCopyWith<$R2, LiteRTAgentConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _LiteRTAgentConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
