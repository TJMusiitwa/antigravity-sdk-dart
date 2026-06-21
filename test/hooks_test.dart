import 'package:test/test.dart';
import 'package:antigravity/antigravity.dart';

void main() {
  // ---------------------------------------------------------------------------
  // HookContext
  // ---------------------------------------------------------------------------
  group('HookContext', () {
    test('get returns defaultValue when key is not set', () {
      final ctx = HookContext();
      expect(ctx.get('missing'), isNull);
      expect(ctx.get('missing', 42), equals(42));
    });

    test('set and get work for the same key', () {
      final ctx = HookContext();
      ctx.set('key', 'value');
      expect(ctx.get('key'), equals('value'));
    });

    test('set overwrites previously stored value', () {
      final ctx = HookContext();
      ctx.set('k', 1);
      ctx.set('k', 2);
      expect(ctx.get('k'), equals(2));
    });

    test('context inherits value from parent', () {
      final parent = HookContext();
      parent.set('inherited', true);
      final child = HookContext(parent: parent);
      expect(child.get('inherited'), isTrue);
    });

    test('local key shadows parent key', () {
      final parent = HookContext();
      parent.set('key', 'parent_value');
      final child = HookContext(parent: parent);
      child.set('key', 'child_value');
      expect(child.get('key'), equals('child_value'));
    });

    test('grandparent value is reachable through two levels', () {
      final grand = HookContext();
      grand.set('deep', 'grandparent');
      final parent = HookContext(parent: grand);
      final child = HookContext(parent: parent);
      expect(child.get('deep'), equals('grandparent'));
    });

    test('context without parent has null parent', () {
      final ctx = HookContext();
      expect(ctx.parent, isNull);
    });

    test('stores values of any type', () {
      final ctx = HookContext();
      ctx.set('list', [1, 2, 3]);
      ctx.set('map', {'a': 1});
      expect(ctx.get('list'), equals([1, 2, 3]));
      expect(ctx.get('map'), equals({'a': 1}));
    });
  });

  // ---------------------------------------------------------------------------
  // SessionContext / TurnContext / OperationContext hierarchy
  // ---------------------------------------------------------------------------
  group('Context hierarchy', () {
    test('TurnContext parent is SessionContext', () {
      final session = SessionContext();
      final turn = TurnContext(session);
      expect(turn.parent, same(session));
    });

    test('OperationContext parent is TurnContext', () {
      final session = SessionContext();
      final turn = TurnContext(session);
      final op = OperationContext(turn);
      expect(op.parent, same(turn));
    });

    test('OperationContext can read from session through chain', () {
      final session = SessionContext();
      session.set('sessionKey', 'sessionValue');
      final turn = TurnContext(session);
      final op = OperationContext(turn);
      expect(op.get('sessionKey'), equals('sessionValue'));
    });

    test('TurnContext key does not leak into SessionContext', () {
      final session = SessionContext();
      final turn = TurnContext(session);
      turn.set('turnOnly', true);
      expect(session.get('turnOnly'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // HookRunner – registration and hasHooks
  // ---------------------------------------------------------------------------
  group('HookRunner – registration', () {
    test('empty runner has no hooks', () {
      final runner = HookRunner();
      expect(runner.hasHooks, isFalse);
    });

    test('registerHook registers OnSessionStartHook', () {
      final runner = HookRunner();
      final hook = _makeSessionStartHook((_) async {});
      runner.registerHook(hook);
      expect(runner.onSessionStartHooks.length, equals(1));
      expect(runner.hasHooks, isTrue);
    });

    test('registerHook registers OnSessionEndHook', () {
      final runner = HookRunner();
      final hook = _makeSessionEndHook((_) async {});
      runner.registerHook(hook);
      expect(runner.onSessionEndHooks.length, equals(1));
    });

    test('registerHook registers PostTurnHook', () {
      final runner = HookRunner();
      final hook = _makePostTurnHook((_, r) async {});
      runner.registerHook(hook);
      expect(runner.postTurnHooks.length, equals(1));
    });

    test('registerHook registers PostToolCallHook', () {
      final runner = HookRunner();
      final hook = _makePostToolCallHook((_, r) async {});
      runner.registerHook(hook);
      expect(runner.postToolCallHooks.length, equals(1));
    });

    test('registerHook registers OnCompactionHook', () {
      final runner = HookRunner();
      final hook = _makeCompactionHook((_, d) async {});
      runner.registerHook(hook);
      expect(runner.onCompactionHooks.length, equals(1));
    });

    test('registerHook throws for unknown hook type', () {
      final runner = HookRunner();
      final unknownHook = _UnknownHook();
      expect(() => runner.registerHook(unknownHook), throwsArgumentError);
    });

    test('multiple hooks can be registered for the same type', () {
      final runner = HookRunner();
      runner.registerHook(_makeSessionStartHook((_) async {}));
      runner.registerHook(_makeSessionStartHook((_) async {}));
      expect(runner.onSessionStartHooks.length, equals(2));
    });
  });

  // ---------------------------------------------------------------------------
  // HookRunner – TurnContext management
  // ---------------------------------------------------------------------------
  group('HookRunner – TurnContext', () {
    test('createTurnContext returns a TurnContext', () {
      final runner = HookRunner();
      final ctx = runner.createTurnContext();
      expect(ctx, isA<TurnContext>());
    });

    test('currentTurnContext auto-creates a TurnContext if none exists', () {
      final runner = HookRunner();
      expect(runner.currentTurnContext, isA<TurnContext>());
    });

    test('createTurnContext replaces the current TurnContext', () {
      final runner = HookRunner();
      final ctx1 = runner.createTurnContext();
      final ctx2 = runner.createTurnContext();
      expect(identical(ctx1, ctx2), isFalse);
      expect(identical(runner.currentTurnContext, ctx2), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // HookRunner – dispatch methods
  // ---------------------------------------------------------------------------
  group('HookRunner – dispatchSessionStart', () {
    test('calls all registered OnSessionStartHooks', () async {
      int callCount = 0;
      final runner = HookRunner();
      runner.registerHook(_makeSessionStartHook((_) async => callCount++));
      runner.registerHook(_makeSessionStartHook((_) async => callCount++));
      await runner.dispatchSessionStart();
      expect(callCount, equals(2));
    });

    test('does nothing with no hooks', () async {
      final runner = HookRunner();
      await runner.dispatchSessionStart(); // should not throw
    });
  });

  group('HookRunner – dispatchSessionEnd', () {
    test('calls all registered OnSessionEndHooks', () async {
      int callCount = 0;
      final runner = HookRunner();
      runner.registerHook(_makeSessionEndHook((_) async => callCount++));
      runner.registerHook(_makeSessionEndHook((_) async => callCount++));
      await runner.dispatchSessionEnd();
      expect(callCount, equals(2));
    });
  });

  group('HookRunner – dispatchPreTurn', () {
    test('returns allow=true with no hooks', () async {
      final runner = HookRunner();
      final result = await runner.dispatchPreTurn('hello');
      expect(result.allow, isTrue);
    });

    test('returns allow=true when all hooks allow', () async {
      final runner = HookRunner();
      runner.registerHook(
        _makePreTurnHook((_, d) async => HookResult(allow: true)),
      );
      runner.registerHook(
        _makePreTurnHook((_, d) async => HookResult(allow: true)),
      );
      final result = await runner.dispatchPreTurn('test');
      expect(result.allow, isTrue);
    });

    test('returns allow=false on first deny and short-circuits', () async {
      int callCount = 0;
      final runner = HookRunner();
      runner.registerHook(
        _makePreTurnHook(
          (_, d) async => HookResult(allow: false, message: 'denied'),
        ),
      );
      runner.registerHook(
        _makePreTurnHook((_, d) async {
          callCount++;
          return HookResult(allow: true);
        }),
      );
      final result = await runner.dispatchPreTurn('test');
      expect(result.allow, isFalse);
      expect(result.message, equals('denied'));
      expect(callCount, equals(0)); // short-circuited
    });

    test('handles null prompt by substituting empty string', () async {
      bool wasCalled = false;
      final runner = HookRunner();
      runner.registerHook(
        _makePreTurnHook((_, data) async {
          wasCalled = true;
          expect(data, equals(''));
          return HookResult(allow: true);
        }),
      );
      await runner.dispatchPreTurn(null);
      expect(wasCalled, isTrue);
    });
  });

  group('HookRunner – dispatchPostTurn', () {
    test(
      'calls all registered PostTurnHooks with the response string',
      () async {
        final received = <String>[];
        final runner = HookRunner();
        runner.registerHook(
          _makePostTurnHook((_, response) async => received.add(response)),
        );
        runner.registerHook(
          _makePostTurnHook((_, response) async => received.add(response)),
        );
        final turn = runner.createTurnContext();
        await runner.dispatchPostTurn(turn, 'agent response');
        expect(received, equals(['agent response', 'agent response']));
      },
    );
  });

  group('HookRunner – dispatchPreToolCall', () {
    test('returns allow=true with no hooks', () async {
      final runner = HookRunner();
      final turn = runner.createTurnContext();
      final toolCall = ToolCall(name: 'view_file', args: {});
      final result = await runner.dispatchPreToolCall(turn, toolCall);
      expect(result.allow, isTrue);
    });

    test('short-circuits on first denial', () async {
      int secondHookCalls = 0;
      final runner = HookRunner();
      runner.registerHook(
        _makePreToolCallHook(
          (_, tc) async => HookResult(allow: false, message: 'blocked'),
        ),
      );
      runner.registerHook(
        _makePreToolCallHook((_, tc) async {
          secondHookCalls++;
          return HookResult(allow: true);
        }),
      );
      final turn = runner.createTurnContext();
      final result = await runner.dispatchPreToolCall(
        turn,
        ToolCall(name: 'create_file', args: {}),
      );
      expect(result.allow, isFalse);
      expect(result.message, contains('blocked'));
      expect(secondHookCalls, equals(0));
    });
  });

  group('HookRunner – dispatchPostToolCall', () {
    test('calls all registered PostToolCallHooks', () async {
      final calls = <String>[];
      final runner = HookRunner();
      runner.registerHook(
        _makePostToolCallHook((_, result) async => calls.add(result.name)),
      );
      runner.registerHook(
        _makePostToolCallHook((_, result) async => calls.add(result.name)),
      );
      final turn = runner.createTurnContext();
      await runner.dispatchPostToolCall(
        turn,
        ToolResult(name: 'view_file', result: 'content'),
      );
      expect(calls, equals(['view_file', 'view_file']));
    });
  });

  group('HookRunner – dispatchOnToolError', () {
    test('returns null when no error hooks registered', () async {
      final runner = HookRunner();
      final turn = runner.createTurnContext();
      final result = await runner.dispatchOnToolError(turn, Exception('boom'));
      expect(result, isNull);
    });

    test('returns first non-null value from error hooks', () async {
      final runner = HookRunner();
      runner.registerHook(_makeToolErrorHook((_, e) async => 'recovered'));
      final turn = runner.createTurnContext();
      final result = await runner.dispatchOnToolError(turn, Exception('err'));
      expect(result, equals('recovered'));
    });

    test('skips hooks that throw and continues', () async {
      final runner = HookRunner();
      runner.registerHook(
        _makeToolErrorHook((_, e) async => throw Exception('hook crashed')),
      );
      runner.registerHook(_makeToolErrorHook((_, e) async => 'fallback'));
      final turn = runner.createTurnContext();
      final result = await runner.dispatchOnToolError(turn, Exception('err'));
      expect(result, equals('fallback'));
    });
  });

  group('HookRunner – dispatchInteraction', () {
    test('returns null when no interaction hooks', () async {
      final runner = HookRunner();
      final turn = runner.createTurnContext();
      final spec = AskQuestionInteractionSpec(questions: []);
      final result = await runner.dispatchInteraction(turn, spec);
      expect(result, isNull);
    });

    test('returns result from first interaction hook', () async {
      final runner = HookRunner();
      runner.registerHook(
        _makeInteractionHook((_, spec) async {
          return QuestionHookResult(responses: [], cancelled: false);
        }),
      );
      final turn = runner.createTurnContext();
      final spec = AskQuestionInteractionSpec(questions: []);
      final result = await runner.dispatchInteraction(turn, spec);
      expect(result, isNotNull);
      expect(result!.cancelled, isFalse);
    });
  });

  group('HookRunner – dispatchCompaction', () {
    test('calls all compaction hooks', () async {
      int callCount = 0;
      final runner = HookRunner();
      runner.registerHook(_makeCompactionHook((_, d) async => callCount++));
      runner.registerHook(_makeCompactionHook((_, d) async => callCount++));
      final turn = runner.createTurnContext();
      await runner.dispatchCompaction(turn, {'tokens': 1000});
      expect(callCount, equals(2));
    });
  });
}

// ---------------------------------------------------------------------------
// Test helpers – concrete anonymous hook implementations
// ---------------------------------------------------------------------------

class _UnknownHook implements Hook {}

class _SimpleSessionStartHook extends OnSessionStartHook {
  final Future<void> Function(HookContext) _fn;
  _SimpleSessionStartHook(this._fn);

  @override
  Future<void> run(HookContext context, void data) => _fn(context);
}

OnSessionStartHook _makeSessionStartHook(
  Future<void> Function(HookContext) fn,
) =>
    _SimpleSessionStartHook(fn);

class _SimpleSessionEndHook extends OnSessionEndHook {
  final Future<void> Function(HookContext) _fn;
  _SimpleSessionEndHook(this._fn);

  @override
  Future<void> run(HookContext context, void data) => _fn(context);
}

OnSessionEndHook _makeSessionEndHook(Future<void> Function(HookContext) fn) =>
    _SimpleSessionEndHook(fn);

class _SimplePostTurnHook extends PostTurnHook {
  final Future<void> Function(HookContext, String) _fn;
  _SimplePostTurnHook(this._fn);

  @override
  Future<void> run(HookContext context, String data) => _fn(context, data);
}

PostTurnHook _makePostTurnHook(Future<void> Function(HookContext, String) fn) =>
    _SimplePostTurnHook(fn);

class _SimplePreTurnHook extends PreTurnHook {
  final Future<HookResult> Function(HookContext, dynamic) _fn;
  _SimplePreTurnHook(this._fn);

  @override
  Future<HookResult> run(HookContext context, dynamic data) =>
      _fn(context, data);
}

PreTurnHook _makePreTurnHook(
  Future<HookResult> Function(HookContext, dynamic) fn,
) =>
    _SimplePreTurnHook(fn);

class _SimplePreToolCallHook extends PreToolCallDecideHook {
  final Future<HookResult> Function(HookContext, ToolCall) _fn;
  _SimplePreToolCallHook(this._fn);

  @override
  Future<HookResult> run(HookContext context, ToolCall data) =>
      _fn(context, data);
}

PreToolCallDecideHook _makePreToolCallHook(
  Future<HookResult> Function(HookContext, ToolCall) fn,
) =>
    _SimplePreToolCallHook(fn);

class _SimplePostToolCallHook extends PostToolCallHook {
  final Future<void> Function(HookContext, ToolResult) _fn;
  _SimplePostToolCallHook(this._fn);

  @override
  Future<void> run(HookContext context, ToolResult data) => _fn(context, data);
}

PostToolCallHook _makePostToolCallHook(
  Future<void> Function(HookContext, ToolResult) fn,
) =>
    _SimplePostToolCallHook(fn);

class _SimpleToolErrorHook extends OnToolErrorHook {
  final Future<dynamic> Function(HookContext, Exception) _fn;
  _SimpleToolErrorHook(this._fn);

  @override
  Future<dynamic> run(HookContext context, Exception data) =>
      _fn(context, data);
}

OnToolErrorHook _makeToolErrorHook(
  Future<dynamic> Function(HookContext, Exception) fn,
) =>
    _SimpleToolErrorHook(fn);

class _SimpleCompactionHook extends OnCompactionHook {
  final Future<void> Function(HookContext, dynamic) _fn;
  _SimpleCompactionHook(this._fn);

  @override
  Future<void> run(HookContext context, dynamic data) => _fn(context, data);
}

OnCompactionHook _makeCompactionHook(
  Future<void> Function(HookContext, dynamic) fn,
) =>
    _SimpleCompactionHook(fn);

class _SimpleInteractionHook extends OnInteractionHook {
  final Future<QuestionHookResult> Function(
    HookContext,
    AskQuestionInteractionSpec,
  ) _fn;
  _SimpleInteractionHook(this._fn);

  @override
  Future<QuestionHookResult> run(
    HookContext context,
    AskQuestionInteractionSpec data,
  ) =>
      _fn(context, data);
}

OnInteractionHook _makeInteractionHook(
  Future<QuestionHookResult> Function(HookContext, AskQuestionInteractionSpec)
      fn,
) =>
    _SimpleInteractionHook(fn);
