import 'dart:async';
import 'dart:io';
import 'package:test/test.dart';
import 'package:antigravity/antigravity.dart';

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
  });
}

// ---------------------------------------------------------------------------
// Mocks & Fakes for testing
// ---------------------------------------------------------------------------

class FakeConnection implements Connection {
  final _stepController = StreamController<Step>.broadcast();
  bool _idle = true;
  bool _isClosed = false;
  final List<Step> _initialHistory = [];

  @override
  String get conversationId => "fake-conv-id";

  @override
  List<Step> get initialHistory => _initialHistory;

  @override
  bool get isIdle => _idle;

  @override
  Future<void> send(
    ContentPrimitive? prompt, {
    Map<String, dynamic>? kwargs,
  }) async {
    _idle = false;
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

  FakeAgentConfig(
    this.strategy, {
    super.systemInstructions,
    super.capabilities,
    super.tools,
    super.policies,
    super.hooks,
    super.triggers,
    super.responseSchema,
  });

  @override
  ConnectionStrategy createStrategy({
    required ToolRunner toolRunner,
    required HookRunner hookRunner,
  }) =>
      strategy;

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
