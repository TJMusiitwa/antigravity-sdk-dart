import 'dart:async';
import 'dart:io';

import 'package:antigravity/antigravity.dart';
import 'package:test/test.dart';

void main() {
  group('Agent & Conversation Mocked Tests', () {
    late FakeConnectionStrategy strategy;

    setUp(() {
      strategy = FakeConnectionStrategy();
    });

    test(
      'Agent validation error – write tools without safety policy throws',
      () async {
        final config = FakeAgentConfig(
          strategy,
          capabilities: CapabilitiesConfig(
            enabledTools: [BuiltinTools.runCommand],
          ),
          policies: const [], // Empty policies list
        );
        final agent = Agent(config);
        expect(agent.start(), throwsArgumentError);
      },
    );

    test('Agent starts successfully with allowAll policy', () async {
      final config = FakeAgentConfig(
        strategy,
        capabilities: CapabilitiesConfig(
          enabledTools: [BuiltinTools.runCommand],
        ),
        policies: [allowAll()],
      );
      final agent = Agent(config);
      await agent.start();
      expect(agent.isStarted, isTrue);
      await agent.stop();
    });

    test(
        'Agent registers the client policy hook when the harness does not '
        'evaluate policies', () async {
      final config = FakeAgentConfig(strategy, policies: [allowAll()]);
      final agent = Agent(config);
      await agent.start();
      expect(
        config.capturedHookRunner!.preToolCallDecideHooks,
        contains(isA<PolicyDecideHook>()),
      );
      await agent.stop();
    });

    test(
        'Agent skips the client policy hook when the harness evaluates '
        'policies', () async {
      final config = FakeAgentConfig(
        strategy,
        harnessPolicies: true,
        policies: [
          askUser('run_command', handler: (tc) => true),
          allowAll(),
        ],
      );
      final agent = Agent(config);
      await agent.start();
      expect(
        config.capturedHookRunner!.preToolCallDecideHooks
            .whereType<PolicyDecideHook>(),
        isEmpty,
      );
      await agent.stop();
    });

    test('Agent still validates policies evaluated by the harness', () async {
      final config = FakeAgentConfig(
        strategy,
        harnessPolicies: true,
        policies: [
          Policy(tool: 'run_command', decision: Decision.askUser),
        ],
      );
      final agent = Agent(config);
      expect(agent.start(), throwsArgumentError);
    });

    test('local configs evaluate policies in the harness', () {
      expect(LocalAgentConfig(apiKey: 'k').evaluatesPoliciesInHarness, isTrue);
      expect(
        LiteRTAgentConfig(modelPath: '/tmp/model.litertlm')
            .evaluatesPoliciesInHarness,
        isTrue,
      );
    });

    test('Conversation pre-turn hook receives prompt and allows it', () async {
      var hookCalledWithPrompt = '';
      final preHook = TestPreTurnHook((prompt) {
        hookCalledWithPrompt = prompt;
      });

      final config = FakeAgentConfig(
        strategy,
        hooks: [preHook],
        policies: [allowAll()],
      );
      final agent = Agent(config);
      await agent.start();

      await agent.chat('test_prompt_123');
      expect(hookCalledWithPrompt, equals('test_prompt_123'));
      await agent.stop();
    });

    test(
      'Conversation pre-turn hook deny halts execution and returns canceled response',
      () async {
        final preDenyHook = TestPreTurnDenyHook('Custom hook denial');

        final config = FakeAgentConfig(
          strategy,
          hooks: [preDenyHook],
          policies: [allowAll()],
        );
        final agent = Agent(config);
        await agent.start();

        final response = await agent.chat('some prompt');
        final steps = await response.chunks.toList();

        expect(steps.length, equals(1));
        expect(steps[0], isA<Step>());
        final step = steps[0] as Step;
        expect(step.status, equals(StepStatus.canceled));
        expect(step.error, equals('Custom hook denial'));

        // Check conversation history has the canceled step
        expect(
          agent.conversation.history.length,
          equals(2),
        ); // user text step + canceled step
        expect(
          agent.conversation.history[1].status,
          equals(StepStatus.canceled),
        );

        await agent.stop();
      },
    );

    test('Conversation post-turn hook executes successfully', () async {
      var postHookCalledWithResponse = '';
      final postHook = TestPostTurnHook((response) {
        postHookCalledWithResponse = response;
      });

      final config = FakeAgentConfig(
        strategy,
        hooks: [postHook],
        policies: [allowAll()],
      );
      final agent = Agent(config);
      await agent.start();

      final response = await agent.chat('hi');
      await response.text(); // Await completion

      expect(postHookCalledWithResponse, equals('Hello'));
      await agent.stop();
    });

    test('Conversation history maxHistorySize limits step growth', () async {
      final config = FakeAgentConfig(strategy, policies: [allowAll()]);
      final agent = Agent(config);
      await agent.start();

      agent.conversation.maxHistorySize = 3;

      // Make chat calls
      final r1 = await agent.chat('p1');
      await r1.text();
      // History will have user step + model steps
      expect(agent.conversation.history.length, equals(3)); // Cropped at 3

      await agent.stop();
    });

    test('Conversation history clearHistory resets history', () async {
      final config = FakeAgentConfig(strategy, policies: [allowAll()]);
      final agent = Agent(config);
      await agent.start();

      final r1 = await agent.chat('p1');
      await r1.text();

      expect(agent.conversation.history.isNotEmpty, isTrue);
      agent.conversation.clearHistory();
      expect(agent.conversation.history, isEmpty);

      await agent.stop();
    });

    test('Conversation absorbs initialHistory and metadata on start', () async {
      final mockStep1 = Step(
        id: 'hist-1',
        stepIndex: 1,
        type: StepType.textResponse,
        source: StepSource.user,
        target: StepTarget.environment,
        status: StepStatus.done,
        content: 'Pre-existing user input',
      );
      final mockStep2 = Step(
        id: 'hist-2',
        stepIndex: 2,
        type: StepType.compaction,
        source: StepSource.system,
        target: StepTarget.environment,
        status: StepStatus.done,
        usageMetadata: UsageMetadata(
          promptTokenCount: 10,
          candidatesTokenCount: 20,
          totalTokenCount: 30,
        ),
      );

      strategy.connection.initialHistory.addAll([mockStep1, mockStep2]);

      final config = FakeAgentConfig(strategy, policies: [allowAll()]);
      final agent = Agent(config);
      await agent.start();

      expect(agent.conversation.history.length, equals(2));
      expect(agent.conversation.history[0].id, equals('hist-1'));
      expect(agent.conversation.history[1].type, equals(StepType.compaction));
      expect(agent.conversation.compactionIndices, contains(1));
      expect(agent.conversation.totalUsage.promptTokenCount, equals(10));
      expect(agent.conversation.totalUsage.candidatesTokenCount, equals(20));
      expect(agent.conversation.totalUsage.totalTokenCount, equals(30));

      await agent.stop();
    });

    test(
        'Conversation.lastTurnUsage returns null before turn or when no tokens accumulated, and returns diff when tokens change',
        () async {
      final strategy = FakeConnectionStrategy();
      final config = FakeAgentConfig(strategy, policies: [allowAll()]);
      final agent = Agent(config);
      await agent.start();

      expect(agent.conversation.lastTurnUsage, isNull);

      // Trigger chat prompt validation
      expect(
        () => agent.conversation.chat(''),
        throwsA(isA<AntigravityValidationException>()),
      );

      expect(agent.conversation.trajectoryUsages, isEmpty);

      await agent.stop();
    });

    test(
        'Formats single, concurrent, compaction, and reasoning steps correctly',
        () {
      final singleToolStep = Step(
        type: StepType.toolCall,
        toolCalls: [ToolCall(name: 'view_file')],
      );
      expect(
        formatStepSpinnerMessage(singleToolStep),
        equals(
          "Running tool 'view_file'...",
        ),
      );

      final concurrentToolsStep = Step(
        type: StepType.toolCall,
        toolCalls: [ToolCall(name: 'view_file'), ToolCall(name: 'edit_file')],
      );
      expect(
        formatStepSpinnerMessage(concurrentToolsStep),
        equals(
          "Running tools 'view_file', 'edit_file'...",
        ),
      );

      final compactionStep = Step(type: StepType.compaction);
      expect(
        formatStepSpinnerMessage(compactionStep),
        equals('Compacting context...'),
      );

      final reasoningStep = Step(
        source: StepSource.model,
        thinkingDelta: 'thinking...',
      );
      expect(
        formatStepSpinnerMessage(reasoningStep),
        equals('Reasoning...'),
      );
    });
  });

  group('MediaContent fromFile and MIME verification', () {
    late File tempFile;

    setUp(() {
      tempFile = File('${Directory.systemTemp.path}/test_image.png');
      tempFile.writeAsBytesSync([1, 2, 3, 4]);
    });

    tearDown(() {
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    });

    test('Loads image correctly from file path', () {
      final media = MediaContent.fromFile(
        tempFile.path,
        description: 'Test image',
      );
      expect(media, isA<Image>());
      expect(media.mimeType, equals('image/png'));
      expect(media.description, equals('Test image'));
      expect(media.data, equals([1, 2, 3, 4]));
    });

    test('subclass fromFile loader functions correctly', () {
      final img = Image.fromFile(tempFile.path, description: 'Direct image');
      expect(img.mimeType, equals('image/png'));
      expect(img.data, equals([1, 2, 3, 4]));
    });

    test('Loads media correctly from bytes and MIME type', () {
      final media = MediaContent.fromBytes(
        [5, 6, 7, 8],
        'image/jpeg',
        description: 'Test bytes',
      );
      expect(media, isA<Image>());
      expect(media.mimeType, equals('image/jpeg'));
      expect(media.description, equals('Test bytes'));
      expect(media.data, equals([5, 6, 7, 8]));
    });

    test('Subclass MIME type validation throws on mismatch', () {
      expect(
        () => Image(mimeType: 'application/pdf', description: '', data: []),
        throwsArgumentError,
      );
    });

    test('AgentConfig.getAllCustomTools collects root and subagent tools', () {
      final fakeStrategy = FakeConnectionStrategy();
      final t1 = Tool(
        name: 'tool_one',
        description: 'First tool',
        schema: const {},
        handler: (args, ctx) async => 'res1',
      );
      final t2 = Tool(
        name: 'tool_two',
        description: 'Second tool',
        schema: const {},
        handler: (args, ctx) async => 'res2',
      );
      final config = FakeAgentConfig(
        fakeStrategy,
        tools: [t1],
        subagents: [
          SubagentConfig(
            name: 'sub1',
            description: 'Subagent 1',
            tools: [t2],
          ),
        ],
      );

      final allTools = config.getAllCustomTools();
      expect(allTools, hasLength(2));
      expect(
          allTools.map((t) => t.name), containsAll(['tool_one', 'tool_two']));
    });

    test('AgentConfig.getAllCustomTools throws on duplicate conflicting tools',
        () {
      final fakeStrategy = FakeConnectionStrategy();
      final t1 = Tool(
        name: 'conflict_tool',
        description: 'First tool',
        schema: const {},
        handler: (args, ctx) async => 'res1',
      );
      final t2 = Tool(
        name: 'conflict_tool',
        description: 'Different tool with same name',
        schema: const {},
        handler: (args, ctx) async => 'res2',
      );
      final config = FakeAgentConfig(
        fakeStrategy,
        tools: [t1],
        subagents: [
          SubagentConfig(
            name: 'sub1',
            description: 'Subagent 1',
            tools: [t2],
          ),
        ],
      );

      expect(() => config.getAllCustomTools(), throwsArgumentError);
    });

    test(
        'Conversation deduplicates compactionIndices for wire-format steps without id field',
        () {
      // Wire frames carry trajectory_id and step_index, but NO id field.
      final wireStep1Active = Step.fromMap({
        'trajectory_id': 'traj-main',
        'step_index': 5,
        'type': 'COMPACTION',
        'status': 'ACTIVE',
        'content': 'Compacting...',
      });
      final wireStep1Done = Step.fromMap({
        'trajectory_id': 'traj-main',
        'step_index': 5,
        'type': 'COMPACTION',
        'status': 'DONE',
        'content': 'Compacted 10 steps into summary',
      });
      final wireStep2Done = Step.fromMap({
        'trajectory_id': 'traj-main',
        'step_index': 12,
        'type': 'COMPACTION',
        'status': 'DONE',
        'content': 'Compacted 20 steps into summary',
      });

      final conn = FakeConnection();
      conn.initialHistory
          .addAll([wireStep1Active, wireStep1Done, wireStep2Done]);
      final conv = Conversation(conn);

      expect(conv.compactionIndices, equals([0, 2]));
    });

    test(
        'Conversation deduplicates streaming compaction steps with makeStepId fallback',
        () async {
      final conn = FakeConnection();
      conn.autoRespond = false;
      final conv = Conversation(conn);

      final response = await conv.chat('start');

      // Emit two wire-format compaction step updates (ACTIVE then DONE) for the same step index
      conn._stepController.add(Step.fromMap({
        'trajectory_id': 'traj-live',
        'step_index': 3,
        'type': 'COMPACTION',
        'status': 'ACTIVE',
        'content': 'Compacting...',
      }));
      conn._stepController.add(Step.fromMap({
        'trajectory_id': 'traj-live',
        'step_index': 3,
        'type': 'COMPACTION',
        'status': 'DONE',
        'content': 'Compacted steps into summary',
      }));
      conn._stepController.add(Step(
        id: 'finish_step',
        stepIndex: 4,
        type: StepType.finish,
        source: StepSource.system,
        target: StepTarget.environment,
        status: StepStatus.done,
        content: 'Finished',
      ));

      await response.chunks.drain();

      // Only one compaction index should be recorded
      expect(conv.compactionIndices, hasLength(1));
      expect(conv.history[conv.compactionIndices.first].stepIndex, equals(3));
    });

    test(
        'Conversation dedups a streaming compaction duplicate separated by another compaction',
        () async {
      // Discriminating case: the previous implementation compared only against
      // _compactionIndices.last, so in the sequence A, B, A the second A was
      // checked against B and slipped through. Set-based dedup catches it.
      Step compaction(String traj, int idx, String status) => Step.fromMap({
            'trajectory_id': traj,
            'step_index': idx,
            'type': 'COMPACTION',
            'status': status,
            'content': 'compaction $traj:$idx $status',
          });

      final conn = FakeConnection();
      conn.autoRespond = false;
      final conv = Conversation(conn);
      final response = await conv.chat('start');

      conn._stepController.add(compaction('traj-live', 3, 'ACTIVE')); // A
      conn._stepController.add(compaction('traj-live', 9, 'DONE')); // B
      conn._stepController.add(compaction('traj-live', 3, 'DONE')); // A again
      conn._stepController.add(Step(
        id: 'finish_step',
        stepIndex: 10,
        type: StepType.finish,
        source: StepSource.system,
        target: StepTarget.environment,
        status: StepStatus.done,
        content: 'Finished',
      ));

      await response.chunks.drain();

      // Two distinct compactions (3 and 9); the repeat of 3 must not re-index.
      expect(conv.compactionIndices, hasLength(2));
      final indexedStepIndices =
          conv.compactionIndices.map((i) => conv.history[i].stepIndex).toList();
      expect(indexedStepIndices, equals([3, 9]));
    });
  });
}

// ---------------------------------------------------------------------------
// Mocks & Fakes for testing
// ---------------------------------------------------------------------------

class FakeConnection implements Connection {
  final _stepController = StreamController<Step>.broadcast();
  bool _idle = true;
  bool _isClosed = false;
  bool autoRespond = true;
  final List<Step> _initialHistory = [];

  @override
  String get conversationId => "fake-conv-id";

  @override
  List<Step> get initialHistory => _initialHistory;

  @override
  UsageMetadata get cumulativeUsage => UsageMetadata();

  @override
  Map<String, UsageMetadata> get trajectoryUsages => const {};

  @override
  StopReason get lastTurnStopReason => StopReason.unspecified;

  @override
  bool get isIdle => _idle;

  @override
  Future<void> send(
    ContentPrimitive? prompt, {
    Map<String, dynamic>? kwargs,
  }) async {
    _idle = false;
    if (!autoRespond) return;
    // Simulate async events from WebSocket
    scheduleMicrotask(() {
      if (_isClosed) return;
      _stepController.add(
        Step(
          id: "1",
          stepIndex: 1,
          type: StepType.textResponse,
          source: StepSource.model,
          target: StepTarget.user,
          status: StepStatus.active,
          contentDelta: "Hello",
        ),
      );
      _stepController.add(
        Step(
          id: "2",
          stepIndex: 2,
          type: StepType.textResponse,
          source: StepSource.model,
          target: StepTarget.user,
          status: StepStatus.done,
          content: "Hello",
        ),
      );
      _idle = true;
      _stepController.add(
        Step(
          id: "idle_sentinel",
          stepIndex: -1,
          type: StepType.finish,
          source: StepSource.system,
          target: StepTarget.environment,
          status: StepStatus.done,
        ),
      );
    });
  }

  @override
  Stream<Step> receiveSteps() => _stepController.stream;

  @override
  Future<void> sendToolResults(List<ToolResult> results) async {}

  @override
  Future<void> sendTriggerNotification(String content) async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<void> disconnect() async {
    _isClosed = true;
    await _stepController.close();
  }

  @override
  Future<void> delete() async {}

  @override
  void signalIdle() {
    _idle = true;
  }

  @override
  Future<void> waitForIdle() async {}

  @override
  Future<bool> waitForWakeup({double timeout = 300.0}) async => true;
}

class FakeConnectionStrategy implements ConnectionStrategy {
  final FakeConnection connection = FakeConnection();
  bool started = false;

  @override
  DebugConfig? get debugConfig => null;

  @override
  Future<void> start() async {
    started = true;
  }

  @override
  Connection connect() => connection;

  @override
  Future<void> stop() async {
    started = false;
    await connection.disconnect();
  }
}

class FakeAgentConfig extends AgentConfig {
  final ConnectionStrategy strategy;
  final bool harnessPolicies;
  HookRunner? capturedHookRunner;

  FakeAgentConfig(
    this.strategy, {
    this.harnessPolicies = false,
    super.systemInstructions,
    super.capabilities,
    super.tools,
    super.policies,
    super.hooks,
    super.triggers,
    super.subagents,
    super.responseSchema,
  });

  @override
  ConnectionStrategy createStrategy({
    required ToolRunner toolRunner,
    required HookRunner hookRunner,
  }) {
    capturedHookRunner = hookRunner;
    return strategy;
  }

  @override
  bool get evaluatesPoliciesInHarness => harnessPolicies;

  @override
  AgentConfig lightweight() => throw UnimplementedError();

  @override
  AgentConfig eval({ThinkingLevel? thinkingLevel = ThinkingLevel.high}) =>
      throw UnimplementedError();

  @override
  String toJson() => throw UnimplementedError();

  @override
  Map<String, dynamic> toMap() => throw UnimplementedError();

  @override
  Never get copyWith => throw UnimplementedError();
}

class TestPreTurnHook extends PreTurnHook {
  final void Function(String) onCalled;
  TestPreTurnHook(this.onCalled);

  @override
  Future<HookResult> run(HookContext context, ContentPrimitive data) async {
    onCalled(data.toString());
    return HookResult(allow: true);
  }
}

class TestPreTurnDenyHook extends PreTurnHook {
  final String denialMessage;
  TestPreTurnDenyHook(this.denialMessage);

  @override
  Future<HookResult> run(HookContext context, ContentPrimitive data) async {
    return HookResult(allow: false, message: denialMessage);
  }
}

class TestPostTurnHook extends PostTurnHook {
  final void Function(String) onCalled;
  TestPostTurnHook(this.onCalled);

  @override
  Future<void> run(HookContext context, String data) async {
    onCalled(data);
  }
}
