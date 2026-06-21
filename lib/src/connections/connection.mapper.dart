// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'connection.dart';

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
    #saveDir: _f$saveDir,
    #appDataDir: _f$appDataDir,
    #responseSchema: _f$responseSchema,
    #skillsPaths: _f$skillsPaths,
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

mixin AgentConfigMappable {
  String toJson();
  Map<String, dynamic> toMap();
  AgentConfigCopyWith<AgentConfig, AgentConfig, AgentConfig> get copyWith;
}

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
  });
  AgentConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}
