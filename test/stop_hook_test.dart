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

import 'package:antigravity/antigravity.dart';
import 'package:test/test.dart';

class _CustomStopHook extends StopHook {
  final Future<StopHookResult?> Function(HookContext context, StopArgs data)
      _handler;
  _CustomStopHook(this._handler);

  @override
  Future<StopHookResult?> run(HookContext context, StopArgs data) =>
      _handler(context, data);
}

void main() {
  group('StopDecision', () {
    test('enum values and wire mapping', () {
      expect(StopDecision.allowStop.value, equals('ALLOW_STOP'));
      expect(StopDecision.continueTurn.value, equals('CONTINUE'));
    });

    test('fromString handles bare and prefixed strings', () {
      expect(StopDecision.fromString('CONTINUE'),
          equals(StopDecision.continueTurn));
      expect(StopDecision.fromString('DECISION_CONTINUE'),
          equals(StopDecision.continueTurn));
      expect(StopDecision.fromString('ALLOW_STOP'),
          equals(StopDecision.allowStop));
      expect(StopDecision.fromString('DECISION_ALLOW_STOP'),
          equals(StopDecision.allowStop));
      expect(StopDecision.fromString('DECISION_UNSPECIFIED'),
          equals(StopDecision.allowStop));
      expect(StopDecision.fromString('unknown_val'),
          equals(StopDecision.allowStop));
    });
  });

  group('StopHookResult', () {
    test('defaults to allowStop with empty reason', () {
      final res = StopHookResult();
      expect(res.decision, equals(StopDecision.allowStop));
      expect(res.reason, equals(''));
    });

    test('accepts valid continueTurn with non-empty reason', () {
      final res = StopHookResult(
        decision: StopDecision.continueTurn,
        reason: 'Please elaborate further.',
      );
      expect(res.decision, equals(StopDecision.continueTurn));
      expect(res.reason, equals('Please elaborate further.'));
    });

    test(
        'throws AntigravityValidationException when continueTurn has empty or blank reason',
        () {
      expect(
        () => StopHookResult(decision: StopDecision.continueTurn),
        throwsA(isA<AntigravityValidationException>()),
      );
      expect(
        () => StopHookResult(decision: StopDecision.continueTurn, reason: ''),
        throwsA(isA<AntigravityValidationException>()),
      );
      expect(
        () =>
            StopHookResult(decision: StopDecision.continueTurn, reason: '   '),
        throwsA(isA<AntigravityValidationException>()),
      );
    });

    test('serialization and deserialization', () {
      final res = StopHookResult(
        decision: StopDecision.continueTurn,
        reason: 'Review code',
      );
      final map = res.toMap();
      expect(map['decision'], equals('CONTINUE'));
      expect(map['reason'], equals('Review code'));

      final decoded = StopHookResult.fromMap(map);
      expect(decoded.decision, equals(StopDecision.continueTurn));
      expect(decoded.reason, equals('Review code'));
    });
  });

  group('StopArgs', () {
    test('default constructor values', () {
      final args = StopArgs();
      expect(args.responseText, equals(''));
      expect(args.trajectoryId, equals(''));
      expect(args.continuationCount, equals(0));
      expect(args.stopReason, equals(StopReason.unspecified));
      expect(args.errorMessage, equals(''));
    });

    test('custom values and serialization', () {
      final args = StopArgs(
        responseText: 'Partial answer',
        trajectoryId: 'traj-42',
        continuationCount: 2,
        stopReason: StopReason.maxModelCallsExceeded,
        errorMessage: 'Quota limit',
      );

      final map = args.toMap();
      expect(map['response_text'], equals('Partial answer'));
      expect(map['trajectory_id'], equals('traj-42'));
      expect(map['continuation_count'], equals(2));
      expect(map['stop_reason'], equals('MAX_MODEL_CALLS_EXCEEDED'));
      expect(map['error_message'], equals('Quota limit'));

      final decoded = StopArgs.fromMap(map);
      expect(decoded.responseText, equals('Partial answer'));
      expect(decoded.trajectoryId, equals('traj-42'));
      expect(decoded.continuationCount, equals(2));
      expect(decoded.stopReason, equals(StopReason.maxModelCallsExceeded));
      expect(decoded.errorMessage, equals('Quota limit'));
    });

    test('fromMap parses proto-prefixed stop_reason correctly', () {
      final map = {
        'response_text': 'done',
        'stop_reason': 'STOP_REASON_QUOTA_EXHAUSTED',
      };
      final decoded = StopArgs.fromMap(map);
      expect(decoded.stopReason, equals(StopReason.quotaExhausted));
    });
  });

  group('HookRunner with StopHook', () {
    test('hasHooks reflects presence of stopHooks', () {
      final runnerWithout = HookRunner();
      expect(runnerWithout.hasHooks, isFalse);

      final runnerWith = HookRunner(
        stopHooks: [
          FunctionStopHook.stateless((args) => StopHookResult()),
        ],
      );
      expect(runnerWith.hasHooks, isTrue);
    });

    test('registerHook dynamically registers StopHook', () {
      final runner = HookRunner();
      expect(runner.stopHooks, isEmpty);

      runner
          .registerHook(FunctionStopHook.stateless((args) => StopHookResult()));
      expect(runner.stopHooks.length, equals(1));
    });

    test('dispatchStop defaults to allowStop when no hooks registered',
        () async {
      final runner = HookRunner();
      final ctx = runner.createTurnContext();
      final res = await runner.dispatchStop(ctx, StopArgs());
      expect(res.decision, equals(StopDecision.allowStop));
    });

    test('dispatchStop returns allowStop when hook allows stop', () async {
      final runner = HookRunner(
        stopHooks: [
          FunctionStopHook.stateless(
            (args) => StopHookResult(decision: StopDecision.allowStop),
          ),
        ],
      );
      final ctx = runner.createTurnContext();
      final res = await runner.dispatchStop(
        ctx,
        StopArgs(responseText: 'done'),
      );
      expect(res.decision, equals(StopDecision.allowStop));
    });

    test('dispatchStop short-circuits on first continueTurn', () async {
      final callLog = <String>[];

      final hook1 = _CustomStopHook((ctx, data) async {
        callLog.add('hook1');
        return StopHookResult(
          decision: StopDecision.continueTurn,
          reason: 'Need more facts',
        );
      });

      final hook2 = _CustomStopHook((ctx, data) async {
        callLog.add('hook2');
        return StopHookResult(
          decision: StopDecision.continueTurn,
          reason: 'Should not run',
        );
      });

      final runner = HookRunner(stopHooks: [hook1, hook2]);
      final ctx = runner.createTurnContext();
      final res = await runner.dispatchStop(ctx, StopArgs());

      expect(res.decision, equals(StopDecision.continueTurn));
      expect(res.reason, equals('Need more facts'));
      expect(callLog, equals(['hook1']));
    });

    test('dispatchStop propagates exceptions from failing hook', () async {
      final runner = HookRunner(
        stopHooks: [
          FunctionStopHook.stateless(
              (args) => throw FormatException('crashed')),
        ],
      );
      final ctx = runner.createTurnContext();
      expect(
        () => runner.dispatchStop(ctx, StopArgs()),
        throwsA(isA<FormatException>()),
      );
    });

    test(
        'dispatchStop handles null result from hook by falling through to allowStop',
        () async {
      final runner = HookRunner(
        stopHooks: [
          _CustomStopHook((ctx, data) async => null),
        ],
      );
      final ctx = runner.createTurnContext();
      final res = await runner.dispatchStop(ctx, StopArgs());
      expect(res.decision, equals(StopDecision.allowStop));
    });
  });
}
