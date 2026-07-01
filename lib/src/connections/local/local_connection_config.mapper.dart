// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'local_connection_config.dart';

class LocalAgentConfigMapper extends ClassMapperBase<LocalAgentConfig> {
  LocalAgentConfigMapper._();

  static LocalAgentConfigMapper? _instance;
  static LocalAgentConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LocalAgentConfigMapper._());
      AgentConfigMapper.ensureInitialized();
      MapperContainer.globals.useAll([
        ToolMapper(),
        PolicyMapper(),
        HookMapper(),
        TriggerMapper(),
      ]);
      CapabilitiesConfigMapper.ensureInitialized();
      McpServerConfigMapper.ensureInitialized();
      SubagentConfigMapper.ensureInitialized();
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
  ) => v.triggers;
  static const Field<
    LocalAgentConfig,
    List<FutureOr<void> Function(TriggerContext)>
  >
  _f$triggers = Field('triggers', _$triggers, opt: true);
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
    def: false,
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

extension LocalAgentConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, LocalAgentConfig, $Out> {
  LocalAgentConfigCopyWith<$R, LocalAgentConfig, $Out>
  get $asLocalAgentConfig =>
      $base.as((v, t, t2) => _LocalAgentConfigCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class LocalAgentConfigCopyWith<$R, $In extends LocalAgentConfig, $Out>
    implements AgentConfigCopyWith<$R, $In, $Out> {
  CapabilitiesConfigCopyWith<$R, CapabilitiesConfig, CapabilitiesConfig>
  get capabilities;
  ListCopyWith<$R, Tool, ObjectCopyWith<$R, Tool, Tool>> get tools;
  @override
  ListCopyWith<$R, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?> get policies;
  ListCopyWith<$R, Hook, ObjectCopyWith<$R, Hook, Hook>> get hooks;
  ListCopyWith<
    $R,
    FutureOr<void> Function(TriggerContext),
    ObjectCopyWith<
      $R,
      FutureOr<void> Function(TriggerContext),
      FutureOr<void> Function(TriggerContext)
    >
  >
  get triggers;
  ListCopyWith<
    $R,
    McpServerConfig,
    McpServerConfigCopyWith<$R, McpServerConfig, McpServerConfig>
  >
  get mcpServers;
  ListCopyWith<
    $R,
    SubagentConfig,
    SubagentConfigCopyWith<$R, SubagentConfig, SubagentConfig>
  >
  get subagents;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get workspaces;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get skillsPaths;
  ListCopyWith<
    $R,
    ModelTarget,
    ModelTargetCopyWith<$R, ModelTarget, ModelTarget>
  >?
  get models;
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

class _LocalAgentConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LocalAgentConfig, $Out>
    implements LocalAgentConfigCopyWith<$R, LocalAgentConfig, $Out> {
  _LocalAgentConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LocalAgentConfig> $mapper =
      LocalAgentConfigMapper.ensureInitialized();
  @override
  CapabilitiesConfigCopyWith<$R, CapabilitiesConfig, CapabilitiesConfig>
  get capabilities => ($value.capabilities as CapabilitiesConfig).copyWith
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
    ObjectCopyWith<
      $R,
      FutureOr<void> Function(TriggerContext),
      FutureOr<void> Function(TriggerContext)
    >
  >
  get triggers => ListCopyWith(
    $value.triggers,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(triggers: v),
  );
  @override
  ListCopyWith<
    $R,
    McpServerConfig,
    McpServerConfigCopyWith<$R, McpServerConfig, McpServerConfig>
  >
  get mcpServers => ListCopyWith(
    $value.mcpServers,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(mcpServers: v),
  );
  @override
  ListCopyWith<
    $R,
    SubagentConfig,
    SubagentConfigCopyWith<$R, SubagentConfig, SubagentConfig>
  >
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
  ListCopyWith<
    $R,
    ModelTarget,
    ModelTargetCopyWith<$R, ModelTarget, ModelTarget>
  >?
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
    Object? saveDir = $none,
    Object? appDataDir = $none,
    Object? responseSchema = $none,
    Object? skillsPaths = $none,
    Object? model = $none,
    Object? models = $none,
    Object? apiKey = $none,
    bool? vertex,
    Object? project = $none,
    Object? location = $none,
    Object? binaryPath = $none,
  }) => $apply(
    FieldCopyWithData({
      if (systemInstructions != $none) #systemInstructions: systemInstructions,
      if (capabilities != $none) #capabilities: capabilities,
      if (tools != $none) #tools: tools,
      if (policies != $none) #policies: policies,
      if (hooks != $none) #hooks: hooks,
      if (triggers != $none) #triggers: triggers,
      if (mcpServers != $none) #mcpServers: mcpServers,
      if (subagents != $none) #subagents: subagents,
      if (workspaces != $none) #workspaces: workspaces,
      if (conversationId != $none) #conversationId: conversationId,
      if (saveDir != $none) #saveDir: saveDir,
      if (appDataDir != $none) #appDataDir: appDataDir,
      if (responseSchema != $none) #responseSchema: responseSchema,
      if (skillsPaths != $none) #skillsPaths: skillsPaths,
      if (model != $none) #model: model,
      if (models != $none) #models: models,
      if (apiKey != $none) #apiKey: apiKey,
      if (vertex != null) #vertex: vertex,
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
  ) => _LocalAgentConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

