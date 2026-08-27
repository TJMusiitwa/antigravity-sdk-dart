// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:dart_mappable/dart_mappable.dart';
import 'config.dart';
import 'exceptions.dart';

part 'stop.mapper.dart';

/// Decision returned by a Stop lifecycle hook.
@MappableEnum(defaultValue: StopDecision.allowStop)
enum StopDecision {
  /// Allows the turn execution to terminate and transition to idle.
  @MappableValue('ALLOW_STOP')
  allowStop('ALLOW_STOP'),

  /// Blocks termination, injects reason as a system prompt, and resumes the agent loop.
  @MappableValue('CONTINUE')
  continueTurn('CONTINUE');

  /// The wire string representation.
  final String value;
  const StopDecision(this.value);

  /// Parses a [StopDecision] from a string, supporting proto-prefixed wire strings
  /// (e.g. `DECISION_CONTINUE`, `DECISION_ALLOW_STOP`, or `CONTINUE`, `ALLOW_STOP`).
  static StopDecision fromString(String val) {
    final normalized = val.toUpperCase().trim().replaceFirst('DECISION_', '');
    return switch (normalized) {
      'CONTINUE' => StopDecision.continueTurn,
      'ALLOW_STOP' || 'ALLOWSTOP' => StopDecision.allowStop,
      _ => StopDecision.allowStop,
    };
  }
}

/// Result returned by a Stop lifecycle hook.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class StopHookResult with StopHookResultMappable {
  /// Whether to allow the turn to stop or continue execution.
  final StopDecision decision;

  /// The prompt/feedback injected into the conversation when decision is [StopDecision.continueTurn].
  /// Must be non-empty when continueTurn is selected.
  final String reason;

  /// Creates a [StopHookResult] with the given [decision] and optional continuation [reason].
  StopHookResult({
    this.decision = StopDecision.allowStop,
    this.reason = '',
  }) {
    if (decision == StopDecision.continueTurn && reason.trim().isEmpty) {
      throw AntigravityValidationException(
        'StopHookResult with decision=CONTINUE requires a non-empty reason.',
      );
    }
  }

  factory StopHookResult.fromMap(Map<String, dynamic> map) =>
      StopHookResultMapper.fromMap(map);
  factory StopHookResult.fromJson(String json) =>
      StopHookResultMapper.fromJson(json);
}

/// Arguments delivered to a Stop hook when the root turn reaches idle.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class StopArgs with StopArgsMappable {
  /// Most recent assistant response text in the turn.
  final String responseText;

  /// Unique identifier of the trajectory executing this turn.
  final String trajectoryId;

  /// The 0-based iteration count of Stop hook continuations within the current turn cycle.
  final int continuationCount;

  /// The reason why the trajectory stopped.
  final StopReason stopReason;

  /// Error message if execution stopped due to a fatal error.
  final String errorMessage;

  /// Creates a [StopArgs] instance describing the stopped trajectory.
  StopArgs({
    this.responseText = '',
    this.trajectoryId = '',
    this.continuationCount = 0,
    this.stopReason = StopReason.unspecified,
    this.errorMessage = '',
  });

  factory StopArgs.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('stop_reason') && map['stop_reason'] is String) {
      final copy = Map<String, dynamic>.from(map);
      copy['stop_reason'] = StopReason.fromString(map['stop_reason'] as String);
      return StopArgsMapper.fromMap(copy);
    }
    return StopArgsMapper.fromMap(map);
  }

  factory StopArgs.fromJson(String json) => StopArgsMapper.fromJson(json);
}
