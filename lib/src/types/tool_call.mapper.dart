// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'tool_call.dart';

class ToolCallMapper extends ClassMapperBase<ToolCall> {
  ToolCallMapper._();

  static ToolCallMapper? _instance;
  static ToolCallMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ToolCallMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ToolCall';

  static String _$name(ToolCall v) => v.name;
  static const Field<ToolCall, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
    def: '',
  );
  static Map<String, dynamic> _$args(ToolCall v) => v.args;
  static const Field<ToolCall, Map<String, dynamic>> _f$args = Field(
    'args',
    _$args,
    key: r'arguments_json',
    opt: true,
    hook: ArgumentsHook(),
  );
  static String? _$id(ToolCall v) => v.id;
  static const Field<ToolCall, String> _f$id = Field('id', _$id, opt: true);
  static String? _$canonicalPath(ToolCall v) => v.canonicalPath;
  static const Field<ToolCall, String> _f$canonicalPath = Field(
    'canonicalPath',
    _$canonicalPath,
    key: r'canonical_path',
    opt: true,
  );

  @override
  final MappableFields<ToolCall> fields = const {
    #name: _f$name,
    #args: _f$args,
    #id: _f$id,
    #canonicalPath: _f$canonicalPath,
  };
  @override
  final bool ignoreNull = true;

  static ToolCall _instantiate(DecodingData data) {
    return ToolCall(
      name: data.dec(_f$name),
      args: data.dec(_f$args),
      id: data.dec(_f$id),
      canonicalPath: data.dec(_f$canonicalPath),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ToolCall fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ToolCall>(map);
  }

  static ToolCall fromJson(String json) {
    return ensureInitialized().decodeJson<ToolCall>(json);
  }
}

mixin ToolCallMappable {
  String toJson() {
    return ToolCallMapper.ensureInitialized().encodeJson<ToolCall>(
      this as ToolCall,
    );
  }

  Map<String, dynamic> toMap() {
    return ToolCallMapper.ensureInitialized().encodeMap<ToolCall>(
      this as ToolCall,
    );
  }

  ToolCallCopyWith<ToolCall, ToolCall, ToolCall> get copyWith =>
      _ToolCallCopyWithImpl<ToolCall, ToolCall>(
        this as ToolCall,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ToolCallMapper.ensureInitialized().stringifyValue(this as ToolCall);
  }

  @override
  bool operator ==(Object other) {
    return ToolCallMapper.ensureInitialized().equalsValue(
      this as ToolCall,
      other,
    );
  }

  @override
  int get hashCode {
    return ToolCallMapper.ensureInitialized().hashValue(this as ToolCall);
  }
}

extension ToolCallValueCopy<$R, $Out> on ObjectCopyWith<$R, ToolCall, $Out> {
  ToolCallCopyWith<$R, ToolCall, $Out> get $asToolCall =>
      $base.as((v, t, t2) => _ToolCallCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ToolCallCopyWith<$R, $In extends ToolCall, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
      get args;
  $R call({
    String? name,
    Map<String, dynamic>? args,
    String? id,
    String? canonicalPath,
  });
  ToolCallCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ToolCallCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ToolCall, $Out>
    implements ToolCallCopyWith<$R, ToolCall, $Out> {
  _ToolCallCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ToolCall> $mapper =
      ToolCallMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
      get args => MapCopyWith(
            $value.args,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(args: v),
          );
  @override
  $R call({
    String? name,
    Object? args = $none,
    Object? id = $none,
    Object? canonicalPath = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (name != null) #name: name,
          if (args != $none) #args: args,
          if (id != $none) #id: id,
          if (canonicalPath != $none) #canonicalPath: canonicalPath,
        }),
      );
  @override
  ToolCall $make(CopyWithData data) => ToolCall(
        name: data.get(#name, or: $value.name),
        args: data.get(#args, or: $value.args),
        id: data.get(#id, or: $value.id),
        canonicalPath: data.get(#canonicalPath, or: $value.canonicalPath),
      );

  @override
  ToolCallCopyWith<$R2, ToolCall, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _ToolCallCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ToolResultMapper extends ClassMapperBase<ToolResult> {
  ToolResultMapper._();

  static ToolResultMapper? _instance;
  static ToolResultMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ToolResultMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ToolResult';

  static String _$name(ToolResult v) => v.name;
  static const Field<ToolResult, String> _f$name = Field('name', _$name);
  static String? _$id(ToolResult v) => v.id;
  static const Field<ToolResult, String> _f$id = Field('id', _$id, opt: true);
  static dynamic _$result(ToolResult v) => v.result;
  static const Field<ToolResult, dynamic> _f$result = Field(
    'result',
    _$result,
    opt: true,
  );
  static String? _$error(ToolResult v) => v.error;
  static const Field<ToolResult, String> _f$error = Field(
    'error',
    _$error,
    opt: true,
  );
  static Exception? _$exception(ToolResult v) => v.exception;
  static const Field<ToolResult, Exception> _f$exception = Field(
    'exception',
    _$exception,
    opt: true,
    hook: UnmappedHook(),
  );

  @override
  final MappableFields<ToolResult> fields = const {
    #name: _f$name,
    #id: _f$id,
    #result: _f$result,
    #error: _f$error,
    #exception: _f$exception,
  };
  @override
  final bool ignoreNull = true;

  static ToolResult _instantiate(DecodingData data) {
    return ToolResult(
      name: data.dec(_f$name),
      id: data.dec(_f$id),
      result: data.dec(_f$result),
      error: data.dec(_f$error),
      exception: data.dec(_f$exception),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ToolResult fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ToolResult>(map);
  }

  static ToolResult fromJson(String json) {
    return ensureInitialized().decodeJson<ToolResult>(json);
  }
}

mixin ToolResultMappable {
  String toJson() {
    return ToolResultMapper.ensureInitialized().encodeJson<ToolResult>(
      this as ToolResult,
    );
  }

  Map<String, dynamic> toMap() {
    return ToolResultMapper.ensureInitialized().encodeMap<ToolResult>(
      this as ToolResult,
    );
  }

  ToolResultCopyWith<ToolResult, ToolResult, ToolResult> get copyWith =>
      _ToolResultCopyWithImpl<ToolResult, ToolResult>(
        this as ToolResult,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ToolResultMapper.ensureInitialized().stringifyValue(
      this as ToolResult,
    );
  }

  @override
  bool operator ==(Object other) {
    return ToolResultMapper.ensureInitialized().equalsValue(
      this as ToolResult,
      other,
    );
  }

  @override
  int get hashCode {
    return ToolResultMapper.ensureInitialized().hashValue(this as ToolResult);
  }
}

extension ToolResultValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ToolResult, $Out> {
  ToolResultCopyWith<$R, ToolResult, $Out> get $asToolResult =>
      $base.as((v, t, t2) => _ToolResultCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ToolResultCopyWith<$R, $In extends ToolResult, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? name,
    String? id,
    dynamic result,
    String? error,
    Exception? exception,
  });
  ToolResultCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ToolResultCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ToolResult, $Out>
    implements ToolResultCopyWith<$R, ToolResult, $Out> {
  _ToolResultCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ToolResult> $mapper =
      ToolResultMapper.ensureInitialized();
  @override
  $R call({
    String? name,
    Object? id = $none,
    Object? result = $none,
    Object? error = $none,
    Object? exception = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (name != null) #name: name,
          if (id != $none) #id: id,
          if (result != $none) #result: result,
          if (error != $none) #error: error,
          if (exception != $none) #exception: exception,
        }),
      );
  @override
  ToolResult $make(CopyWithData data) => ToolResult(
        name: data.get(#name, or: $value.name),
        id: data.get(#id, or: $value.id),
        result: data.get(#result, or: $value.result),
        error: data.get(#error, or: $value.error),
        exception: data.get(#exception, or: $value.exception),
      );

  @override
  ToolResultCopyWith<$R2, ToolResult, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _ToolResultCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
