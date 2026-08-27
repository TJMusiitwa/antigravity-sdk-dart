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

void main() {
  group('ToolResult metadata preservation', () {
    test('serializes and deserializes server_name field', () {
      final res = ToolResult(
        id: 'tc-1',
        callId: 'call-1',
        stepId: 'traj:1',
        serverName: 'mcp-weather',
        name: 'get_weather',
        result: {'temp': 72},
      );

      final map = res.toMap();
      expect(map['server_name'], equals('mcp-weather'));
      expect(map['call_id'], equals('call-1'));
      expect(map['step_id'], equals('traj:1'));
      expect(map['id'], equals('tc-1'));

      final fromMap = ToolResultMapper.fromMap(map);
      expect(fromMap.serverName, equals('mcp-weather'));
      expect(fromMap.callId, equals('call-1'));
      expect(fromMap.stepId, equals('traj:1'));
      expect(fromMap.id, equals('tc-1'));
    });

    test(
        'ToolRunner.processToolCalls preserves all metadata on successful execution',
        () async {
      final runner = ToolRunner(
        tools: [
          Tool(
            name: 'calc',
            description: 'Simple calculation',
            schema: {},
            handler: (args, ctx) async =>
                (args['a'] as num) + (args['b'] as num),
          ),
        ],
      );

      final calls = [
        ToolCall(
          name: 'calc',
          args: {'a': 10, 'b': 20},
          id: 'call-id-success',
          callId: 'call-id-success',
          stepId: 'step-10',
          serverName: 'calc-server',
        ),
      ];

      final results = await runner.processToolCalls(calls);
      expect(results.length, equals(1));
      final res = results.first;

      expect(res.name, equals('calc'));
      expect(res.id, equals('call-id-success'));
      expect(res.callId, equals('call-id-success'));
      expect(res.stepId, equals('step-10'));
      expect(res.serverName, equals('calc-server'));
      expect(res.result, equals(30));
      expect(res.error, isNull);
    });

    test('ToolRunner.processToolCalls preserves all metadata on unknown tool',
        () async {
      final runner = ToolRunner(tools: []);

      final calls = [
        ToolCall(
          name: 'non_existent_tool',
          args: {},
          id: 'call-id-unknown',
          callId: 'call-id-unknown',
          stepId: 'step-11',
          serverName: 'server-alpha',
        ),
      ];

      final results = await runner.processToolCalls(calls);
      expect(results.length, equals(1));
      final res = results.first;

      expect(res.name, equals('non_existent_tool'));
      expect(res.id, equals('call-id-unknown'));
      expect(res.callId, equals('call-id-unknown'));
      expect(res.stepId, equals('step-11'));
      expect(res.serverName, equals('server-alpha'));
      expect(res.error, contains("Unknown tool: 'non_existent_tool'"));
    });

    test('ToolRunner.processToolCalls preserves all metadata on exception',
        () async {
      final runner = ToolRunner(
        tools: [
          Tool(
            name: 'failing_tool',
            description: 'Throws error',
            schema: {},
            handler: (args, ctx) async =>
                throw FormatException('Invalid format in tool'),
          ),
        ],
      );

      final calls = [
        ToolCall(
          name: 'failing_tool',
          args: {},
          id: 'call-id-fail',
          callId: 'call-id-fail',
          stepId: 'step-12',
          serverName: 'fail-server',
        ),
      ];

      final results = await runner.processToolCalls(calls);
      expect(results.length, equals(1));
      final res = results.first;

      expect(res.name, equals('failing_tool'));
      expect(res.id, equals('call-id-fail'));
      expect(res.callId, equals('call-id-fail'));
      expect(res.stepId, equals('step-12'));
      expect(res.serverName, equals('fail-server'));
      expect(res.error, contains('Invalid format in tool'));
      expect(res.exception, isNotNull);
    });
  });
}
