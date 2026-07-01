// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'content.dart';

class BuiltinSlashCommandNameMapper
    extends EnumMapper<BuiltinSlashCommandName> {
  BuiltinSlashCommandNameMapper._();

  static BuiltinSlashCommandNameMapper? _instance;
  static BuiltinSlashCommandNameMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = BuiltinSlashCommandNameMapper._(),
      );
    }
    return _instance!;
  }

  static BuiltinSlashCommandName fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  BuiltinSlashCommandName decode(dynamic value) {
    switch (value) {
      case 'plan':
        return BuiltinSlashCommandName.plan;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(BuiltinSlashCommandName self) {
    switch (self) {
      case BuiltinSlashCommandName.plan:
        return 'plan';
    }
  }
}

extension BuiltinSlashCommandNameMapperExtension on BuiltinSlashCommandName {
  dynamic toValue() {
    BuiltinSlashCommandNameMapper.ensureInitialized();
    return MapperContainer.globals.toValue<BuiltinSlashCommandName>(this);
  }
}

class SlashCommandMapper extends ClassMapperBase<SlashCommand> {
  SlashCommandMapper._();

  static SlashCommandMapper? _instance;
  static SlashCommandMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SlashCommandMapper._());
      BuiltinSlashCommandNameMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SlashCommand';

  static BuiltinSlashCommandName _$name(SlashCommand v) => v.name;
  static const Field<SlashCommand, BuiltinSlashCommandName> _f$name = Field(
    'name',
    _$name,
  );

  @override
  final MappableFields<SlashCommand> fields = const {#name: _f$name};

  static SlashCommand _instantiate(DecodingData data) {
    return SlashCommand(name: data.dec(_f$name));
  }

  @override
  final Function instantiate = _instantiate;

  static SlashCommand fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SlashCommand>(map);
  }

  static SlashCommand fromJson(String json) {
    return ensureInitialized().decodeJson<SlashCommand>(json);
  }
}

mixin SlashCommandMappable {
  String toJson() {
    return SlashCommandMapper.ensureInitialized().encodeJson<SlashCommand>(
      this as SlashCommand,
    );
  }

  Map<String, dynamic> toMap() {
    return SlashCommandMapper.ensureInitialized().encodeMap<SlashCommand>(
      this as SlashCommand,
    );
  }

  SlashCommandCopyWith<SlashCommand, SlashCommand, SlashCommand> get copyWith =>
      _SlashCommandCopyWithImpl<SlashCommand, SlashCommand>(
        this as SlashCommand,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SlashCommandMapper.ensureInitialized().stringifyValue(
      this as SlashCommand,
    );
  }

  @override
  bool operator ==(Object other) {
    return SlashCommandMapper.ensureInitialized().equalsValue(
      this as SlashCommand,
      other,
    );
  }

  @override
  int get hashCode {
    return SlashCommandMapper.ensureInitialized().hashValue(
      this as SlashCommand,
    );
  }
}

extension SlashCommandValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SlashCommand, $Out> {
  SlashCommandCopyWith<$R, SlashCommand, $Out> get $asSlashCommand =>
      $base.as((v, t, t2) => _SlashCommandCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SlashCommandCopyWith<$R, $In extends SlashCommand, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({BuiltinSlashCommandName? name});
  SlashCommandCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SlashCommandCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SlashCommand, $Out>
    implements SlashCommandCopyWith<$R, SlashCommand, $Out> {
  _SlashCommandCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SlashCommand> $mapper =
      SlashCommandMapper.ensureInitialized();
  @override
  $R call({BuiltinSlashCommandName? name}) =>
      $apply(FieldCopyWithData({if (name != null) #name: name}));
  @override
  SlashCommand $make(CopyWithData data) =>
      SlashCommand(name: data.get(#name, or: $value.name));

  @override
  SlashCommandCopyWith<$R2, SlashCommand, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SlashCommandCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

