// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'compaction.dart';

/// @nodoc
class CompactionConfigMapper extends ClassMapperBase<CompactionConfig> {
  CompactionConfigMapper._();

  static CompactionConfigMapper? _instance;
  static CompactionConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CompactionConfigMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'CompactionConfig';

  static int? _$tokenThreshold(CompactionConfig v) => v.tokenThreshold;
  static const Field<CompactionConfig, int> _f$tokenThreshold = Field(
    'tokenThreshold',
    _$tokenThreshold,
    key: r'token_threshold',
    opt: true,
  );

  @override
  final MappableFields<CompactionConfig> fields = const {
    #tokenThreshold: _f$tokenThreshold,
  };
  @override
  final bool ignoreNull = true;

  static CompactionConfig _instantiate(DecodingData data) {
    return CompactionConfig(tokenThreshold: data.dec(_f$tokenThreshold));
  }

  @override
  final Function instantiate = _instantiate;

  static CompactionConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CompactionConfig>(map);
  }

  static CompactionConfig fromJson(String json) {
    return ensureInitialized().decodeJson<CompactionConfig>(json);
  }
}

/// @nodoc
mixin CompactionConfigMappable {
  String toJson() {
    return CompactionConfigMapper.ensureInitialized()
        .encodeJson<CompactionConfig>(this as CompactionConfig);
  }

  Map<String, dynamic> toMap() {
    return CompactionConfigMapper.ensureInitialized()
        .encodeMap<CompactionConfig>(this as CompactionConfig);
  }

  CompactionConfigCopyWith<CompactionConfig, CompactionConfig, CompactionConfig>
      get copyWith =>
          _CompactionConfigCopyWithImpl<CompactionConfig, CompactionConfig>(
            this as CompactionConfig,
            $identity,
            $identity,
          );
  @override
  String toString() {
    return CompactionConfigMapper.ensureInitialized().stringifyValue(
      this as CompactionConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    return CompactionConfigMapper.ensureInitialized().equalsValue(
      this as CompactionConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return CompactionConfigMapper.ensureInitialized().hashValue(
      this as CompactionConfig,
    );
  }
}

/// @nodoc
extension CompactionConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CompactionConfig, $Out> {
  CompactionConfigCopyWith<$R, CompactionConfig, $Out>
      get $asCompactionConfig => $base
          .as((v, t, t2) => _CompactionConfigCopyWithImpl<$R, $Out>(v, t, t2));
}

/// @nodoc
abstract class CompactionConfigCopyWith<$R, $In extends CompactionConfig, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? tokenThreshold});
  CompactionConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

/// @nodoc
class _CompactionConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CompactionConfig, $Out>
    implements CompactionConfigCopyWith<$R, CompactionConfig, $Out> {
  _CompactionConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CompactionConfig> $mapper =
      CompactionConfigMapper.ensureInitialized();
  @override
  $R call({Object? tokenThreshold = $none}) => $apply(
        FieldCopyWithData({
          if (tokenThreshold != $none) #tokenThreshold: tokenThreshold,
        }),
      );
  @override
  CompactionConfig $make(CopyWithData data) => CompactionConfig(
        tokenThreshold: data.get(#tokenThreshold, or: $value.tokenThreshold),
      );

  @override
  CompactionConfigCopyWith<$R2, CompactionConfig, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _CompactionConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
