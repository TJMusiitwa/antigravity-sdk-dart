import 'dart:async';

import '../conversation/conversation.dart';
import 'chunks.dart';
import 'config.dart';
import 'step.dart';
import 'tool_call.dart';

/// The response to a single conversation turn.
///
/// A stream of semantic chunks buffered as they arrive. Each stream getter
/// ([chunks], [textStream], [thoughts], [toolCalls]) returns an independent
/// cursor over a shared buffer. If the upstream stream fails, the error is
/// rethrown to each cursor that reaches the end of the buffer.
class ChatResponse {
  final List<dynamic> _bufferedChunks = [];
  final Completer<void> _completion = Completer<void>();
  Completer<void> _changed = Completer<void>();
  Object? _error;
  StackTrace? _errorStack;
  dynamic _structuredOutput;
  UsageMetadata? _usage;
  StopReason _stopReason = StopReason.unspecified;
  final Conversation? _conversation;
  final ChatResponse? _source;

  /// Creates a [ChatResponse] that buffers chunks from [rawStream].
  ///
  /// The optional conversation supplies [usage], [stopReason], and
  /// [structuredOutput], and is used by [cancel]. Without it, those return
  /// their empty defaults and [cancel] does nothing.
  ChatResponse(Stream<dynamic> rawStream, {Conversation? conversation})
    : this._(rawStream, conversation: conversation);

  ChatResponse._(
    Stream<dynamic> rawStream, {
    this._conversation,
    this._source,
  }) {
    rawStream.listen(
      (chunk) {
        _bufferedChunks.add(chunk);
        _notifyReaders();
      },
      onError: (Object error, StackTrace stackTrace) {
        _error = error;
        _errorStack = stackTrace;
        _finalize();
      },
      onDone: () => _finalize(),
      cancelOnError: true,
    );
  }

  void _finalize() {
    final source = _source;
    if (_error == null) {
      _structuredOutput = source == null
          ? _conversation?.lastStructuredOutput
          : source._structuredOutput;
    }
    _usage = source == null ? _conversation?.lastTurnUsage : source.usage;
    _stopReason =
        source?.stopReason ??
        _conversation?.lastTurnStopReason ??
        StopReason.unspecified;
    _completion.complete();
    _notifyReaders();
  }

  void _notifyReaders() {
    _changed.complete();
    _changed = Completer<void>();
  }

  /// Completes when this turn has finished, including after a stream error.
  Future<void> get done => _completion.future;

  void _throwIfFailed() {
    if (_error case final error?) {
      Error.throwWithStackTrace(error, _errorStack!);
    }
  }

  /// Independent async stream of raw chunks (including thoughts and tool results).
  Stream<dynamic> get chunks async* {
    int index = 0;
    while (true) {
      if (index < _bufferedChunks.length) {
        yield _bufferedChunks[index++];
      } else if (_completion.isCompleted) {
        _throwIfFailed();
        break;
      } else {
        await _changed.future;
      }
    }
  }

  /// Independent async stream generator of text tokens.
  Stream<String> get textStream =>
      chunks.where((c) => c is Text).cast<Text>().map((chunk) => chunk.text);

  /// Async helper to accumulate all response text.
  Future<String> text() async {
    final buffer = StringBuffer();
    await for (final token in textStream) {
      buffer.write(token);
    }
    return buffer.toString();
  }

  /// Independent async stream of thoughts/reasoning.
  Stream<String> get thoughts => chunks
      .where((c) => c is Thought)
      .cast<Thought>()
      .map((chunk) => chunk.text);

  /// Independent async stream of ToolCalls.
  Stream<ToolCall> get toolCalls =>
      chunks.where((c) => c is ToolCall).cast<ToolCall>();

  /// Blocks until the stream completes and returns the final structured output.
  Future<dynamic> structuredOutput() async {
    await _completion.future;
    _throwIfFailed();
    return _structuredOutput;
  }

  /// Accumulated token usage across all model invocations in this turn.
  UsageMetadata? get usage => _completion.isCompleted
      ? _usage
      : (_source?.usage ?? _conversation?.lastTurnUsage);

  /// The reason why the execution turn stopped.
  StopReason get stopReason => _completion.isCompleted
      ? _stopReason
      : _source?.stopReason ??
            _conversation?.lastTurnStopReason ??
            StopReason.unspecified;

  /// Cancels the active execution turn and halts generation.
  Future<void> cancel() async {
    if (!_completion.isCompleted && _conversation != null) {
      await _conversation.cancel();
    }
  }
}

/// Experimental workflow result with all standard response accessors.
class WorkflowResult extends ChatResponse {
  /// The path to the workflow script that was executed, when run from a
  /// script file.
  final String scriptPath;

  /// The inline workflow script source, when run from inline source.
  final String script;

  /// A brief description of the workflow run.
  final String description;

  /// The formatted workflow log and result text produced by the script.
  final String output;

  /// The final assistant response text from the workflow turn.
  final String responseText;

  /// Creates a [WorkflowResult] over [rawStream] with workflow metadata.
  WorkflowResult(
    super.rawStream, {
    super.conversation,
    this.scriptPath = '',
    this.script = '',
    this.description = '',
    this.output = '',
    this.responseText = '',
  });

  /// Creates a workflow result with the chunks and metadata of [response].
  WorkflowResult.fromResponse(
    ChatResponse response, {
    this.scriptPath = '',
    this.script = '',
    this.description = '',
    this.output = '',
    this.responseText = '',
  }) : super._(response.chunks, source: response);
}
