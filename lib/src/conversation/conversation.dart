import 'dart:async';
import 'package:antigravity/antigravity.dart';

/// Manages a high-level stateful interaction between a user and an agent.
class Conversation {
  final Connection _connection;
  final HookRunner? _hookRunner;
  final List<Step> _history = [];
  UsageMetadata _cumulativeUsage = _zeroUsage();
  UsageMetadata? _turnUsage;

  Conversation(this._connection, {HookRunner? hookRunner})
    : _hookRunner = hookRunner;

  /// Creates and starts a new conversation using the provided strategy.
  static Future<Conversation> create(
    ConnectionStrategy strategy, {
    HookRunner? hookRunner,
  }) async {
    await strategy.start();
    final conn = strategy.connect();
    return Conversation(conn, hookRunner: hookRunner);
  }

  /// Returns the underlying connection.
  Connection get connection => _connection;

  /// Returns an unmodifiable view of the conversation history.
  List<Step> get history => List.unmodifiable(_history);

  /// Returns the current conversation identifier.
  String get conversationId => _connection.conversationId;

  /// Returns the number of user/agent turns so far.
  int get turnCount =>
      _history.where((s) => s.source == StepSource.user).length;

  /// Returns the text of the last model response.
  String get lastResponse {
    final last = _history.lastWhere(
      (s) => s.type == StepType.textResponse && s.source == StepSource.model,
      orElse: () => Step(
        id: '',
        stepIndex: 0,
        type: StepType.unknown,
        source: StepSource.unknown,
        target: StepTarget.unknown,
        status: StepStatus.unknown,
      ),
    );
    return last.content;
  }

  /// Returns the total token usage for this conversation.
  UsageMetadata get usage => _cumulativeUsage;

  /// Returns the total token usage (alias for common examples).
  UsageMetadata get totalUsage => _cumulativeUsage;

  /// Returns usage for the last turn.
  UsageMetadata get lastTurnUsage => _turnUsage ?? _zeroUsage();

  /// Sends a prompt to the agent and returns a streamable response.
  Future<ChatResponse> chat(
    ContentPrimitive? prompt, {
    Map<String, dynamic>? kwargs,
  }) async {
    // 1. Reset turn usage
    _turnUsage = _zeroUsage();

    // 2. Dispatch pre-turn hooks
    if (_hookRunner != null) {
      final ctx = _hookRunner.createTurnContext();
      await _hookRunner.dispatchPreTurn(ctx);
    }

    // 3. Record user input step in history
    final userStep = Step(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      stepIndex: _history.length + 1,
      type: StepType.textResponse,
      source: StepSource.user,
      target: StepTarget.environment,
      status: StepStatus.done,
      content: prompt is String ? prompt : '[Media/Complex Input]',
    );
    _history.add(userStep);

    // 4. Send to connection
    await _connection.send(prompt, kwargs: kwargs);

    // 5. Wrap step stream to update internal state
    final controller = StreamController<dynamic>();
    final originalStream = _connection.receiveSteps();

    originalStream.listen(
      (step) {
        _history.add(step);
        if (step.usageMetadata != null) {
          _accumulateUsage(step.usageMetadata!);
        }

        // Forward to ChatResponse
        controller.add(step);

        if (step.status == StepStatus.done || step.status == StepStatus.error) {
          // Check for post-turn hook
          if (_hookRunner != null) {
            final ctx = _hookRunner.createTurnContext();
            _hookRunner.dispatchPostTurn(ctx, step.content);
          }
        }
      },
      onError: (err) => controller.addError(err),
      onDone: () => controller.close(),
    );

    return ChatResponse(controller.stream);
  }

  /// Proxies for Connection methods used in examples
  Future<void> send(ContentPrimitive? prompt, {Map<String, dynamic>? kwargs}) =>
      _connection.send(prompt, kwargs: kwargs);

  Stream<Step> receiveSteps() => _connection.receiveSteps();

  void _accumulateUsage(UsageMetadata usage) {
    _cumulativeUsage = _addUsage(_cumulativeUsage, usage);
    _turnUsage = _addUsage(_turnUsage ?? _zeroUsage(), usage);
  }

  /// Cancels the current turn in progress.
  Future<void> cancel() async => _connection.cancel();

  /// Deletes this conversation and all associated state from the backend.
  Future<void> delete() async => _connection.delete();

  /// Signals that the conversation is ready to receive input.
  void signalIdle() => _connection.signalIdle();

  /// Blocks until the conversation is idle and ready for the next turn.
  Future<void> waitForIdle() async => _connection.waitForIdle();

  /// Blocks until the conversation wakes up or the timeout is reached.
  Future<bool> waitForWakeup({double timeout = 300.0}) async =>
      _connection.waitForWakeup(timeout: timeout);

  /// Disconnects the session.
  Future<void> disconnect() async {
    // Session end hook
    if (_hookRunner != null) {
      await _hookRunner.dispatchSessionEnd();
    }
    await _connection.disconnect();
  }

  static UsageMetadata _zeroUsage() => UsageMetadata(
    promptTokenCount: 0,
    cachedContentTokenCount: 0,
    candidatesTokenCount: 0,
    thoughtsTokenCount: 0,
    totalTokenCount: 0,
  );

  UsageMetadata _addUsage(UsageMetadata a, UsageMetadata b) {
    return UsageMetadata(
      promptTokenCount: (a.promptTokenCount ?? 0) + (b.promptTokenCount ?? 0),
      cachedContentTokenCount:
          (a.cachedContentTokenCount ?? 0) + (b.cachedContentTokenCount ?? 0),
      candidatesTokenCount:
          (a.candidatesTokenCount ?? 0) + (b.candidatesTokenCount ?? 0),
      thoughtsTokenCount:
          (a.thoughtsTokenCount ?? 0) + (b.thoughtsTokenCount ?? 0),
      totalTokenCount: (a.totalTokenCount ?? 0) + (b.totalTokenCount ?? 0),
    );
  }
}
