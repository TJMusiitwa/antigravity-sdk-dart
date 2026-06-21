// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'capabilities.dart';

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
      case BuiltinTools.finish:
        return 'finish';
    }
  }
}

extension BuiltinToolsMapperExtension on BuiltinTools {
  dynamic toValue() {
    BuiltinToolsMapper.ensureInitialized();
    return MapperContainer.globals.toValue<BuiltinTools>(this);
  }
}

class CapabilitiesConfigMapper extends ClassMapperBase<CapabilitiesConfig> {
  CapabilitiesConfigMapper._();

  static CapabilitiesConfigMapper? _instance;
  static CapabilitiesConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CapabilitiesConfigMapper._());
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

  @override
  final MappableFields<CapabilitiesConfig> fields = const {
    #enableSubagents: _f$enableSubagents,
    #enabledTools: _f$enabledTools,
    #disabledTools: _f$disabledTools,
    #compactionThreshold: _f$compactionThreshold,
    #finishToolSchemaJson: _f$finishToolSchemaJson,
  };
  @override
  final bool ignoreNull = true;

  static CapabilitiesConfig _instantiate(DecodingData data) {
    return CapabilitiesConfig(
      enableSubagents: data.dec(_f$enableSubagents),
      enabledTools: data.dec(_f$enabledTools),
      disabledTools: data.dec(_f$disabledTools),
      compactionThreshold: data.dec(_f$compactionThreshold),
      finishToolSchemaJson: data.dec(_f$finishToolSchemaJson),
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

extension CapabilitiesConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CapabilitiesConfig, $Out> {
  CapabilitiesConfigCopyWith<$R, CapabilitiesConfig, $Out>
      get $asCapabilitiesConfig => $base.as(
            (v, t, t2) => _CapabilitiesConfigCopyWithImpl<$R, $Out>(v, t, t2),
          );
}

abstract class CapabilitiesConfigCopyWith<$R, $In extends CapabilitiesConfig,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, BuiltinTools,
      ObjectCopyWith<$R, BuiltinTools, BuiltinTools>>? get enabledTools;
  ListCopyWith<$R, BuiltinTools,
      ObjectCopyWith<$R, BuiltinTools, BuiltinTools>>? get disabledTools;
  $R call({
    bool? enableSubagents,
    List<BuiltinTools>? enabledTools,
    List<BuiltinTools>? disabledTools,
    int? compactionThreshold,
    String? finishToolSchemaJson,
  });
  CapabilitiesConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

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
  $R call({
    bool? enableSubagents,
    Object? enabledTools = $none,
    Object? disabledTools = $none,
    Object? compactionThreshold = $none,
    Object? finishToolSchemaJson = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (enableSubagents != null) #enableSubagents: enableSubagents,
          if (enabledTools != $none) #enabledTools: enabledTools,
          if (disabledTools != $none) #disabledTools: disabledTools,
          if (compactionThreshold != $none)
            #compactionThreshold: compactionThreshold,
          if (finishToolSchemaJson != $none)
            #finishToolSchemaJson: finishToolSchemaJson,
        }),
      );
  @override
  CapabilitiesConfig $make(CopyWithData data) => CapabilitiesConfig(
        enableSubagents: data.get(#enableSubagents, or: $value.enableSubagents),
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
      );

  @override
  CapabilitiesConfigCopyWith<$R2, CapabilitiesConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _CapabilitiesConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
