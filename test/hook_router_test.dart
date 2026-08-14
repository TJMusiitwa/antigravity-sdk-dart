import 'dart:async';
import 'package:antigravity/antigravity.dart';
import 'package:antigravity/src/connections/local/hook_router.dart';
import 'package:test/test.dart';

class MockSessionStartHook extends OnSessionStartHook {
  bool called = false;
  @override
  Future<void> run(HookContext context, void data) async {
    called = true;
  }
}

class MockSessionEndHook extends OnSessionEndHook {
  bool called = false;
  @override
  Future<void> run(HookContext context, void data) async {
    called = true;
  }
}

class MockPreTurnHook extends PreTurnHook {
  final HookResult result;
  MockPreTurnHook(this.result);
  @override
  Future<HookResult> run(HookContext context, ContentPrimitive data) async {
    return result;
  }
}

class MockPostTurnHook extends PostTurnHook {
  String? receivedResponse;
  @override
  Future<void> run(HookContext context, String data) async {
    receivedResponse = data;
  }
}

class MockPostToolCallHook extends PostToolCallHook {
  ToolResult? receivedResult;
  @override
  Future<void> run(HookContext context, ToolResult data) async {
    receivedResult = data;
  }
}

class MockPreToolCallDecideHook extends PreToolCallDecideHook {
  final HookResult result;
  ToolCall? receivedToolCall;
  MockPreToolCallDecideHook(this.result);

  @override
  Future<HookResult> run(HookContext context, ToolCall data) async {
    receivedToolCall = data;
    return result;
  }
}

class MockOnToolErrorHook extends OnToolErrorHook {
  Exception? receivedError;
  dynamic returnValue;

  MockOnToolErrorHook({this.returnValue});

  @override
  Future<dynamic> run(HookContext context, Exception data) async {
    receivedError = data;
    return returnValue;
  }
}

void main() {
  group('HookRouter', () {
    test('handles session start and end hooks', () async {
      final sessionStart = MockSessionStartHook();
      final sessionEnd = MockSessionEndHook();
      final runner = HookRunner(
        onSessionStartHooks: [sessionStart],
        onSessionEndHooks: [sessionEnd],
      );

      final sentEvents = <Map<String, dynamic>>[];
      final router = HookRouter(runner, (evt) async {
        sentEvents.add(evt);
      });

      await router.handle({
        'request_id': 'req-1',
        'type': 'LIFECYCLE_HOOK_ON_SESSION_START',
      });

      expect(sessionStart.called, isTrue);
      expect(
          sentEvents.last['call_hook_response']['request_id'], equals('req-1'));
      expect(sentEvents.last['call_hook_response']['empty_result'], isNotNull);

      await router.handle({
        'request_id': 'req-2',
        'type': 'LIFECYCLE_HOOK_ON_SESSION_END',
      });

      expect(sessionEnd.called, isTrue);
      expect(
          sentEvents.last['call_hook_response']['request_id'], equals('req-2'));
    });

    test('handles pre turn hook allowing turn', () async {
      final preTurn = MockPreTurnHook(HookResult(allow: true));
      final runner = HookRunner(preTurnHooks: [preTurn]);
      final sentEvents = <Map<String, dynamic>>[];
      final router = HookRouter(runner, (evt) async {
        sentEvents.add(evt);
      });

      await router.handle({
        'request_id': 'req-3',
        'type': 'LIFECYCLE_HOOK_PRE_TURN',
        'pre_turn_args': {
          'user_input': {
            'parts': [
              {'text': 'Hello agent'}
            ]
          }
        }
      });

      expect(
          sentEvents.last['call_hook_response']['request_id'], equals('req-3'));
      final preTurnResult =
          sentEvents.last['call_hook_response']['pre_turn_result'];
      expect(preTurnResult['decision'], equals('ALLOW'));
    });

    test('handles pre turn hook denying turn', () async {
      final preTurn =
          MockPreTurnHook(HookResult(allow: false, message: 'Policy Deny'));
      final runner = HookRunner(preTurnHooks: [preTurn]);
      final sentEvents = <Map<String, dynamic>>[];
      final router = HookRouter(runner, (evt) async {
        sentEvents.add(evt);
      });

      await router.handle({
        'request_id': 'req-4',
        'type': 'LIFECYCLE_HOOK_PRE_TURN',
      });

      final preTurnResult =
          sentEvents.last['call_hook_response']['pre_turn_result'];
      expect(preTurnResult['decision'], equals('DENY'));
      expect(preTurnResult['reason'], equals('Policy Deny'));
    });

    test('handles post turn hook', () async {
      final postTurn = MockPostTurnHook();
      final runner = HookRunner(postTurnHooks: [postTurn]);
      final sentEvents = <Map<String, dynamic>>[];
      final router = HookRouter(runner, (evt) async {
        sentEvents.add(evt);
      });

      await router.handle({
        'request_id': 'req-5',
        'type': 'LIFECYCLE_HOOK_POST_TURN',
        'post_turn_args': {
          'response_text': 'Completed successfully',
        }
      });

      expect(postTurn.receivedResponse, equals('Completed successfully'));
    });

    test('handles post tool hook with structured results extraction', () async {
      final postTool = MockPostToolCallHook();
      final runner = HookRunner(postToolCallHooks: [postTool]);
      final sentEvents = <Map<String, dynamic>>[];
      final router = HookRouter(
        runner,
        (evt) async {
          sentEvents.add(evt);
        },
        resultExtractor: extractToolResult,
      );

      await router.handle({
        'request_id': 'req-6',
        'type': 'LIFECYCLE_HOOK_POST_TOOL',
        'post_tool_args': {
          'tool_name': 'read_url_content',
          'step_update': {
            'read_url_content': {
              'title': 'Google Home',
              'summary': 'Home of search engine',
              'content_path': '/tmp/google.html',
            }
          }
        }
      });

      final tr = postTool.receivedResult;
      expect(tr, isNotNull);
      expect(tr!.name, equals('read_url_content'));
      expect(tr.result, isA<ReadUrlContentResult>());
      final r = tr.result as ReadUrlContentResult;
      expect(r.title, equals('Google Home'));
      expect(r.summary, equals('Home of search engine'));
      expect(r.contentPath, equals('/tmp/google.html'));
    });

    test('handles tool error hook', () async {
      final toolErrorHook = MockOnToolErrorHook();
      final runner = HookRunner(onToolErrorHooks: [toolErrorHook]);
      final sentEvents = <Map<String, dynamic>>[];
      final router = HookRouter(runner, (evt) async {
        sentEvents.add(evt);
      });

      await router.handle({
        'request_id': 'req-7',
        'type': 'LIFECYCLE_HOOK_ON_TOOL_ERROR',
        'on_tool_error_args': {
          'error': 'Failed to execute tool',
          'tool_name': 'view_file',
          'server_name': 'mcp_server_1',
        }
      });

      expect(toolErrorHook.receivedError, isA<ToolExecutionException>());
      final err = toolErrorHook.receivedError as ToolExecutionException;
      expect(err.message, equals('Failed to execute tool'));
      expect(err.toolName, equals('view_file'));
      expect(err.serverName, equals('mcp_server_1'));
      expect(
          sentEvents.last['call_hook_response']['request_id'], equals('req-7'));
      expect(sentEvents.last['call_hook_response']['empty_result'], isNotNull);
    });

    test('handles pre tool call hook allowing tool', () async {
      final preTool = MockPreToolCallDecideHook(HookResult(allow: true));
      final runner = HookRunner(preToolCallDecideHooks: [preTool]);
      final sentEvents = <Map<String, dynamic>>[];
      final router = HookRouter(runner, (evt) async {
        sentEvents.add(evt);
      });

      await router.handle({
        'request_id': 'req-8',
        'type': 'LIFECYCLE_HOOK_PRE_TOOL',
        'pre_tool_args': {
          'tool_name': 'view_file',
          'arguments_json': '{"path": "file:///workspace/example.txt"}',
          'server_name': 'filesystem',
          'call_id': 'call-123',
        },
      });

      expect(preTool.receivedToolCall, isNotNull);
      expect(preTool.receivedToolCall!.name, equals('view_file'));
      expect(preTool.receivedToolCall!.serverName, equals('filesystem'));
      expect(preTool.receivedToolCall!.effectiveCallId, equals('call-123'));
      expect(preTool.receivedToolCall!.canonicalPath, equals('/workspace/example.txt'));

      expect(sentEvents.last['call_hook_response']['request_id'], equals('req-8'));
      final preToolResult = sentEvents.last['call_hook_response']['pre_tool_result'];
      expect(preToolResult['decision'], equals('ALLOW'));
    });

    test('handles pre tool call hook denying tool', () async {
      final preTool = MockPreToolCallDecideHook(
        HookResult(allow: false, message: 'Policy denied execution'),
      );
      final runner = HookRunner(preToolCallDecideHooks: [preTool]);
      final sentEvents = <Map<String, dynamic>>[];
      final router = HookRouter(runner, (evt) async {
        sentEvents.add(evt);
      });

      await router.handle({
        'request_id': 'req-9',
        'type': 'LIFECYCLE_HOOK_PRE_TOOL',
        'pre_tool_args': {
          'tool_name': 'run_command',
          'arguments_json': '{"command": "rm -rf /"}',
          'call_id': 'call-456',
        },
      });

      expect(preTool.receivedToolCall, isNotNull);
      expect(preTool.receivedToolCall!.name, equals('run_command'));
      expect(sentEvents.last['call_hook_response']['request_id'], equals('req-9'));
      final preToolResult = sentEvents.last['call_hook_response']['pre_tool_result'];
      expect(preToolResult['decision'], equals('DENY'));
      expect(preToolResult['reason'], equals('Policy denied execution'));
    });
  });
}
