// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'system_instructions.dart';

class SystemInstructionSectionMapper
    extends ClassMapperBase<SystemInstructionSection> {
  SystemInstructionSectionMapper._();

  static SystemInstructionSectionMapper? _instance;
  static SystemInstructionSectionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = SystemInstructionSectionMapper._(),
      );
    }
    return _instance!;
  }

  @override
  final String id = 'SystemInstructionSection';

  static String _$content(SystemInstructionSection v) => v.content;
  static const Field<SystemInstructionSection, String> _f$content = Field(
    'content',
    _$content,
  );
  static String _$title(SystemInstructionSection v) => v.title;
  static const Field<SystemInstructionSection, String> _f$title = Field(
    'title',
    _$title,
    opt: true,
    def: 'user_system_instructions',
  );

  @override
  final MappableFields<SystemInstructionSection> fields = const {
    #content: _f$content,
    #title: _f$title,
  };

  static SystemInstructionSection _instantiate(DecodingData data) {
    return SystemInstructionSection(
      content: data.dec(_f$content),
      title: data.dec(_f$title),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SystemInstructionSection fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SystemInstructionSection>(map);
  }

  static SystemInstructionSection fromJson(String json) {
    return ensureInitialized().decodeJson<SystemInstructionSection>(json);
  }
}

mixin SystemInstructionSectionMappable {
  String toJson() {
    return SystemInstructionSectionMapper.ensureInitialized()
        .encodeJson<SystemInstructionSection>(this as SystemInstructionSection);
  }

  Map<String, dynamic> toMap() {
    return SystemInstructionSectionMapper.ensureInitialized()
        .encodeMap<SystemInstructionSection>(this as SystemInstructionSection);
  }

  SystemInstructionSectionCopyWith<
    SystemInstructionSection,
    SystemInstructionSection,
    SystemInstructionSection
  >
  get copyWith =>
      _SystemInstructionSectionCopyWithImpl<
        SystemInstructionSection,
        SystemInstructionSection
      >(this as SystemInstructionSection, $identity, $identity);
  @override
  String toString() {
    return SystemInstructionSectionMapper.ensureInitialized().stringifyValue(
      this as SystemInstructionSection,
    );
  }

  @override
  bool operator ==(Object other) {
    return SystemInstructionSectionMapper.ensureInitialized().equalsValue(
      this as SystemInstructionSection,
      other,
    );
  }

  @override
  int get hashCode {
    return SystemInstructionSectionMapper.ensureInitialized().hashValue(
      this as SystemInstructionSection,
    );
  }
}

extension SystemInstructionSectionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SystemInstructionSection, $Out> {
  SystemInstructionSectionCopyWith<$R, SystemInstructionSection, $Out>
  get $asSystemInstructionSection => $base.as(
    (v, t, t2) => _SystemInstructionSectionCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class SystemInstructionSectionCopyWith<
  $R,
  $In extends SystemInstructionSection,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? content, String? title});
  SystemInstructionSectionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SystemInstructionSectionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SystemInstructionSection, $Out>
    implements
        SystemInstructionSectionCopyWith<$R, SystemInstructionSection, $Out> {
  _SystemInstructionSectionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SystemInstructionSection> $mapper =
      SystemInstructionSectionMapper.ensureInitialized();
  @override
  $R call({String? content, String? title}) => $apply(
    FieldCopyWithData({
      if (content != null) #content: content,
      if (title != null) #title: title,
    }),
  );
  @override
  SystemInstructionSection $make(CopyWithData data) => SystemInstructionSection(
    content: data.get(#content, or: $value.content),
    title: data.get(#title, or: $value.title),
  );

  @override
  SystemInstructionSectionCopyWith<$R2, SystemInstructionSection, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _SystemInstructionSectionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class SystemInstructionsMapper extends ClassMapperBase<SystemInstructions> {
  SystemInstructionsMapper._();

  static SystemInstructionsMapper? _instance;
  static SystemInstructionsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SystemInstructionsMapper._());
      CustomSystemInstructionsMapper.ensureInitialized();
      TemplatedSystemInstructionsMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SystemInstructions';

  @override
  final MappableFields<SystemInstructions> fields = const {};

  static SystemInstructions _instantiate(DecodingData data) {
    throw MapperException.missingSubclass(
      'SystemInstructions',
      'type',
      '${data.value['type']}',
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SystemInstructions fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SystemInstructions>(map);
  }

  static SystemInstructions fromJson(String json) {
    return ensureInitialized().decodeJson<SystemInstructions>(json);
  }
}

mixin SystemInstructionsMappable {
  String toJson();
  Map<String, dynamic> toMap();
  SystemInstructionsCopyWith<
    SystemInstructions,
    SystemInstructions,
    SystemInstructions
  >
  get copyWith;
}

abstract class SystemInstructionsCopyWith<
  $R,
  $In extends SystemInstructions,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call();
  SystemInstructionsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class CustomSystemInstructionsMapper
    extends SubClassMapperBase<CustomSystemInstructions> {
  CustomSystemInstructionsMapper._();

  static CustomSystemInstructionsMapper? _instance;
  static CustomSystemInstructionsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = CustomSystemInstructionsMapper._(),
      );
      SystemInstructionsMapper.ensureInitialized().addSubMapper(_instance!);
    }
    return _instance!;
  }

  @override
  final String id = 'CustomSystemInstructions';

  static String _$text(CustomSystemInstructions v) => v.text;
  static const Field<CustomSystemInstructions, String> _f$text = Field(
    'text',
    _$text,
  );

  @override
  final MappableFields<CustomSystemInstructions> fields = const {
    #text: _f$text,
  };

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = 'custom';
  @override
  late final ClassMapperBase superMapper =
      SystemInstructionsMapper.ensureInitialized();

  static CustomSystemInstructions _instantiate(DecodingData data) {
    return CustomSystemInstructions(text: data.dec(_f$text));
  }

  @override
  final Function instantiate = _instantiate;

  static CustomSystemInstructions fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CustomSystemInstructions>(map);
  }

  static CustomSystemInstructions fromJson(String json) {
    return ensureInitialized().decodeJson<CustomSystemInstructions>(json);
  }
}

mixin CustomSystemInstructionsMappable {
  String toJson() {
    return CustomSystemInstructionsMapper.ensureInitialized()
        .encodeJson<CustomSystemInstructions>(this as CustomSystemInstructions);
  }

  Map<String, dynamic> toMap() {
    return CustomSystemInstructionsMapper.ensureInitialized()
        .encodeMap<CustomSystemInstructions>(this as CustomSystemInstructions);
  }

  CustomSystemInstructionsCopyWith<
    CustomSystemInstructions,
    CustomSystemInstructions,
    CustomSystemInstructions
  >
  get copyWith =>
      _CustomSystemInstructionsCopyWithImpl<
        CustomSystemInstructions,
        CustomSystemInstructions
      >(this as CustomSystemInstructions, $identity, $identity);
  @override
  String toString() {
    return CustomSystemInstructionsMapper.ensureInitialized().stringifyValue(
      this as CustomSystemInstructions,
    );
  }

  @override
  bool operator ==(Object other) {
    return CustomSystemInstructionsMapper.ensureInitialized().equalsValue(
      this as CustomSystemInstructions,
      other,
    );
  }

  @override
  int get hashCode {
    return CustomSystemInstructionsMapper.ensureInitialized().hashValue(
      this as CustomSystemInstructions,
    );
  }
}

extension CustomSystemInstructionsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CustomSystemInstructions, $Out> {
  CustomSystemInstructionsCopyWith<$R, CustomSystemInstructions, $Out>
  get $asCustomSystemInstructions => $base.as(
    (v, t, t2) => _CustomSystemInstructionsCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class CustomSystemInstructionsCopyWith<
  $R,
  $In extends CustomSystemInstructions,
  $Out
>
    implements SystemInstructionsCopyWith<$R, $In, $Out> {
  @override
  $R call({String? text});
  CustomSystemInstructionsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CustomSystemInstructionsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CustomSystemInstructions, $Out>
    implements
        CustomSystemInstructionsCopyWith<$R, CustomSystemInstructions, $Out> {
  _CustomSystemInstructionsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CustomSystemInstructions> $mapper =
      CustomSystemInstructionsMapper.ensureInitialized();
  @override
  $R call({String? text}) =>
      $apply(FieldCopyWithData({if (text != null) #text: text}));
  @override
  CustomSystemInstructions $make(CopyWithData data) =>
      CustomSystemInstructions(text: data.get(#text, or: $value.text));

  @override
  CustomSystemInstructionsCopyWith<$R2, CustomSystemInstructions, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _CustomSystemInstructionsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class TemplatedSystemInstructionsMapper
    extends SubClassMapperBase<TemplatedSystemInstructions> {
  TemplatedSystemInstructionsMapper._();

  static TemplatedSystemInstructionsMapper? _instance;
  static TemplatedSystemInstructionsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = TemplatedSystemInstructionsMapper._(),
      );
      SystemInstructionsMapper.ensureInitialized().addSubMapper(_instance!);
      SystemInstructionSectionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'TemplatedSystemInstructions';

  static String? _$identity(TemplatedSystemInstructions v) => v.identity;
  static const Field<TemplatedSystemInstructions, String> _f$identity = Field(
    'identity',
    _$identity,
    opt: true,
  );
  static List<SystemInstructionSection> _$sections(
    TemplatedSystemInstructions v,
  ) => v.sections;
  static const Field<
    TemplatedSystemInstructions,
    List<SystemInstructionSection>
  >
  _f$sections = Field('sections', _$sections, opt: true);

  @override
  final MappableFields<TemplatedSystemInstructions> fields = const {
    #identity: _f$identity,
    #sections: _f$sections,
  };

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = 'appended';
  @override
  late final ClassMapperBase superMapper =
      SystemInstructionsMapper.ensureInitialized();

  static TemplatedSystemInstructions _instantiate(DecodingData data) {
    return TemplatedSystemInstructions(
      identity: data.dec(_f$identity),
      sections: data.dec(_f$sections),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static TemplatedSystemInstructions fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TemplatedSystemInstructions>(map);
  }

  static TemplatedSystemInstructions fromJson(String json) {
    return ensureInitialized().decodeJson<TemplatedSystemInstructions>(json);
  }
}

mixin TemplatedSystemInstructionsMappable {
  String toJson() {
    return TemplatedSystemInstructionsMapper.ensureInitialized()
        .encodeJson<TemplatedSystemInstructions>(
          this as TemplatedSystemInstructions,
        );
  }

  Map<String, dynamic> toMap() {
    return TemplatedSystemInstructionsMapper.ensureInitialized()
        .encodeMap<TemplatedSystemInstructions>(
          this as TemplatedSystemInstructions,
        );
  }

  TemplatedSystemInstructionsCopyWith<
    TemplatedSystemInstructions,
    TemplatedSystemInstructions,
    TemplatedSystemInstructions
  >
  get copyWith =>
      _TemplatedSystemInstructionsCopyWithImpl<
        TemplatedSystemInstructions,
        TemplatedSystemInstructions
      >(this as TemplatedSystemInstructions, $identity, $identity);
  @override
  String toString() {
    return TemplatedSystemInstructionsMapper.ensureInitialized().stringifyValue(
      this as TemplatedSystemInstructions,
    );
  }

  @override
  bool operator ==(Object other) {
    return TemplatedSystemInstructionsMapper.ensureInitialized().equalsValue(
      this as TemplatedSystemInstructions,
      other,
    );
  }

  @override
  int get hashCode {
    return TemplatedSystemInstructionsMapper.ensureInitialized().hashValue(
      this as TemplatedSystemInstructions,
    );
  }
}

extension TemplatedSystemInstructionsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, TemplatedSystemInstructions, $Out> {
  TemplatedSystemInstructionsCopyWith<$R, TemplatedSystemInstructions, $Out>
  get $asTemplatedSystemInstructions => $base.as(
    (v, t, t2) => _TemplatedSystemInstructionsCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class TemplatedSystemInstructionsCopyWith<
  $R,
  $In extends TemplatedSystemInstructions,
  $Out
>
    implements SystemInstructionsCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    SystemInstructionSection,
    SystemInstructionSectionCopyWith<
      $R,
      SystemInstructionSection,
      SystemInstructionSection
    >
  >
  get sections;
  @override
  $R call({String? identity, List<SystemInstructionSection>? sections});
  TemplatedSystemInstructionsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _TemplatedSystemInstructionsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TemplatedSystemInstructions, $Out>
    implements
        TemplatedSystemInstructionsCopyWith<
          $R,
          TemplatedSystemInstructions,
          $Out
        > {
  _TemplatedSystemInstructionsCopyWithImpl(
    super.value,
    super.then,
    super.then2,
  );

  @override
  late final ClassMapperBase<TemplatedSystemInstructions> $mapper =
      TemplatedSystemInstructionsMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    SystemInstructionSection,
    SystemInstructionSectionCopyWith<
      $R,
      SystemInstructionSection,
      SystemInstructionSection
    >
  >
  get sections => ListCopyWith(
    $value.sections,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(sections: v),
  );
  @override
  $R call({Object? identity = $none, Object? sections = $none}) => $apply(
    FieldCopyWithData({
      if (identity != $none) #identity: identity,
      if (sections != $none) #sections: sections,
    }),
  );
  @override
  TemplatedSystemInstructions $make(CopyWithData data) =>
      TemplatedSystemInstructions(
        identity: data.get(#identity, or: $value.identity),
        sections: data.get(#sections, or: $value.sections),
      );

  @override
  TemplatedSystemInstructionsCopyWith<$R2, TemplatedSystemInstructions, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _TemplatedSystemInstructionsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

