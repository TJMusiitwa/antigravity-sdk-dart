// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'stop.dart';

/// @nodoc

class StopDecisionMapper extends EnumMapper<StopDecision> {
  StopDecisionMapper._();

  static StopDecisionMapper? _instance;
  static StopDecisionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = StopDecisionMapper._());
    }
    return _instance!;
  }

  static StopDecision fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  StopDecision decode(dynamic value) {
    switch (value) {
      case 'ALLOW_STOP':
        return StopDecision.allowStop;
      case 'CONTINUE':
        return StopDecision.continueTurn;
      default:
        return StopDecision.values[0];
    }
  }

  @override
  dynamic encode(StopDecision self) {
    switch (self) {
      case StopDecision.allowStop:
        return 'ALLOW_STOP';
      case StopDecision.continueTurn:
        return 'CONTINUE';
    }
  }
}

/// @nodoc

extension StopDecisionMapperExtension on StopDecision {
  dynamic toValue() {
    StopDecisionMapper.ensureInitialized();
    return MapperContainer.globals.toValue<StopDecision>(this);
  }
}

/// @nodoc
class StopHookResultMapper extends ClassMapperBase<StopHookResult> {
  StopHookResultMapper._();

  static StopHookResultMapper? _instance;
  static StopHookResultMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = StopHookResultMapper._());
      StopDecisionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'StopHookResult';

  static StopDecision _$decision(StopHookResult v) => v.decision;
  static const Field<StopHookResult, StopDecision> _f$decision = Field(
    'decision',
    _$decision,
    opt: true,
    def: StopDecision.allowStop,
  );
  static String _$reason(StopHookResult v) => v.reason;
  static const Field<StopHookResult, String> _f$reason = Field(
    'reason',
    _$reason,
    opt: true,
    def: '',
  );

  @override
  final MappableFields<StopHookResult> fields = const {
    #decision: _f$decision,
    #reason: _f$reason,
  };
  @override
  final bool ignoreNull = true;

  static StopHookResult _instantiate(DecodingData data) {
    return StopHookResult(
      decision: data.dec(_f$decision),
      reason: data.dec(_f$reason),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static StopHookResult fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<StopHookResult>(map);
  }

  static StopHookResult fromJson(String json) {
    return ensureInitialized().decodeJson<StopHookResult>(json);
  }
}

/// @nodoc
mixin StopHookResultMappable {
  String toJson() {
    return StopHookResultMapper.ensureInitialized().encodeJson<StopHookResult>(
      this as StopHookResult,
    );
  }

  Map<String, dynamic> toMap() {
    return StopHookResultMapper.ensureInitialized().encodeMap<StopHookResult>(
      this as StopHookResult,
    );
  }

  StopHookResultCopyWith<StopHookResult, StopHookResult, StopHookResult>
      get copyWith =>
          _StopHookResultCopyWithImpl<StopHookResult, StopHookResult>(
            this as StopHookResult,
            $identity,
            $identity,
          );
  @override
  String toString() {
    return StopHookResultMapper.ensureInitialized().stringifyValue(
      this as StopHookResult,
    );
  }

  @override
  bool operator ==(Object other) {
    return StopHookResultMapper.ensureInitialized().equalsValue(
      this as StopHookResult,
      other,
    );
  }

  @override
  int get hashCode {
    return StopHookResultMapper.ensureInitialized().hashValue(
      this as StopHookResult,
    );
  }
}

/// @nodoc
extension StopHookResultValueCopy<$R, $Out>
    on ObjectCopyWith<$R, StopHookResult, $Out> {
  StopHookResultCopyWith<$R, StopHookResult, $Out> get $asStopHookResult =>
      $base.as((v, t, t2) => _StopHookResultCopyWithImpl<$R, $Out>(v, t, t2));
}

/// @nodoc
abstract class StopHookResultCopyWith<$R, $In extends StopHookResult, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({StopDecision? decision, String? reason});
  StopHookResultCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

/// @nodoc
class _StopHookResultCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, StopHookResult, $Out>
    implements StopHookResultCopyWith<$R, StopHookResult, $Out> {
  _StopHookResultCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<StopHookResult> $mapper =
      StopHookResultMapper.ensureInitialized();
  @override
  $R call({StopDecision? decision, String? reason}) => $apply(
        FieldCopyWithData({
          if (decision != null) #decision: decision,
          if (reason != null) #reason: reason,
        }),
      );
  @override
  StopHookResult $make(CopyWithData data) => StopHookResult(
        decision: data.get(#decision, or: $value.decision),
        reason: data.get(#reason, or: $value.reason),
      );

  @override
  StopHookResultCopyWith<$R2, StopHookResult, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _StopHookResultCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

/// @nodoc
class StopArgsMapper extends ClassMapperBase<StopArgs> {
  StopArgsMapper._();

  static StopArgsMapper? _instance;
  static StopArgsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = StopArgsMapper._());
      StopReasonMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'StopArgs';

  static String _$responseText(StopArgs v) => v.responseText;
  static const Field<StopArgs, String> _f$responseText = Field(
    'responseText',
    _$responseText,
    key: r'response_text',
    opt: true,
    def: '',
  );
  static String _$trajectoryId(StopArgs v) => v.trajectoryId;
  static const Field<StopArgs, String> _f$trajectoryId = Field(
    'trajectoryId',
    _$trajectoryId,
    key: r'trajectory_id',
    opt: true,
    def: '',
  );
  static int _$continuationCount(StopArgs v) => v.continuationCount;
  static const Field<StopArgs, int> _f$continuationCount = Field(
    'continuationCount',
    _$continuationCount,
    key: r'continuation_count',
    opt: true,
    def: 0,
  );
  static StopReason _$stopReason(StopArgs v) => v.stopReason;
  static const Field<StopArgs, StopReason> _f$stopReason = Field(
    'stopReason',
    _$stopReason,
    key: r'stop_reason',
    opt: true,
    def: StopReason.unspecified,
  );
  static String _$errorMessage(StopArgs v) => v.errorMessage;
  static const Field<StopArgs, String> _f$errorMessage = Field(
    'errorMessage',
    _$errorMessage,
    key: r'error_message',
    opt: true,
    def: '',
  );

  @override
  final MappableFields<StopArgs> fields = const {
    #responseText: _f$responseText,
    #trajectoryId: _f$trajectoryId,
    #continuationCount: _f$continuationCount,
    #stopReason: _f$stopReason,
    #errorMessage: _f$errorMessage,
  };
  @override
  final bool ignoreNull = true;

  static StopArgs _instantiate(DecodingData data) {
    return StopArgs(
      responseText: data.dec(_f$responseText),
      trajectoryId: data.dec(_f$trajectoryId),
      continuationCount: data.dec(_f$continuationCount),
      stopReason: data.dec(_f$stopReason),
      errorMessage: data.dec(_f$errorMessage),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static StopArgs fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<StopArgs>(map);
  }

  static StopArgs fromJson(String json) {
    return ensureInitialized().decodeJson<StopArgs>(json);
  }
}

/// @nodoc
mixin StopArgsMappable {
  String toJson() {
    return StopArgsMapper.ensureInitialized().encodeJson<StopArgs>(
      this as StopArgs,
    );
  }

  Map<String, dynamic> toMap() {
    return StopArgsMapper.ensureInitialized().encodeMap<StopArgs>(
      this as StopArgs,
    );
  }

  StopArgsCopyWith<StopArgs, StopArgs, StopArgs> get copyWith =>
      _StopArgsCopyWithImpl<StopArgs, StopArgs>(
        this as StopArgs,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return StopArgsMapper.ensureInitialized().stringifyValue(this as StopArgs);
  }

  @override
  bool operator ==(Object other) {
    return StopArgsMapper.ensureInitialized().equalsValue(
      this as StopArgs,
      other,
    );
  }

  @override
  int get hashCode {
    return StopArgsMapper.ensureInitialized().hashValue(this as StopArgs);
  }
}

/// @nodoc
extension StopArgsValueCopy<$R, $Out> on ObjectCopyWith<$R, StopArgs, $Out> {
  StopArgsCopyWith<$R, StopArgs, $Out> get $asStopArgs =>
      $base.as((v, t, t2) => _StopArgsCopyWithImpl<$R, $Out>(v, t, t2));
}

/// @nodoc
abstract class StopArgsCopyWith<$R, $In extends StopArgs, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? responseText,
    String? trajectoryId,
    int? continuationCount,
    StopReason? stopReason,
    String? errorMessage,
  });
  StopArgsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

/// @nodoc
class _StopArgsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, StopArgs, $Out>
    implements StopArgsCopyWith<$R, StopArgs, $Out> {
  _StopArgsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<StopArgs> $mapper =
      StopArgsMapper.ensureInitialized();
  @override
  $R call({
    String? responseText,
    String? trajectoryId,
    int? continuationCount,
    StopReason? stopReason,
    String? errorMessage,
  }) =>
      $apply(
        FieldCopyWithData({
          if (responseText != null) #responseText: responseText,
          if (trajectoryId != null) #trajectoryId: trajectoryId,
          if (continuationCount != null) #continuationCount: continuationCount,
          if (stopReason != null) #stopReason: stopReason,
          if (errorMessage != null) #errorMessage: errorMessage,
        }),
      );
  @override
  StopArgs $make(CopyWithData data) => StopArgs(
        responseText: data.get(#responseText, or: $value.responseText),
        trajectoryId: data.get(#trajectoryId, or: $value.trajectoryId),
        continuationCount: data.get(
          #continuationCount,
          or: $value.continuationCount,
        ),
        stopReason: data.get(#stopReason, or: $value.stopReason),
        errorMessage: data.get(#errorMessage, or: $value.errorMessage),
      );

  @override
  StopArgsCopyWith<$R2, StopArgs, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _StopArgsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
