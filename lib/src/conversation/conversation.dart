import 'dart:async';
import 'package:logging/logging.dart';
import 'package:antigravity/antigravity.dart';

final _logger = Logger('antigravity.conversation');

/// Manages a high-level stateful interaction between a user and an agent in the Google Antigravity SDK.
class Conversation {
  final Connection _connection;
  final HookRunner? _hookRunner;
  final List<Step> _history = [];
  final List<int> _compactionIndices = [];

  /// The maximum number of processing steps retained in conversation history.
  int? maxHistorySize;
  UsageMetadata _cumulativeUsage = _zeroUsage();

  /// Creates a new [Conversation] on the given underlying connection.
  Conversation(this._connection, {HookRunner? hookRunner})
      : _hookRunner = hookRunner {
    _history.addAll(_connection.initialHistory);
    for (var i = 0; i < _connection.initialHistory.length; i++) {
      final step = _connection.initialHistory[i];
      if (step.type == StepType.compaction) {
        _compactionIndices.add(i);
      }
      if (step.usageMetadata != null) {
        _accumulateUsage(step.usageMetadata!);
      }
    }
    _enforceMaxHistory();
  }

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

  /// Returns step indices where history compaction events occurred.
  List<int> get compactionIndices => List.unmodifiable(_compactionIndices);

  /// Clears all steps and compaction indices from history.
  void clearHistory() {
    _history.clear();
    _compactionIndices.clear();
  }

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

  UsageMetadata? _turnStartUsage;
  StopReason _lastTurnStopReason = StopReason.unspecified;

  /// Returns the reason why the most recent turn stopped.
  StopReason get lastTurnStopReason => _lastTurnStopReason;

  /// Returns the total token usage for this conversation session.
  UsageMetadata get usage => _connection.cumulativeUsage.totalTokenCount != null
      ? _connection.cumulativeUsage
      : _cumulativeUsage;

  /// Returns the total token usage (alias for common examples).
  UsageMetadata get totalUsage => usage;

  /// Returns a map of trajectory ID to cumulative token usage for subagents and main agent.
  Map<String, UsageMetadata> get trajectoryUsages =>
      _connection.trajectoryUsages;

  /// Returns usage accumulated during the last turn, or null if no tokens were recorded.
  UsageMetadata? get lastTurnUsage {
    if (_turnStartUsage == null) return null;
    final currentUsage = usage;
    final diff = currentUsage - _turnStartUsage!;
    if ((diff.totalTokenCount ?? 0) == 0 &&
        (diff.promptTokenCount ?? 0) == 0 &&
        (diff.candidatesTokenCount ?? 0) == 0) {
      return null;
    }
    return diff;
  }

  /// Extracts the structured output payload from the most recent finish step.
  dynamic get lastStructuredOutput {
    for (final step in _history.reversed) {
      if (step.type == StepType.finish) {
        return step.structuredOutput;
      }
    }
    return null;
  }

  static void validatePrompt(dynamic prompt) {
    if (prompt == null) {
      throw AntigravityValidationException(
        "chat() requires non-empty message content. Got null.",
      );
    }
    if (prompt is String && prompt.trim().isEmpty) {
      throw AntigravityValidationException(
        "chat() requires a non-empty message string. Got: '$prompt'",
      );
    }
    if (prompt is Iterable) {
      if (prompt.isEmpty) {
        throw AntigravityValidationException(
          "chat() requires non-empty message content. Got an empty list.",
        );
      }
      bool allEmpty = true;
      for (final item in prompt) {
        if (item is String && item.trim().isNotEmpty) {
          allEmpty = false;
          break;
        } else if (item is Text && item.text.trim().isNotEmpty) {
          allEmpty = false;
          break;
        } else if (item != null && item is! String && item is! Text) {
          allEmpty = false;
          break;
        }
      }
      if (allEmpty) {
        throw AntigravityValidationException(
          "chat() requires non-empty message content. Got: $prompt",
        );
      }
    }
  }

  /// Sends a prompt to the agent and returns a streamable response.
  Future<ChatResponse> chat(
    ContentPrimitive? prompt, {
    Map<String, dynamic>? kwargs,
  }) async {
    validatePrompt(prompt);
    _turnStartUsage = usage;
    _lastTurnStopReason = StopReason.unspecified;

    // 2. Record user input step in history
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
    _enforceMaxHistory();

    // 3. Dispatch pre-turn hooks
    if (_hookRunner != null) {
      final res = await _hookRunner!.dispatchPreTurn(prompt);
      if (!res.allow) {
        final message = res.message.isNotEmpty
            ? res.message
            : 'Turn execution denied by hook.';
        _logger.warning("Turn denied by hook: $message");

        final canceledStep = Step(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          stepIndex: _history.length + 1,
          type: StepType.systemMessage,
          source: StepSource.system,
          target: StepTarget.user,
          status: StepStatus.canceled,
          content: '',
          error: message,
        );
        _history.add(canceledStep);

        final controller = StreamController<dynamic>();
        controller.add(canceledStep);
        unawaited(controller.close());
        return ChatResponse(controller.stream);
      }
    }

    // 4. Wrap step stream to update internal state
    final controller = StreamController<dynamic>();
    final originalStream = _connection.receiveSteps();
    final Set<String> seenToolIds = {};
    late StreamSubscription subscription;

    subscription = originalStream.listen(
      (step) {
        if (step.id == 'idle_sentinel') {
          _lastTurnStopReason = _connection.lastTurnStopReason;
          // Check for post-turn hook
          if (_hookRunner != null) {
            final ctx = _hookRunner!.createTurnContext();
            final lastTextContent =
                _history.isEmpty ? '' : _history.last.content;
            _hookRunner!.dispatchPostTurn(ctx, lastTextContent).catchError((
              Object err,
              StackTrace st,
            ) {
              _logger.severe('Error in post-turn hook: $err', err, st);
            });
          }
          unawaited(subscription.cancel());
          controller.close();
          return;
        }

        _history.add(step);
        if (step.type == StepType.compaction) {
          _compactionIndices.add(_history.length - 1);
        }
        _enforceMaxHistory();
        if (step.usageMetadata != null) {
          _accumulateUsage(step.usageMetadata!);
        }

        // Forward chunks to ChatResponse
        final isModel = step.source == StepSource.model;
        final isTargetUser = step.target == StepTarget.user;

        if (isModel && isTargetUser) {
          if (step.thinkingDelta.isNotEmpty) {
            controller.add(
              Thought(stepIndex: step.stepIndex, text: step.thinkingDelta),
            );
          }
          if (step.contentDelta.isNotEmpty) {
            controller.add(
              Text(stepIndex: step.stepIndex, text: step.contentDelta),
            );
          }
        }

        for (final call in step.toolCalls) {
          final id = call.id ?? '';
          if (id.isEmpty || !seenToolIds.contains(id)) {
            if (id.isNotEmpty) {
              seenToolIds.add(id);
            }
            controller.add(call);
          }
        }

        final isError = step.status == StepStatus.error;
        final isFinish = step.type == StepType.finish;

        final isTurnComplete = isFinish || isError;

        if (isTurnComplete) {
          _lastTurnStopReason = _connection.lastTurnStopReason;
          // Check for post-turn hook
          if (_hookRunner != null) {
            final ctx = _hookRunner!.createTurnContext();
            _hookRunner!.dispatchPostTurn(ctx, step.content).catchError((
              Object err,
              StackTrace st,
            ) {
              _logger.severe('Error in post-turn hook: $err', err, st);
            });
          }
          unawaited(subscription.cancel());
          controller.close();
        }
      },
      onError: (err) {
        controller.addError(err);
        unawaited(subscription.cancel());
        controller.close();
      },
      onDone: () {
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    // 5. Send to connection
    await _connection.send(prompt, kwargs: kwargs);

    return ChatResponse(controller.stream, conversation: this);
  }

  /// Proxies for Connection methods used in examples
  Future<void> send(ContentPrimitive? prompt, {Map<String, dynamic>? kwargs}) =>
      _connection.send(prompt, kwargs: kwargs);

  Stream<Step> receiveSteps() => _connection.receiveSteps();

  void _accumulateUsage(UsageMetadata usage) {
    _cumulativeUsage = _cumulativeUsage + usage;
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
      await _hookRunner!.dispatchSessionEnd();
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

  void _enforceMaxHistory() {
    if (maxHistorySize != null && _history.length > maxHistorySize!) {
      final toRemove = _history.length - maxHistorySize!;
      _history.removeRange(0, toRemove);
      _compactionIndices.removeWhere((idx) => idx < toRemove);
      for (var i = 0; i < _compactionIndices.length; i++) {
        _compactionIndices[i] -= toRemove;
      }
    }
  }
}
