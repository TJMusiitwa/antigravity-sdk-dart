import 'package:dart_mappable/dart_mappable.dart';

import 'exceptions.dart';

part 'compaction.mapper.dart';

/// Context compaction policy for an agent session.
///
/// Controls when the harness writes history checkpoints (summaries) and the
/// hard ceiling on the context window before older turns are evicted.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class CompactionConfig with CompactionConfigMappable {
  /// Maximum tokens per history segment before a compaction checkpoint is written.
  final int? checkpointIntervalTokens;

  /// Hard cap on the total context window before compaction is triggered.
  final int? maxContextTokens;

  CompactionConfig({
    int? checkpointIntervalTokens,
    this.maxContextTokens,
    @Deprecated('Use checkpointIntervalTokens on CompactionConfig directly')
    int? compactionThreshold,
  }) : checkpointIntervalTokens =
            checkpointIntervalTokens ?? compactionThreshold {
    if (checkpointIntervalTokens != null &&
        compactionThreshold != null &&
        checkpointIntervalTokens != compactionThreshold) {
      throw AntigravityValidationException(
        'checkpointIntervalTokens and the deprecated compactionThreshold '
        'alias were both provided with conflicting values '
        '($checkpointIntervalTokens vs $compactionThreshold).',
      );
    }
    _validatePositive(
        'checkpointIntervalTokens', this.checkpointIntervalTokens);
    _validatePositive('maxContextTokens', maxContextTokens);
    if (this.checkpointIntervalTokens != null &&
        maxContextTokens != null &&
        this.checkpointIntervalTokens! > maxContextTokens!) {
      throw AntigravityValidationException(
        'checkpointIntervalTokens (${this.checkpointIntervalTokens}) must be '
        'less than or equal to maxContextTokens ($maxContextTokens).',
      );
    }
  }

  /// The deprecated alias for [checkpointIntervalTokens].
  @Deprecated('Use checkpointIntervalTokens on CompactionConfig directly')
  int? get compactionThreshold => checkpointIntervalTokens;

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
