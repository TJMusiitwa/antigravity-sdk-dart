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

import 'dart:async';
import 'package:antigravity/antigravity.dart';
import 'package:antigravity/src/connections/local/hook_router.dart';
import 'package:test/test.dart';

class MockStopHook extends StopHook {
  HookContext? receivedContext;
  final List<HookContext> receivedContexts = [];
  StopArgs? receivedArgs;
  final StopHookResult Function(HookContext context, StopArgs args) onRun;

  MockStopHook(StopHookResult Function(StopArgs args) handler)
      : onRun = ((context, args) => handler(args));

  MockStopHook.withContext(this.onRun);

  @override
  Future<StopHookResult?> run(HookContext context, StopArgs data) async {
    receivedContext = context;
    receivedContexts.add(context);
    receivedArgs = data;
    return onRun(context, data);
  }
}

void main() {
  group('HookRouter - LIFECYCLE_HOOK_STOP', () {
    test('handles LIFECYCLE_HOOK_STOP with ALLOW_STOP decision', () async {
      final mock = MockStopHook((args) {
        return StopHookResult(decision: StopDecision.allowStop);
      });
      final runner = HookRunner(stopHooks: [mock]);
      final sentEvents = <Map<String, dynamic>>[];
      final router = HookRouter(runner, (evt) async {
        sentEvents.add(evt);
      });

      await router.handle({
        'request_id': 'req-stop-1',
        'type': 'LIFECYCLE_HOOK_STOP',
        'stop_args': {
          'response_text': 'Here is your summary.',
          'trajectory_id': 'traj-100',
          'continuation_count': 0,
          'stop_reason': 'STOP_REASON_MAX_MODEL_CALLS_EXCEEDED',
          'error_message': '',
        },
      });

      expect(mock.receivedArgs, isNotNull);
      expect(mock.receivedArgs!.responseText, equals('Here is your summary.'));
      expect(mock.receivedArgs!.trajectoryId, equals('traj-100'));
      expect(mock.receivedArgs!.continuationCount, equals(0));
      expect(mock.receivedArgs!.stopReason,
          equals(StopReason.maxModelCallsExceeded));

      expect(sentEvents.length, equals(1));
      final resp = sentEvents.first['call_hook_response'];
      expect(resp['request_id'], equals('req-stop-1'));
      final stopResult = resp['stop_result'];
      expect(stopResult['decision'], equals('ALLOW_STOP'));
      expect(stopResult.containsKey('reason'), isFalse);
    });

    test('handles LIFECYCLE_HOOK_STOP with CONTINUE decision and reason',
        () async {
      final mock = MockStopHook((args) {
        return StopHookResult(
          decision: StopDecision.continueTurn,
          reason: 'Please elaborate on the implications.',
        );
      });
      final runner = HookRunner(stopHooks: [mock]);
      final sentEvents = <Map<String, dynamic>>[];
      final router = HookRouter(runner, (evt) async {
        sentEvents.add(evt);
      });

      await router.handle({
        'request_id': 'req-stop-2',
        'type': 'LIFECYCLE_HOOK_STOP',
        'stop_args': {
          'response_text': 'Brief fact.',
          'trajectory_id': 'traj-200',
          'continuation_count': 1,
          'stop_reason': 'STOP_REASON_UNSPECIFIED',
        },
      });

      expect(mock.receivedArgs, isNotNull);
      expect(mock.receivedArgs!.continuationCount, equals(1));

      final resp = sentEvents.first['call_hook_response'];
      expect(resp['request_id'], equals('req-stop-2'));
      final stopResult = resp['stop_result'];
      expect(stopResult['decision'], equals('CONTINUE'));
      expect(stopResult['reason'],
          equals('Please elaborate on the implications.'));
    });

    test('handles bare STOP type string and empty stop_args', () async {
      final mock = MockStopHook((args) => StopHookResult());
      final runner = HookRunner(stopHooks: [mock]);
      final sentEvents = <Map<String, dynamic>>[];
      final router = HookRouter(runner, (evt) async => sentEvents.add(evt));

      await router.handle({
        'request_id': 'req-stop-3',
        'type': 'STOP',
      });

      expect(mock.receivedArgs, isNotNull);
      expect(mock.receivedArgs!.responseText, equals(''));

      final resp = sentEvents.first['call_hook_response'];
      expect(resp['request_id'], equals('req-stop-3'));
      expect(resp['stop_result']['decision'], equals('ALLOW_STOP'));
    });

    test('trims reason with leading and trailing whitespace on wire', () async {
      final mock = MockStopHook((args) {
        return StopHookResult(
          decision: StopDecision.continueTurn,
          reason: '  Please elaborate.  ',
        );
      });
      final runner = HookRunner(stopHooks: [mock]);
      final sentEvents = <Map<String, dynamic>>[];
      final router = HookRouter(runner, (evt) async => sentEvents.add(evt));

      await router.handle({
        'request_id': 'req-stop-trim',
        'type': 'LIFECYCLE_HOOK_STOP',
        'stop_args': {
          'response_text': 'Draft answer.',
          'trajectory_id': 'traj-trim',
          'continuation_count': 0,
        },
      });

      final resp = sentEvents.first['call_hook_response'];
      expect(resp['request_id'], equals('req-stop-trim'));
      final stopResult = resp['stop_result'];
      expect(stopResult['decision'], equals('CONTINUE'));
      expect(stopResult['reason'], equals('Please elaborate.'));
    });

    test(
        'retains currentTurnContext on continueTurn and clears it on allowStop',
        () async {
      var callCount = 0;
      final mock = MockStopHook.withContext((context, args) {
        callCount++;
        if (callCount == 1) {
          return StopHookResult(
            decision: StopDecision.continueTurn,
            reason: 'Continue cycle',
          );
        }
        return StopHookResult(decision: StopDecision.allowStop);
      });

      final runner = HookRunner(stopHooks: [mock]);
      final sentEvents = <Map<String, dynamic>>[];
      final router = HookRouter(runner, (evt) async => sentEvents.add(evt));

      // Call 1: returns continueTurn -> retains context
      await router.handle({
        'request_id': 'req-turn-1',
        'type': 'LIFECYCLE_HOOK_STOP',
        'stop_args': {'response_text': 'turn 1'},
      });

      // Call 2: sequential call on same router -> should receive identical context, returns allowStop
      await router.handle({
        'request_id': 'req-turn-2',
        'type': 'LIFECYCLE_HOOK_STOP',
        'stop_args': {'response_text': 'turn 2'},
      });

      expect(mock.receivedContexts.length, equals(2));
      expect(mock.receivedContexts[1], same(mock.receivedContexts[0]));

      // Call 3: call following allowStop -> should receive a new, different context
      await router.handle({
        'request_id': 'req-turn-3',
        'type': 'LIFECYCLE_HOOK_STOP',
        'stop_args': {'response_text': 'turn 3'},
      });

      expect(mock.receivedContexts.length, equals(3));
      expect(mock.receivedContexts[2], isNot(same(mock.receivedContexts[1])));
    });
  });
}
