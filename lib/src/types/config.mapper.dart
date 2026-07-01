// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'config.dart';

class SubagentCapabilitiesMapper extends ClassMapperBase<SubagentCapabilities> {
  SubagentCapabilitiesMapper._();

  static SubagentCapabilitiesMapper? _instance;
  static SubagentCapabilitiesMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SubagentCapabilitiesMapper._());
      BuiltinToolsMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SubagentCapabilities';

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
    #enabledTools: _f$enabledTools,
    #disabledTools: _f$disabledTools,
  };
  @override
  final bool ignoreNull = true;

  static SubagentCapabilities _instantiate(DecodingData data) {
    return SubagentCapabilities(
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

mixin SubagentCapabilitiesMappable {
  String toJson() {
    return SubagentCapabilitiesMapper.ensureInitialized()
        .encodeJson<SubagentCapabilities>(this as SubagentCapabilities);
  }

  Map<String, dynamic> toMap() {
    return SubagentCapabilitiesMapper.ensureInitialized()
        .encodeMap<SubagentCapabilities>(this as SubagentCapabilities);
  }

  SubagentCapabilitiesCopyWith<
    SubagentCapabilities,
    SubagentCapabilities,
    SubagentCapabilities
  >
  get copyWith =>
      _SubagentCapabilitiesCopyWithImpl<
        SubagentCapabilities,
        SubagentCapabilities
      >(this as SubagentCapabilities, $identity, $identity);
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

extension SubagentCapabilitiesValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SubagentCapabilities, $Out> {
  SubagentCapabilitiesCopyWith<$R, SubagentCapabilities, $Out>
  get $asSubagentCapabilities => $base.as(
    (v, t, t2) => _SubagentCapabilitiesCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class SubagentCapabilitiesCopyWith<
  $R,
  $In extends SubagentCapabilities,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    BuiltinTools,
    ObjectCopyWith<$R, BuiltinTools, BuiltinTools>
  >?
  get enabledTools;
  ListCopyWith<
    $R,
    BuiltinTools,
    ObjectCopyWith<$R, BuiltinTools, BuiltinTools>
  >?
  get disabledTools;
  $R call({
    List<BuiltinTools>? enabledTools,
    List<BuiltinTools>? disabledTools,
  });
  SubagentCapabilitiesCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SubagentCapabilitiesCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SubagentCapabilities, $Out>
    implements SubagentCapabilitiesCopyWith<$R, SubagentCapabilities, $Out> {
  _SubagentCapabilitiesCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SubagentCapabilities> $mapper =
      SubagentCapabilitiesMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    BuiltinTools,
    ObjectCopyWith<$R, BuiltinTools, BuiltinTools>
  >?
  get enabledTools => $value.enabledTools != null
      ? ListCopyWith(
          $value.enabledTools!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(enabledTools: v),
        )
      : null;
  @override
  ListCopyWith<
    $R,
    BuiltinTools,
    ObjectCopyWith<$R, BuiltinTools, BuiltinTools>
  >?
  get disabledTools => $value.disabledTools != null
      ? ListCopyWith(
          $value.disabledTools!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(disabledTools: v),
        )
      : null;
  @override
  $R call({Object? enabledTools = $none, Object? disabledTools = $none}) =>
      $apply(
        FieldCopyWithData({
          if (enabledTools != $none) #enabledTools: enabledTools,
          if (disabledTools != $none) #disabledTools: disabledTools,
        }),
      );
  @override
  SubagentCapabilities $make(CopyWithData data) => SubagentCapabilities(
    enabledTools: data.get(#enabledTools, or: $value.enabledTools),
    disabledTools: data.get(#disabledTools, or: $value.disabledTools),
  );

  @override
  SubagentCapabilitiesCopyWith<$R2, SubagentCapabilities, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _SubagentCapabilitiesCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

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
  get copyWith => _SubagentConfigCopyWithImpl<SubagentConfig, SubagentConfig>(
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

extension SubagentConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SubagentConfig, $Out> {
  SubagentConfigCopyWith<$R, SubagentConfig, $Out> get $asSubagentConfig =>
      $base.as((v, t, t2) => _SubagentConfigCopyWithImpl<$R, $Out>(v, t, t2));
}

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
  }) => $apply(
    FieldCopyWithData({
      if (name != null) #name: name,
      if (description != null) #description: description,
      if (systemInstructions != $none) #systemInstructions: systemInstructions,
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
  ) => _SubagentConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

