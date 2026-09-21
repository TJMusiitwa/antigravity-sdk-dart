import 'package:dart_mappable/dart_mappable.dart';

import 'exceptions.dart';

part 'compaction.mapper.dart';

/// Context compaction policy for an agent session.
///
/// Antigravity manages context by compacting older conversation history when
/// the active trajectory exceeds [tokenThreshold].
///
/// Example:
/// ```dart
/// final config = CompactionConfig(tokenThreshold: 50000);
/// ```
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class CompactionConfig with CompactionConfigMappable {
  /// Token ceiling allowed for the conversation history before compaction
  /// occurs. When null, the backend's default limit is used. Must be > 0.
  final int? tokenThreshold;

  CompactionConfig({
    this.tokenThreshold,
  }) {
    _validatePositive('tokenThreshold', tokenThreshold);
  }

  /// Deprecated alias for [tokenThreshold].
  ///
  /// Use [tokenThreshold] directly instead.
  @Deprecated(
    'Use tokenThreshold on CompactionConfig directly. '
    'checkpointIntervalTokens was removed in v0.1.17.',
  )
  int? get checkpointIntervalTokens => tokenThreshold;

  static void _validatePositive(String name, int? value) {
    if (value != null && value <= 0) {
      throw AntigravityValidationException(
        '$name must be greater than 0, got $value',
      );
    }
  }

  static const fromMap = CompactionConfigMapper.fromMap;
  static const fromJson = CompactionConfigMapper.fromJson;
}
