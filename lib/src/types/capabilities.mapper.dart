// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'capabilities.dart';

/// @nodoc

class BuiltinToolsMapper extends EnumMapper<BuiltinTools> {
  BuiltinToolsMapper._();

  static BuiltinToolsMapper? _instance;
  static BuiltinToolsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = BuiltinToolsMapper._());
    }
    return _instance!;
  }

  static BuiltinTools fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  BuiltinTools decode(dynamic value) {
    switch (value) {
      case 'list_directory':
        return BuiltinTools.listDirectory;
      case 'search_directory':
        return BuiltinTools.searchDirectory;
      case 'find_file':
        return BuiltinTools.findFile;
      case 'view_file':
        return BuiltinTools.viewFile;
      case 'create_file':
        return BuiltinTools.createFile;
      case 'edit_file':
        return BuiltinTools.editFile;
      case 'run_command':
        return BuiltinTools.runCommand;
      case 'ask_question':
        return BuiltinTools.askQuestion;
      case 'start_subagent':
        return BuiltinTools.startSubagent;
      case 'generate_image':
        return BuiltinTools.generateImage;
      case 'search_web':
        return BuiltinTools.searchWeb;
      case 'read_url_content':
        return BuiltinTools.readUrlContent;
      case 'finish':
        return BuiltinTools.finish;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(BuiltinTools self) {
    switch (self) {
      case BuiltinTools.listDirectory:
        return 'list_directory';
      case BuiltinTools.searchDirectory:
        return 'search_directory';
      case BuiltinTools.findFile:
        return 'find_file';
      case BuiltinTools.viewFile:
        return 'view_file';
      case BuiltinTools.createFile:
        return 'create_file';
      case BuiltinTools.editFile:
        return 'edit_file';
      case BuiltinTools.runCommand:
        return 'run_command';
      case BuiltinTools.askQuestion:
        return 'ask_question';
      case BuiltinTools.startSubagent:
        return 'start_subagent';
      case BuiltinTools.generateImage:
        return 'generate_image';
      case BuiltinTools.searchWeb:
        return 'search_web';
      case BuiltinTools.readUrlContent:
        return 'read_url_content';
      case BuiltinTools.finish:
        return 'finish';
    }
  }
}

/// @nodoc

extension BuiltinToolsMapperExtension on BuiltinTools {
  dynamic toValue() {
    BuiltinToolsMapper.ensureInitialized();
    return MapperContainer.globals.toValue<BuiltinTools>(this);
  }
}

/// @nodoc

class AgentBehaviorMapper extends EnumMapper<AgentBehavior> {
  AgentBehaviorMapper._();

  static AgentBehaviorMapper? _instance;
  static AgentBehaviorMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AgentBehaviorMapper._());
    }
    return _instance!;
  }

  static AgentBehavior fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  AgentBehavior decode(dynamic value) {
    switch (value) {
      case r'autonomous':
        return AgentBehavior.autonomous;
      case r'interactive':
        return AgentBehavior.interactive;
      default:
        return AgentBehavior.values[0];
    }
  }

  @override
  dynamic encode(AgentBehavior self) {
    switch (self) {
      case AgentBehavior.autonomous:
        return r'autonomous';
      case AgentBehavior.interactive:
        return r'interactive';
    }
  }
}

/// @nodoc

extension AgentBehaviorMapperExtension on AgentBehavior {
  String toValue() {
    AgentBehaviorMapper.ensureInitialized();
    return MapperContainer.globals.toValue<AgentBehavior>(this) as String;
  }
}

/// @nodoc
class CapabilitiesConfigMapper extends ClassMapperBase<CapabilitiesConfig> {
  CapabilitiesConfigMapper._();

  static CapabilitiesConfigMapper? _instance;
  static CapabilitiesConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CapabilitiesConfigMapper._());
      AgentBehaviorMapper.ensureInitialized();
      BuiltinToolsMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CapabilitiesConfig';

  static bool _$enableSubagents(CapabilitiesConfig v) => v.enableSubagents;
  static const Field<CapabilitiesConfig, bool> _f$enableSubagents = Field(
    'enableSubagents',
    _$enableSubagents,
    key: r'enable_subagents',
    opt: true,
    def: true,
  );
  static AgentBehavior _$agentBehavior(CapabilitiesConfig v) => v.agentBehavior;
  static const Field<CapabilitiesConfig, AgentBehavior> _f$agentBehavior =
      Field(
    'agentBehavior',
    _$agentBehavior,
    key: r'agent_behavior',
    opt: true,
  );
  static AgentBehavior _$agentMode(CapabilitiesConfig v) => v.agentMode;
  static const Field<CapabilitiesConfig, AgentBehavior> _f$agentMode = Field(
    'agentMode',
    _$agentMode,
    key: r'agent_mode',
    opt: true,
  );
  static List<BuiltinTools>? _$enabledTools(CapabilitiesConfig v) =>
      v.enabledTools;
  static const Field<CapabilitiesConfig, List<BuiltinTools>> _f$enabledTools =
      Field('enabledTools', _$enabledTools, key: r'enabled_tools', opt: true);
  static List<BuiltinTools>? _$disabledTools(CapabilitiesConfig v) =>
      v.disabledTools;
  static const Field<CapabilitiesConfig, List<BuiltinTools>> _f$disabledTools =
      Field(
    'disabledTools',
    _$disabledTools,
    key: r'disabled_tools',
    opt: true,
  );
  static int? _$compactionThreshold(CapabilitiesConfig v) =>
      v.compactionThreshold;
  static const Field<CapabilitiesConfig, int> _f$compactionThreshold = Field(
    'compactionThreshold',
    _$compactionThreshold,
    key: r'compaction_threshold',
    opt: true,
  );
  static String? _$finishToolSchemaJson(CapabilitiesConfig v) =>
      v.finishToolSchemaJson;
  static const Field<CapabilitiesConfig, String> _f$finishToolSchemaJson =
      Field(
    'finishToolSchemaJson',
    _$finishToolSchemaJson,
    key: r'finish_tool_schema_json',
    opt: true,
  );
  static int? _$maxSubagentDepth(CapabilitiesConfig v) => v.maxSubagentDepth;
  static const Field<CapabilitiesConfig, int> _f$maxSubagentDepth = Field(
    'maxSubagentDepth',
    _$maxSubagentDepth,
    key: r'max_subagent_depth',
    opt: true,
  );
  static List<String>? _$allowedSubagents(CapabilitiesConfig v) =>
      v.allowedSubagents;
  static const Field<CapabilitiesConfig, List<String>> _f$allowedSubagents =
      Field(
    'allowedSubagents',
    _$allowedSubagents,
    key: r'allowed_subagents',
    opt: true,
  );

  @override
  final MappableFields<CapabilitiesConfig> fields = const {
    #enableSubagents: _f$enableSubagents,
    #agentBehavior: _f$agentBehavior,
    #agentMode: _f$agentMode,
    #enabledTools: _f$enabledTools,
    #disabledTools: _f$disabledTools,
    #compactionThreshold: _f$compactionThreshold,
    #finishToolSchemaJson: _f$finishToolSchemaJson,
    #maxSubagentDepth: _f$maxSubagentDepth,
    #allowedSubagents: _f$allowedSubagents,
  };
  @override
  final bool ignoreNull = true;

  static CapabilitiesConfig _instantiate(DecodingData data) {
    return CapabilitiesConfig(
      enableSubagents: data.dec(_f$enableSubagents),
      agentBehavior: data.dec(_f$agentBehavior),
      agentMode: data.dec(_f$agentMode),
      enabledTools: data.dec(_f$enabledTools),
      disabledTools: data.dec(_f$disabledTools),
      compactionThreshold: data.dec(_f$compactionThreshold),
      finishToolSchemaJson: data.dec(_f$finishToolSchemaJson),
      maxSubagentDepth: data.dec(_f$maxSubagentDepth),
      allowedSubagents: data.dec(_f$allowedSubagents),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CapabilitiesConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CapabilitiesConfig>(map);
  }

  static CapabilitiesConfig fromJson(String json) {
    return ensureInitialized().decodeJson<CapabilitiesConfig>(json);
  }
}

/// @nodoc
mixin CapabilitiesConfigMappable {
  String toJson() {
    return CapabilitiesConfigMapper.ensureInitialized()
        .encodeJson<CapabilitiesConfig>(this as CapabilitiesConfig);
  }

  Map<String, dynamic> toMap() {
    return CapabilitiesConfigMapper.ensureInitialized()
        .encodeMap<CapabilitiesConfig>(this as CapabilitiesConfig);
  }

  CapabilitiesConfigCopyWith<CapabilitiesConfig, CapabilitiesConfig,
      CapabilitiesConfig> get copyWith => _CapabilitiesConfigCopyWithImpl<
          CapabilitiesConfig, CapabilitiesConfig>(
        this as CapabilitiesConfig,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CapabilitiesConfigMapper.ensureInitialized().stringifyValue(
      this as CapabilitiesConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return CapabilitiesConfigMapper.ensureInitialized().equalsValue(
      this as CapabilitiesConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return CapabilitiesConfigMapper.ensureInitialized().hashValue(
      this as CapabilitiesConfig,
    );
  }
}

/// @nodoc
extension CapabilitiesConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CapabilitiesConfig, $Out> {
  CapabilitiesConfigCopyWith<$R, CapabilitiesConfig, $Out>
      get $asCapabilitiesConfig => $base.as(
            (v, t, t2) => _CapabilitiesConfigCopyWithImpl<$R, $Out>(v, t, t2),
          );
}

/// @nodoc
abstract class CapabilitiesConfigCopyWith<$R, $In extends CapabilitiesConfig,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, BuiltinTools,
      ObjectCopyWith<$R, BuiltinTools, BuiltinTools>>? get enabledTools;
  ListCopyWith<$R, BuiltinTools,
      ObjectCopyWith<$R, BuiltinTools, BuiltinTools>>? get disabledTools;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
      get allowedSubagents;
  $R call({
    bool? enableSubagents,
    AgentBehavior? agentBehavior,
    AgentBehavior? agentMode,
    List<BuiltinTools>? enabledTools,
    List<BuiltinTools>? disabledTools,
    int? compactionThreshold,
    String? finishToolSchemaJson,
    int? maxSubagentDepth,
    List<String>? allowedSubagents,
  });
  CapabilitiesConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

/// @nodoc
class _CapabilitiesConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CapabilitiesConfig, $Out>
    implements CapabilitiesConfigCopyWith<$R, CapabilitiesConfig, $Out> {
  _CapabilitiesConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CapabilitiesConfig> $mapper =
      CapabilitiesConfigMapper.ensureInitialized();
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
  $R call({
    bool? enableSubagents,
    Object? agentBehavior = $none,
    Object? agentMode = $none,
    Object? enabledTools = $none,
    Object? disabledTools = $none,
    Object? compactionThreshold = $none,
    Object? finishToolSchemaJson = $none,
    Object? maxSubagentDepth = $none,
    Object? allowedSubagents = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (enableSubagents != null) #enableSubagents: enableSubagents,
          if (agentBehavior != $none) #agentBehavior: agentBehavior,
          if (agentMode != $none) #agentMode: agentMode,
          if (enabledTools != $none) #enabledTools: enabledTools,
          if (disabledTools != $none) #disabledTools: disabledTools,
          if (compactionThreshold != $none)
            #compactionThreshold: compactionThreshold,
          if (finishToolSchemaJson != $none)
            #finishToolSchemaJson: finishToolSchemaJson,
          if (maxSubagentDepth != $none) #maxSubagentDepth: maxSubagentDepth,
          if (allowedSubagents != $none) #allowedSubagents: allowedSubagents,
        }),
      );
  @override
  CapabilitiesConfig $make(CopyWithData data) => CapabilitiesConfig(
        enableSubagents: data.get(#enableSubagents, or: $value.enableSubagents),
        agentBehavior: data.get(#agentBehavior, or: $value.agentBehavior),
        agentMode: data.get(#agentMode, or: $value.agentMode),
        enabledTools: data.get(#enabledTools, or: $value.enabledTools),
        disabledTools: data.get(#disabledTools, or: $value.disabledTools),
        compactionThreshold: data.get(
          #compactionThreshold,
          or: $value.compactionThreshold,
        ),
        finishToolSchemaJson: data.get(
          #finishToolSchemaJson,
          or: $value.finishToolSchemaJson,
        ),
        maxSubagentDepth:
            data.get(#maxSubagentDepth, or: $value.maxSubagentDepth),
        allowedSubagents:
            data.get(#allowedSubagents, or: $value.allowedSubagents),
      );

  @override
  CapabilitiesConfigCopyWith<$R2, CapabilitiesConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _CapabilitiesConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
