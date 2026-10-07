import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:antigravity/antigravity.dart';
import 'package:antigravity/src/connections/local/localharness_proto.dart';
import 'package:test/test.dart';

class _FakeProcess implements Process {
  @override
  Future<int> get exitCode => Future.value(0);
  @override
  Stream<List<int>> get stdout => const Stream.empty();
  @override
  Stream<List<int>> get stderr => const Stream.empty();
  @override
  IOSink get stdin {
    final controller = StreamController<List<int>>();
    controller.stream.listen((_) {});
    return IOSink(controller.sink);
  }

  @override
  int get pid => -1;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => true;
}

/// A loopback WebSocket pair standing in for the harness.
class _Harness {
  final HttpServer _server;
  final WebSocket client;
  final WebSocket _serverSide;
  final _sent = StreamController<Map<String, dynamic>>();
  late final StreamIterator<Map<String, dynamic>> _iterator =
      StreamIterator(_sent.stream);

  _Harness._(this._server, this.client, this._serverSide) {
    _serverSide.listen((message) =>
        _sent.add(jsonDecode(message as String) as Map<String, dynamic>));
  }

  static Future<_Harness> open() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final serverSide = Completer<WebSocket>();
    server.listen((request) async =>
        serverSide.complete(await WebSocketTransformer.upgrade(request)));
    final client = await WebSocket.connect('ws://127.0.0.1:${server.port}');
    return _Harness._(server, client, await serverSide.future);
  }

  /// Sends a GAOS server event to the connection.
  void push(Map<String, dynamic> event) => _serverSide.add(jsonEncode(event));

  /// The next event the connection sent to the harness.
  Future<Map<String, dynamic>> next() async {
    final hasNext =
        await _iterator.moveNext().timeout(const Duration(seconds: 2));
    if (!hasNext) throw StateError('Harness socket closed');
    return _iterator.current;
  }

  Future<void> close() async {
    await client.close();
    await _server.close(force: true);
  }
}

class _Log {
  final entries = <String>[];
}

class _SessionStart extends OnSessionStartHook {
  final _Log log;
  _SessionStart(this.log);
  @override
  Future<void> run(HookContext context, void data) async =>
      log.entries.add('start');
}

class _SessionEnd extends OnSessionEndHook {
  final _Log log;
  _SessionEnd(this.log);
  @override
  Future<void> run(HookContext context, void data) async =>
      log.entries.add('end');
}

class _PreTurn extends PreTurnHook {
  final _Log log;
  final bool allow;
  _PreTurn(this.log, {this.allow = true});
  @override
  Future<HookResult> run(HookContext context, ContentPrimitive data) async {
    log.entries.add('pre_turn:$data');
    return HookResult(allow: allow, message: allow ? '' : 'turn blocked');
  }
}

class _PostTurn extends PostTurnHook {
  final _Log log;
  final bool fail;
  _PostTurn(this.log, {this.fail = false});
  @override
  Future<void> run(HookContext context, String data) async {
    if (fail) throw StateError('boom');
    log.entries.add('post_turn:$data');
  }
}

class _PreTool extends PreToolCallDecideHook {
  final _Log log;
  final bool allow;
  _PreTool(this.log, {this.allow = true});
  @override
  Future<HookResult> run(HookContext context, ToolCall data) async {
    log.entries.add('pre_tool:${data.name}:${data.canonicalPath}');
    if (!allow) return HookResult(allow: false, message: 'tool blocked');
    return HookResult(
        allow: true,
        modifiedArgs: {'path': data.canonicalPath, 'max_lines': 10});
  }
}

class _PostTool extends PostToolCallHook {
  final _Log log;
  final results = <dynamic>[];
  _PostTool(this.log);
  @override
  Future<void> run(HookContext context, ToolResult data) async {
    results.add(data.result);
    log.entries.add('post_tool:${data.name}:${data.result}');
  }
}

class _ToolError extends OnToolErrorHook {
  final _Log log;
  _ToolError(this.log);
  @override
  Future<dynamic> run(HookContext context, Exception data) async {
    final error = data as ToolExecutionException;
    log.entries.add('on_tool_error:${error.toolName}:${error.message}');
    return 'Recovered error message';
  }
}

class _Compaction extends OnCompactionHook {
  final _Log log;
  _Compaction(this.log);
  @override
  Future<void> run(HookContext context, Step data) async =>
      log.entries.add('compaction:${data.content}');
}

class _Interaction extends OnInteractionHook {
  final List<int> batchSizes = [];
  @override
  Future<QuestionHookResult> run(
      HookContext context, AskQuestionInteractionSpec data) async {
    batchSizes.add(data.questions.length);
    return QuestionHookResult(responses: [
      QuestionResponse(selectedOptionIds: ['1']),
      QuestionResponse(selectedOptionIds: ['2']),
    ]);
  }
}

Map<String, dynamic> _hookRequest(String id, String type,
        [Map<String, dynamic> extra = const {}]) =>
    {
      'event_type': 'call_hook_request',
      'request_id': id,
      'type': type,
      'name': type,
      ...extra,
    };

Map<String, dynamic> _question(int index, String id, String text) => {
      'event_type': 'step.start',
      'index': index,
      'step': {
        'type': 'elicitation_call',
        'elicitation_id': id,
        'preamble': {
          'content': [
            {'type': 'text', 'text': text},
          ],
        },
        'multiple_choice_request': {
          'allow_multiple_selections': false,
          'choices': [
            {
              'label': '1',
              'display': [
                {'type': 'text', 'text': 'A'},
              ],
            },
            {
              'label': '2',
              'display': [
                {'type': 'text', 'text': 'B'},
              ],
            },
          ],
        },
      },
    };

void main() {
  late _Harness harness;
  late List<Step> steps;
  late List<Object> errors;

  setUp(() async {
    harness = await _Harness.open();
    steps = [];
    errors = [];
  });
  tearDown(() => harness.close());

  InteractionsConnection connect({
    ToolRunner? toolRunner,
    HookRunner? hookRunner,
    String root = 'root-1',
  }) {
    final connection = InteractionsConnection(
      process: _FakeProcess(),
      ws: harness.client,
      messageStream: harness.client,
      toolRunner: toolRunner ?? ToolRunner(),
      hookRunner: hookRunner ?? HookRunner(),
      rootInteractionId: root,
    );
    connection.receiveSteps().listen(steps.add, onError: errors.add);
    connection.startReaderLoop();
    return connection;
  }

  Future<void> idle() async {
    for (var i = 0; i < 200; i++) {
      if (steps.any((s) => s.id == 'idle_sentinel')) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('Timed out waiting for the idle sentinel.');
  }

  test('step lifecycle accumulates usage and the turn stop reason', () async {
    final connection = connect();
    await connection.send('Hi');
    expect(await harness.next(), {
      'event_type': 'input',
      'content': [
        {'type': 'text', 'text': 'Hi'},
      ],
    });
    expect(connection.isIdle, isFalse);
    harness
      ..push({
        'event_type': 'step.start',
        'index': 0,
        'step': {'type': 'model_output'},
      })
      ..push({
        'event_type': 'step.delta',
        'index': 0,
        'delta': {'type': 'text', 'text': 'Hello '},
      })
      ..push({
        'event_type': 'step.delta',
        'index': 0,
        'delta': {'type': 'text', 'text': 'world!'},
      })
      ..push({
        'event_type': 'step.stop',
        'index': 0,
        'usage': {
          'total_input_tokens': 10,
          'total_output_tokens': 5,
          'total_thought_tokens': 2,
          'total_cached_tokens': 3,
          'total_tokens': 17,
        },
      })
      ..push({
        'event_type': 'state_update',
        'state': 'fully_idle',
        'reason': 'max_model_calls_exceeded',
      });
    await idle();

    expect(connection.isIdle, isTrue);
    expect(connection.lastTurnStopReason, StopReason.maxModelCallsExceeded);
    final usage = connection.cumulativeUsage;
    expect(usage.promptTokenCount, 10);
    expect(usage.candidatesTokenCount, 5);
    expect(usage.thoughtsTokenCount, 2);
    expect(usage.cachedContentTokenCount, 3);
    expect(usage.totalTokenCount, 17);
    expect(connection.trajectoryUsages['root-1']!.totalTokenCount, 17);
    final emitted = steps.where((s) => s.id != 'idle_sentinel').toList();
    expect(emitted, hasLength(4));
    expect(emitted.first.status, StepStatus.active);
    expect(emitted.last.type, StepType.textResponse);
    expect(emitted.last.content, 'Hello world!');
    expect(emitted.last.status, StepStatus.done);
  });

  test('function_invocation runs the client tool and returns its result',
      () async {
    connect(
      toolRunner: ToolRunner(tools: [
        Tool(
          name: 'add_numbers',
          description: 'Adds two integers.',
          schema: const {},
          handler: (args, _) => (args['a'] as int) + (args['b'] as int),
        ),
      ]),
    );
    harness.push({
      'event_type': 'function_invocation',
      'call_id': 'call_add_1',
      'name': 'add_numbers',
      'arguments': {'a': 7, 'b': 8},
    });
    expect(await harness.next(), {
      'event_type': 'function_result',
      'call_id': 'call_add_1',
      'name': 'add_numbers',
      'is_error': false,
      'result': {'result': 15},
    });
    final call = steps.single;
    expect(call.type, StepType.toolCall);
    expect(call.trajectoryId, 'root-1');
    expect(call.toolCalls.single.args, {'a': 7, 'b': 8});
  });

  test('hook requests dispatch every lifecycle hook', () async {
    final log = _Log();
    final connection = connect(
      hookRunner: HookRunner(hooks: [
        _SessionStart(log),
        _PreTurn(log),
        _PreTool(log),
        _PostTool(log),
        _ToolError(log),
        _Compaction(log),
        FunctionStopHook((_, args) {
          log.entries.add('stop:${args.responseText}');
          return StopHookResult(
              decision: StopDecision.continueTurn, reason: 'Continue working');
        }),
        _PostTurn(log),
        _SessionEnd(log),
      ]),
    );

    harness.push(_hookRequest('req-start', 'on_session_start'));
    expect(await harness.next(), {
      'event_type': 'call_hook_response',
      'request_id': 'req-start',
      'empty_result': {},
    });

    harness.push(_hookRequest('req-pre-turn', 'pre_turn', {
      'pre_turn_args': {
        'user_input': {'type': 'user_input', 'content': 'original prompt'},
      },
    }));
    expect((await harness.next())['pre_turn_result'], {'decision': 'allow'});

    harness.push(_hookRequest('req-pre-tool', 'pre_tool', {
      'pre_tool_args': {
        'tool_name': 'view_file',
        'arguments_json': '{"path": "file:///tmp/test.py"}',
      },
    }));
    final preTool = await harness.next();
    expect(preTool['pre_tool_result'], {
      'decision': 'allow',
      'modified_args': {'path': '/tmp/test.py', 'max_lines': 10},
    });
    expect(
        preTool['pre_tool_result']['modified_args']['max_lines'], isA<int>());

    harness.push(_hookRequest('req-post-tool', 'post_tool', {
      'post_tool_args': {'tool_name': 'view_file', 'result': 'file contents'},
    }));
    expect(await harness.next(), {
      'event_type': 'call_hook_response',
      'request_id': 'req-post-tool',
      'empty_result': {},
    });

    harness.push(_hookRequest('req-tool-err', 'on_tool_error', {
      'on_tool_error_args': {
        'tool_name': 'run_command',
        'error_message': 'exit 1',
      },
    }));
    expect(await harness.next(), {
      'event_type': 'call_hook_response',
      'request_id': 'req-tool-err',
      'on_tool_error_result': {
        'custom_error_message': 'Recovered error message',
      },
    });

    harness.push(_hookRequest('req-compact', 'on_compaction', {
      'on_compaction_args': {
        'interaction_id': 'root-1',
        'step_index': 5,
        'summary': 'Compacted summary',
      },
    }));
    expect(await harness.next(), {
      'event_type': 'call_hook_response',
      'request_id': 'req-compact',
      'empty_result': {},
    });
    final compaction = steps.singleWhere((s) => s.type == StepType.compaction);
    expect(compaction.content, 'Compacted summary');
    expect(compaction.id, 'root-1:5');

    harness.push(_hookRequest('req-stop', 'stop', {
      'stop_args': {
        'response_text': 'Almost done',
        'interaction_id': 'root-1',
        'continuation_count': 1,
      },
    }));
    expect((await harness.next())['stop_result'], {
      'decision': 'continue',
      'reason': 'Continue working',
    });

    harness.push(_hookRequest('req-post-turn', 'post_turn', {
      'post_turn_args': {'response_text': 'All done'},
    }));
    expect((await harness.next())['empty_result'], {});

    harness.push(_hookRequest('req-end', 'on_session_end'));
    expect((await harness.next())['empty_result'], {});

    expect(log.entries, [
      'start',
      'pre_turn:original prompt',
      'pre_tool:view_file:/tmp/test.py',
      'post_tool:view_file:file contents',
      'on_tool_error:run_command:exit 1',
      'compaction:Compacted summary',
      'stop:Almost done',
      'post_turn:All done',
      'end',
    ]);
    expect(connection.conversationId, 'root-1');
  });

  test('post_tool parses built-in JSON results into typed results', () async {
    final log = _Log();
    final capture = _PostTool(log);
    connect(hookRunner: HookRunner(hooks: [capture]));
    harness.push(_hookRequest('r', 'post_tool', {
      'post_tool_args': {
        'tool_name': 'run_command',
        'result': '{"output": "ok"}',
      },
    }));
    await harness.next();
    expect(capture.results.single, isA<RunCommandResult>());
    expect((capture.results.single as RunCommandResult).output, 'ok');
  });

  test('question elicitations in one batch dispatch together', () async {
    final interaction = _Interaction();
    connect(root: 'conv-1', hookRunner: HookRunner(hooks: [interaction]));
    harness
      ..push(_question(10, 'conv-1-question-3-0', 'Language?'))
      ..push({'event_type': 'step.stop', 'index': 10})
      ..push(_question(11, 'conv-1-question-3-1', 'OS?'))
      ..push({'event_type': 'step.stop', 'index': 11});

    final first = await harness.next();
    final second = await harness.next();
    expect([
      first,
      second
    ], [
      {
        'event_type': 'elicitation_result',
        'elicitation_id': 'conv-1-question-3-0',
        'multiple_choice': {
          'selected_choice_labels': ['1'],
        },
      },
      {
        'event_type': 'elicitation_result',
        'elicitation_id': 'conv-1-question-3-1',
        'multiple_choice': {
          'selected_choice_labels': ['2'],
        },
      },
    ]);
    expect(interaction.batchSizes, [2]);
    expect(steps.map((s) => s.status), everyElement(StepStatus.waitingForUser));
  });

  test('questions without an interaction hook are answered as skipped',
      () async {
    connect(root: 'conv-1');
    harness.push(_question(10, 'conv-1-question-3-0', 'Language?'));
    expect(await harness.next(), {
      'event_type': 'elicitation_result',
      'elicitation_id': 'conv-1-question-3-0',
      'multiple_choice': {},
    });
  });

  test('subagent state updates do not end the turn; cancellation does',
      () async {
    final connection = connect(root: 'conv-1');
    await connection.send('go');
    await harness.next();
    harness.push({
      'event_type': 'state_update',
      'sub_interaction_id': 'sub-1',
      'parent_interaction_id': 'conv-1',
      'state': 'fully_idle',
    });
    harness.push({
      'event_type': 'state_update',
      'state': 'cancelled',
      'error': 'Turn cancelled by user',
    });
    await idle();
    expect(connection.isIdle, isTrue);
    expect(errors.single, isA<AntigravityExecutionException>());
    expect(errors.single.toString(), contains('Turn cancelled by user'));
  });

  test('denials, allow_stop, hook failures, and media results', () async {
    final log = _Log();
    connect(
      root: 'conv-1',
      hookRunner: HookRunner(hooks: [
        _PreTurn(log, allow: false),
        _PreTool(log, allow: false),
        FunctionStopHook(
            (_, __) => StopHookResult(decision: StopDecision.allowStop)),
        _PostTurn(log, fail: true),
      ]),
      toolRunner: ToolRunner(tools: [
        Tool(
          name: 'make_chart',
          description: 'Returns an image.',
          schema: const {},
          handler: (_, __) => Image(
              mimeType: 'image/png',
              description: '',
              data: utf8.encode('pngbytes')),
        ),
      ]),
    );

    harness.push(_hookRequest('req-deny-turn', 'pre_turn', {
      'pre_turn_args': {
        'user_input': {'type': 'user_input', 'content': 'x'},
      },
    }));
    expect((await harness.next())['pre_turn_result'],
        {'decision': 'deny', 'reason': 'turn blocked'});

    harness.push(_hookRequest('req-deny-tool', 'pre_tool', {
      'pre_tool_args': {
        'tool_name': 'run_command',
        'arguments_json': '{"CommandLine": "rm -rf /"}',
      },
    }));
    expect((await harness.next())['pre_tool_result'],
        {'decision': 'deny', 'reason': 'tool blocked'});

    harness.push(_hookRequest('req-allow-stop', 'stop', {
      'stop_args': {'response_text': 'Done'},
    }));
    expect((await harness.next())['stop_result'], {'decision': 'allow_stop'});

    harness.push(_hookRequest('req-err', 'post_turn', {
      'post_turn_args': {'response_text': 'Done'},
    }));
    expect((await harness.next())['error_message'], contains('boom'));

    harness.push({
      'event_type': 'function_invocation',
      'call_id': 'call-chart-1',
      'name': 'make_chart',
      'arguments': {},
    });
    final chart = await harness.next();
    expect(chart['event_type'], 'function_result');
    expect(chart['call_id'], 'call-chart-1');
    expect(chart['is_error'], isFalse);
    expect(chart['result'], {'result': null});
  });

  test('send, cancel, and disconnect run session-end hooks', () async {
    final log = _Log();
    final connection = connect(
      root: 'conv-root',
      hookRunner: HookRunner(hooks: [_SessionEnd(log)]),
    );
    expect(connection.conversationId, 'conv-root');

    await connection.send('Hello from Interactions');
    expect(await harness.next(), {
      'event_type': 'input',
      'content': [
        {'type': 'text', 'text': 'Hello from Interactions'},
      ],
    });
    await connection.cancel();
    expect(await harness.next(), {'event_type': 'interaction.cancel'});

    final disconnected = connection.disconnect();
    expect(await harness.next(), {'event_type': 'interaction.complete'});
    harness.push(_hookRequest('req-end-1', 'on_session_end'));
    expect(await harness.next(), {
      'event_type': 'call_hook_response',
      'request_id': 'req-end-1',
      'empty_result': {},
    });
    harness.push({'event_type': 'interaction.completed'});
    await disconnected.timeout(const Duration(seconds: 2));
    expect(log.entries, ['end']);
  });

  test('tool results need an id; triggers are unsupported', () async {
    final connection = connect();
    expect(() => connection.sendToolResults([ToolResult(name: 't')]),
        throwsArgumentError);
    expect(() => connection.sendTriggerNotification('ping'),
        throwsUnsupportedError);
  });

  group('InteractionsAgentConfig', () {
    test('creates an Interactions strategy and create event', () {
      final config = InteractionsAgentConfig(
        apiKey: 'test-key',
        systemInstructions: 'You are helpful.',
      );
      final strategy = config.createStrategy(
          toolRunner: ToolRunner(), hookRunner: HookRunner());
      expect(strategy, isA<InteractionsConnectionStrategy>());
      final event = (strategy as InteractionsConnectionStrategy)
          .buildCreateInteractionEventForTest();
      expect(event['event_type'], 'interaction.create');
      expect(event['agent'], 'antigravity');
      expect(event['agent_config']['type'], 'antigravity');
      expect(config.lightweight(), isA<InteractionsAgentConfig>());
      expect(config.eval(), isA<InteractionsAgentConfig>());
    });

    test('rejects auto and dynamic policies when building the event', () {
      for (final policy in [auto(), allow('run_command', when: (_) => true)]) {
        final strategy = InteractionsAgentConfig(
          apiKey: 'test-key',
          policies: [policy],
        ).createStrategy(toolRunner: ToolRunner(), hookRunner: HookRunner())
            as InteractionsConnectionStrategy;
        expect(strategy.buildCreateInteractionEventForTest,
            throwsA(isA<AntigravityValidationException>()));
      }
    });

    test('rejects triggers', () {
      expect(
          () => InteractionsAgentConfig(
              apiKey: 'test-key', triggers: [(ctx) async {}]),
          throwsA(isA<AntigravityValidationException>()));
    });
  });

  test('the handshake sets use_interactions_api (field 6)', () {
    final plain = LocalHarnessProto.encodeInputConfig(storageDirectory: '');
    final interactions = LocalHarnessProto.encodeInputConfig(
        storageDirectory: '', useInteractionsApi: true);
    expect(plain, isEmpty);
    expect(interactions, [6 << 3, 1]);
  });
}
