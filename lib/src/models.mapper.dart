// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'models.dart';

class ThinkingLevelMapper extends EnumMapper<ThinkingLevel> {
  ThinkingLevelMapper._();

  static ThinkingLevelMapper? _instance;
  static ThinkingLevelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ThinkingLevelMapper._());
    }
    return _instance!;
  }

  static ThinkingLevel fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ThinkingLevel decode(dynamic value) {
    switch (value) {
      case r'minimal':
        return ThinkingLevel.minimal;
      case r'low':
        return ThinkingLevel.low;
      case r'medium':
        return ThinkingLevel.medium;
      case r'high':
        return ThinkingLevel.high;
      default:
        return ThinkingLevel.values[0];
    }
  }

  @override
  dynamic encode(ThinkingLevel self) {
    switch (self) {
      case ThinkingLevel.minimal:
        return r'minimal';
      case ThinkingLevel.low:
        return r'low';
      case ThinkingLevel.medium:
        return r'medium';
      case ThinkingLevel.high:
        return r'high';
    }
  }
}

extension ThinkingLevelMapperExtension on ThinkingLevel {
  String toValue() {
    ThinkingLevelMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ThinkingLevel>(this) as String;
  }
}

class ModelTypeMapper extends EnumMapper<ModelType> {
  ModelTypeMapper._();

  static ModelTypeMapper? _instance;
  static ModelTypeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModelTypeMapper._());
    }
    return _instance!;
  }

  static ModelType fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ModelType decode(dynamic value) {
    switch (value) {
      case r'text':
        return ModelType.text;
      case r'image':
        return ModelType.image;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ModelType self) {
    switch (self) {
      case ModelType.text:
        return r'text';
      case ModelType.image:
        return r'image';
    }
  }
}

extension ModelTypeMapperExtension on ModelType {
  String toValue() {
    ModelTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ModelType>(this) as String;
  }
}

class ModelEndpointMapper extends ClassMapperBase<ModelEndpoint> {
  ModelEndpointMapper._();

  static ModelEndpointMapper? _instance;
  static ModelEndpointMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModelEndpointMapper._());
      GeminiAPIEndpointMapper.ensureInitialized();
      VertexEndpointMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModelEndpoint';

  static String? _$baseUrl(ModelEndpoint v) => v.baseUrl;
  static const Field<ModelEndpoint, String> _f$baseUrl = Field(
    'baseUrl',
    _$baseUrl,
    key: r'base_url',
    opt: true,
  );
  static Map<String, String>? _$httpHeaders(ModelEndpoint v) => v.httpHeaders;
  static const Field<ModelEndpoint, Map<String, String>> _f$httpHeaders = Field(
    'httpHeaders',
    _$httpHeaders,
    key: r'http_headers',
    opt: true,
  );

  @override
  final MappableFields<ModelEndpoint> fields = const {
    #baseUrl: _f$baseUrl,
    #httpHeaders: _f$httpHeaders,
  };
  @override
  final bool ignoreNull = true;

  static ModelEndpoint _instantiate(DecodingData data) {
    throw MapperException.missingSubclass(
      'ModelEndpoint',
      'type',
      '${data.value['type']}',
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModelEndpoint fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModelEndpoint>(map);
  }

  static ModelEndpoint fromJson(String json) {
    return ensureInitialized().decodeJson<ModelEndpoint>(json);
  }
}

mixin ModelEndpointMappable {
  String toJson();
  Map<String, dynamic> toMap();
  ModelEndpointCopyWith<ModelEndpoint, ModelEndpoint, ModelEndpoint>
      get copyWith;
}

abstract class ModelEndpointCopyWith<$R, $In extends ModelEndpoint, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
      get httpHeaders;
  $R call({String? baseUrl, Map<String, String>? httpHeaders});
  ModelEndpointCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class GeminiModelOptionsMapper extends ClassMapperBase<GeminiModelOptions> {
  GeminiModelOptionsMapper._();

  static GeminiModelOptionsMapper? _instance;
  static GeminiModelOptionsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GeminiModelOptionsMapper._());
      ThinkingLevelMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GeminiModelOptions';

  static ThinkingLevel? _$thinkingLevel(GeminiModelOptions v) =>
      v.thinkingLevel;
  static const Field<GeminiModelOptions, ThinkingLevel> _f$thinkingLevel =
      Field(
    'thinkingLevel',
    _$thinkingLevel,
    key: r'thinking_level',
    opt: true,
  );

  @override
  final MappableFields<GeminiModelOptions> fields = const {
    #thinkingLevel: _f$thinkingLevel,
  };
  @override
  final bool ignoreNull = true;

  static GeminiModelOptions _instantiate(DecodingData data) {
    return GeminiModelOptions(thinkingLevel: data.dec(_f$thinkingLevel));
  }

  @override
  final Function instantiate = _instantiate;

  static GeminiModelOptions fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GeminiModelOptions>(map);
  }

  static GeminiModelOptions fromJson(String json) {
    return ensureInitialized().decodeJson<GeminiModelOptions>(json);
  }
}

mixin GeminiModelOptionsMappable {
  String toJson() {
    return GeminiModelOptionsMapper.ensureInitialized()
        .encodeJson<GeminiModelOptions>(this as GeminiModelOptions);
  }

  Map<String, dynamic> toMap() {
    return GeminiModelOptionsMapper.ensureInitialized()
        .encodeMap<GeminiModelOptions>(this as GeminiModelOptions);
  }

  GeminiModelOptionsCopyWith<GeminiModelOptions, GeminiModelOptions,
      GeminiModelOptions> get copyWith => _GeminiModelOptionsCopyWithImpl<
          GeminiModelOptions, GeminiModelOptions>(
        this as GeminiModelOptions,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return GeminiModelOptionsMapper.ensureInitialized().stringifyValue(
      this as GeminiModelOptions,
    );
  }

  @override
  bool operator ==(Object other) {
    return GeminiModelOptionsMapper.ensureInitialized().equalsValue(
      this as GeminiModelOptions,
      other,
    );
  }

  @override
  int get hashCode {
    return GeminiModelOptionsMapper.ensureInitialized().hashValue(
      this as GeminiModelOptions,
    );
  }
}

extension GeminiModelOptionsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GeminiModelOptions, $Out> {
  GeminiModelOptionsCopyWith<$R, GeminiModelOptions, $Out>
      get $asGeminiModelOptions => $base.as(
            (v, t, t2) => _GeminiModelOptionsCopyWithImpl<$R, $Out>(v, t, t2),
          );
}

abstract class GeminiModelOptionsCopyWith<$R, $In extends GeminiModelOptions,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call({ThinkingLevel? thinkingLevel});
  GeminiModelOptionsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _GeminiModelOptionsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GeminiModelOptions, $Out>
    implements GeminiModelOptionsCopyWith<$R, GeminiModelOptions, $Out> {
  _GeminiModelOptionsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GeminiModelOptions> $mapper =
      GeminiModelOptionsMapper.ensureInitialized();
  @override
  $R call({Object? thinkingLevel = $none}) => $apply(
        FieldCopyWithData({
          if (thinkingLevel != $none) #thinkingLevel: thinkingLevel,
        }),
      );
  @override
  GeminiModelOptions $make(CopyWithData data) => GeminiModelOptions(
        thinkingLevel: data.get(#thinkingLevel, or: $value.thinkingLevel),
      );

  @override
  GeminiModelOptionsCopyWith<$R2, GeminiModelOptions, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _GeminiModelOptionsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class GeminiAPIEndpointMapper extends SubClassMapperBase<GeminiAPIEndpoint> {
  GeminiAPIEndpointMapper._();

  static GeminiAPIEndpointMapper? _instance;
  static GeminiAPIEndpointMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GeminiAPIEndpointMapper._());
      ModelEndpointMapper.ensureInitialized().addSubMapper(_instance!);
      GeminiModelOptionsMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GeminiAPIEndpoint';

  static String? _$baseUrl(GeminiAPIEndpoint v) => v.baseUrl;
  static const Field<GeminiAPIEndpoint, String> _f$baseUrl = Field(
    'baseUrl',
    _$baseUrl,
    key: r'base_url',
    opt: true,
  );
  static Map<String, String>? _$httpHeaders(GeminiAPIEndpoint v) =>
      v.httpHeaders;
  static const Field<GeminiAPIEndpoint, Map<String, String>> _f$httpHeaders =
      Field('httpHeaders', _$httpHeaders, key: r'http_headers', opt: true);
  static String? _$apiKey(GeminiAPIEndpoint v) => v.apiKey;
  static const Field<GeminiAPIEndpoint, String> _f$apiKey = Field(
    'apiKey',
    _$apiKey,
    key: r'api_key',
    opt: true,
  );
  static GeminiModelOptions? _$options(GeminiAPIEndpoint v) => v.options;
  static const Field<GeminiAPIEndpoint, GeminiModelOptions> _f$options = Field(
    'options',
    _$options,
    opt: true,
  );

  @override
  final MappableFields<GeminiAPIEndpoint> fields = const {
    #baseUrl: _f$baseUrl,
    #httpHeaders: _f$httpHeaders,
    #apiKey: _f$apiKey,
    #options: _f$options,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = 'gemini';
  @override
  late final ClassMapperBase superMapper =
      ModelEndpointMapper.ensureInitialized();

  static GeminiAPIEndpoint _instantiate(DecodingData data) {
    return GeminiAPIEndpoint(
      baseUrl: data.dec(_f$baseUrl),
      httpHeaders: data.dec(_f$httpHeaders),
      apiKey: data.dec(_f$apiKey),
      options: data.dec(_f$options),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static GeminiAPIEndpoint fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GeminiAPIEndpoint>(map);
  }

  static GeminiAPIEndpoint fromJson(String json) {
    return ensureInitialized().decodeJson<GeminiAPIEndpoint>(json);
  }
}

mixin GeminiAPIEndpointMappable {
  String toJson() {
    return GeminiAPIEndpointMapper.ensureInitialized()
        .encodeJson<GeminiAPIEndpoint>(this as GeminiAPIEndpoint);
  }

  Map<String, dynamic> toMap() {
    return GeminiAPIEndpointMapper.ensureInitialized()
        .encodeMap<GeminiAPIEndpoint>(this as GeminiAPIEndpoint);
  }

  GeminiAPIEndpointCopyWith<GeminiAPIEndpoint, GeminiAPIEndpoint,
          GeminiAPIEndpoint>
      get copyWith =>
          _GeminiAPIEndpointCopyWithImpl<GeminiAPIEndpoint, GeminiAPIEndpoint>(
            this as GeminiAPIEndpoint,
            $identity,
            $identity,
          );
  @override
  String toString() {
    return GeminiAPIEndpointMapper.ensureInitialized().stringifyValue(
      this as GeminiAPIEndpoint,
    );
  }

  @override
  bool operator ==(Object other) {
    return GeminiAPIEndpointMapper.ensureInitialized().equalsValue(
      this as GeminiAPIEndpoint,
      other,
    );
  }

  @override
  int get hashCode {
    return GeminiAPIEndpointMapper.ensureInitialized().hashValue(
      this as GeminiAPIEndpoint,
    );
  }
}

extension GeminiAPIEndpointValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GeminiAPIEndpoint, $Out> {
  GeminiAPIEndpointCopyWith<$R, GeminiAPIEndpoint, $Out>
      get $asGeminiAPIEndpoint => $base.as(
            (v, t, t2) => _GeminiAPIEndpointCopyWithImpl<$R, $Out>(v, t, t2),
          );
}

abstract class GeminiAPIEndpointCopyWith<$R, $In extends GeminiAPIEndpoint,
    $Out> implements ModelEndpointCopyWith<$R, $In, $Out> {
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
      get httpHeaders;
  GeminiModelOptionsCopyWith<$R, GeminiModelOptions, GeminiModelOptions>?
      get options;
  @override
  $R call({
    String? baseUrl,
    Map<String, String>? httpHeaders,
    String? apiKey,
    GeminiModelOptions? options,
  });
  GeminiAPIEndpointCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _GeminiAPIEndpointCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GeminiAPIEndpoint, $Out>
    implements GeminiAPIEndpointCopyWith<$R, GeminiAPIEndpoint, $Out> {
  _GeminiAPIEndpointCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GeminiAPIEndpoint> $mapper =
      GeminiAPIEndpointMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
      get httpHeaders => $value.httpHeaders != null
          ? MapCopyWith(
              $value.httpHeaders!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(httpHeaders: v),
            )
          : null;
  @override
  GeminiModelOptionsCopyWith<$R, GeminiModelOptions, GeminiModelOptions>?
      get options => $value.options?.copyWith.$chain((v) => call(options: v));
  @override
  $R call({
    Object? baseUrl = $none,
    Object? httpHeaders = $none,
    Object? apiKey = $none,
    Object? options = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (baseUrl != $none) #baseUrl: baseUrl,
          if (httpHeaders != $none) #httpHeaders: httpHeaders,
          if (apiKey != $none) #apiKey: apiKey,
          if (options != $none) #options: options,
        }),
      );
  @override
  GeminiAPIEndpoint $make(CopyWithData data) => GeminiAPIEndpoint(
        baseUrl: data.get(#baseUrl, or: $value.baseUrl),
        httpHeaders: data.get(#httpHeaders, or: $value.httpHeaders),
        apiKey: data.get(#apiKey, or: $value.apiKey),
        options: data.get(#options, or: $value.options),
      );

  @override
  GeminiAPIEndpointCopyWith<$R2, GeminiAPIEndpoint, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _GeminiAPIEndpointCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class VertexEndpointMapper extends SubClassMapperBase<VertexEndpoint> {
  VertexEndpointMapper._();

  static VertexEndpointMapper? _instance;
  static VertexEndpointMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = VertexEndpointMapper._());
      ModelEndpointMapper.ensureInitialized().addSubMapper(_instance!);
      GeminiModelOptionsMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'VertexEndpoint';

  static String? _$baseUrl(VertexEndpoint v) => v.baseUrl;
  static const Field<VertexEndpoint, String> _f$baseUrl = Field(
    'baseUrl',
    _$baseUrl,
    key: r'base_url',
    opt: true,
  );
  static Map<String, String>? _$httpHeaders(VertexEndpoint v) => v.httpHeaders;
  static const Field<VertexEndpoint, Map<String, String>> _f$httpHeaders =
      Field('httpHeaders', _$httpHeaders, key: r'http_headers', opt: true);
  static String? _$project(VertexEndpoint v) => v.project;
  static const Field<VertexEndpoint, String> _f$project = Field(
    'project',
    _$project,
    opt: true,
  );
  static String? _$location(VertexEndpoint v) => v.location;
  static const Field<VertexEndpoint, String> _f$location = Field(
    'location',
    _$location,
    opt: true,
  );
  static GeminiModelOptions? _$options(VertexEndpoint v) => v.options;
  static const Field<VertexEndpoint, GeminiModelOptions> _f$options = Field(
    'options',
    _$options,
    opt: true,
  );

  @override
  final MappableFields<VertexEndpoint> fields = const {
    #baseUrl: _f$baseUrl,
    #httpHeaders: _f$httpHeaders,
    #project: _f$project,
    #location: _f$location,
    #options: _f$options,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = 'vertex';
  @override
  late final ClassMapperBase superMapper =
      ModelEndpointMapper.ensureInitialized();

  static VertexEndpoint _instantiate(DecodingData data) {
    return VertexEndpoint(
      baseUrl: data.dec(_f$baseUrl),
      httpHeaders: data.dec(_f$httpHeaders),
      project: data.dec(_f$project),
      location: data.dec(_f$location),
      options: data.dec(_f$options),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static VertexEndpoint fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<VertexEndpoint>(map);
  }

  static VertexEndpoint fromJson(String json) {
    return ensureInitialized().decodeJson<VertexEndpoint>(json);
  }
}

mixin VertexEndpointMappable {
  String toJson() {
    return VertexEndpointMapper.ensureInitialized().encodeJson<VertexEndpoint>(
      this as VertexEndpoint,
    );
  }

  Map<String, dynamic> toMap() {
    return VertexEndpointMapper.ensureInitialized().encodeMap<VertexEndpoint>(
      this as VertexEndpoint,
    );
  }

  VertexEndpointCopyWith<VertexEndpoint, VertexEndpoint, VertexEndpoint>
      get copyWith =>
          _VertexEndpointCopyWithImpl<VertexEndpoint, VertexEndpoint>(
            this as VertexEndpoint,
            $identity,
            $identity,
          );
  @override
  String toString() {
    return VertexEndpointMapper.ensureInitialized().stringifyValue(
      this as VertexEndpoint,
    );
  }

  @override
  bool operator ==(Object other) {
    return VertexEndpointMapper.ensureInitialized().equalsValue(
      this as VertexEndpoint,
      other,
    );
  }

  @override
  int get hashCode {
    return VertexEndpointMapper.ensureInitialized().hashValue(
      this as VertexEndpoint,
    );
  }
}

extension VertexEndpointValueCopy<$R, $Out>
    on ObjectCopyWith<$R, VertexEndpoint, $Out> {
  VertexEndpointCopyWith<$R, VertexEndpoint, $Out> get $asVertexEndpoint =>
      $base.as((v, t, t2) => _VertexEndpointCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class VertexEndpointCopyWith<$R, $In extends VertexEndpoint, $Out>
    implements ModelEndpointCopyWith<$R, $In, $Out> {
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
      get httpHeaders;
  GeminiModelOptionsCopyWith<$R, GeminiModelOptions, GeminiModelOptions>?
      get options;
  @override
  $R call({
    String? baseUrl,
    Map<String, String>? httpHeaders,
    String? project,
    String? location,
    GeminiModelOptions? options,
  });
  VertexEndpointCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _VertexEndpointCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, VertexEndpoint, $Out>
    implements VertexEndpointCopyWith<$R, VertexEndpoint, $Out> {
  _VertexEndpointCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<VertexEndpoint> $mapper =
      VertexEndpointMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
      get httpHeaders => $value.httpHeaders != null
          ? MapCopyWith(
              $value.httpHeaders!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(httpHeaders: v),
            )
          : null;
  @override
  GeminiModelOptionsCopyWith<$R, GeminiModelOptions, GeminiModelOptions>?
      get options => $value.options?.copyWith.$chain((v) => call(options: v));
  @override
  $R call({
    Object? baseUrl = $none,
    Object? httpHeaders = $none,
    Object? project = $none,
    Object? location = $none,
    Object? options = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (baseUrl != $none) #baseUrl: baseUrl,
          if (httpHeaders != $none) #httpHeaders: httpHeaders,
          if (project != $none) #project: project,
          if (location != $none) #location: location,
          if (options != $none) #options: options,
        }),
      );
  @override
  VertexEndpoint $make(CopyWithData data) => VertexEndpoint(
        baseUrl: data.get(#baseUrl, or: $value.baseUrl),
        httpHeaders: data.get(#httpHeaders, or: $value.httpHeaders),
        project: data.get(#project, or: $value.project),
        location: data.get(#location, or: $value.location),
        options: data.get(#options, or: $value.options),
      );

  @override
  VertexEndpointCopyWith<$R2, VertexEndpoint, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _VertexEndpointCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ModelTargetMapper extends ClassMapperBase<ModelTarget> {
  ModelTargetMapper._();

  static ModelTargetMapper? _instance;
  static ModelTargetMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModelTargetMapper._());
      ModelTypeMapper.ensureInitialized();
      ModelEndpointMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModelTarget';

  static String? _$name(ModelTarget v) => v.name;
  static const Field<ModelTarget, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
  );
  static List<ModelType> _$types(ModelTarget v) => v.types;
  static const Field<ModelTarget, List<ModelType>> _f$types = Field(
    'types',
    _$types,
    opt: true,
  );
  static ModelEndpoint? _$endpoint(ModelTarget v) => v.endpoint;
  static const Field<ModelTarget, ModelEndpoint> _f$endpoint = Field(
    'endpoint',
    _$endpoint,
    opt: true,
  );

  @override
  final MappableFields<ModelTarget> fields = const {
    #name: _f$name,
    #types: _f$types,
    #endpoint: _f$endpoint,
  };
  @override
  final bool ignoreNull = true;

  static ModelTarget _instantiate(DecodingData data) {
    return ModelTarget(
      name: data.dec(_f$name),
      types: data.dec(_f$types),
      endpoint: data.dec(_f$endpoint),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModelTarget fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModelTarget>(map);
  }

  static ModelTarget fromJson(String json) {
    return ensureInitialized().decodeJson<ModelTarget>(json);
  }
}

mixin ModelTargetMappable {
  String toJson() {
    return ModelTargetMapper.ensureInitialized().encodeJson<ModelTarget>(
      this as ModelTarget,
    );
  }

  Map<String, dynamic> toMap() {
    return ModelTargetMapper.ensureInitialized().encodeMap<ModelTarget>(
      this as ModelTarget,
    );
  }

  ModelTargetCopyWith<ModelTarget, ModelTarget, ModelTarget> get copyWith =>
      _ModelTargetCopyWithImpl<ModelTarget, ModelTarget>(
        this as ModelTarget,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ModelTargetMapper.ensureInitialized().stringifyValue(
      this as ModelTarget,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModelTargetMapper.ensureInitialized().equalsValue(
      this as ModelTarget,
      other,
    );
  }

  @override
  int get hashCode {
    return ModelTargetMapper.ensureInitialized().hashValue(this as ModelTarget);
  }
}

extension ModelTargetValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModelTarget, $Out> {
  ModelTargetCopyWith<$R, ModelTarget, $Out> get $asModelTarget =>
      $base.as((v, t, t2) => _ModelTargetCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ModelTargetCopyWith<$R, $In extends ModelTarget, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, ModelType, ObjectCopyWith<$R, ModelType, ModelType>>
      get types;
  ModelEndpointCopyWith<$R, ModelEndpoint, ModelEndpoint>? get endpoint;
  $R call({String? name, List<ModelType>? types, ModelEndpoint? endpoint});
  ModelTargetCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModelTargetCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModelTarget, $Out>
    implements ModelTargetCopyWith<$R, ModelTarget, $Out> {
  _ModelTargetCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModelTarget> $mapper =
      ModelTargetMapper.ensureInitialized();
  @override
  ListCopyWith<$R, ModelType, ObjectCopyWith<$R, ModelType, ModelType>>
      get types => ListCopyWith(
            $value.types,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(types: v),
          );
  @override
  ModelEndpointCopyWith<$R, ModelEndpoint, ModelEndpoint>? get endpoint =>
      $value.endpoint?.copyWith.$chain((v) => call(endpoint: v));
  @override
  $R call({
    Object? name = $none,
    Object? types = $none,
    Object? endpoint = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (name != $none) #name: name,
          if (types != $none) #types: types,
          if (endpoint != $none) #endpoint: endpoint,
        }),
      );
  @override
  ModelTarget $make(CopyWithData data) => ModelTarget(
        name: data.get(#name, or: $value.name),
        types: data.get(#types, or: $value.types),
        endpoint: data.get(#endpoint, or: $value.endpoint),
      );

  @override
  ModelTargetCopyWith<$R2, ModelTarget, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _ModelTargetCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
