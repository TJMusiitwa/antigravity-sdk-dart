import 'dart:async';

import '../conversation/conversation.dart';
import 'chunks.dart';
import 'config.dart';
import 'step.dart';
import 'tool_call.dart';

/// The response to a single conversation turn.
///
/// A stream of semantic chunks with lazy buffering. Each stream getter
/// ([chunks], [textStream], [thoughts], [toolCalls]) returns an independent
/// cursor over a shared buffer. If the upstream stream fails, the error is
/// rethrown to each cursor that reaches the end of the buffer.
class ChatResponse {
  final Stream<dynamic> _stream;
  final List<dynamic> _bufferedChunks = [];
  bool _isDone = false;
  Object? _error;
  final Conversation? _conversation;

  /// Creates a [ChatResponse] that buffers chunks from [rawStream].
  ///
  /// The optional conversation supplies [usage], [stopReason], and
  /// [structuredOutput], and is used by [cancel]. Without it, those return
  /// their empty defaults and [cancel] does nothing.
  ChatResponse(Stream<dynamic> rawStream, {this._conversation})
    : _stream = rawStream.asBroadcastStream() {
    _stream.listen(
      (chunk) {
        _bufferedChunks.add(chunk);
      },
      onError: (err) {
        _error = err;
      },
      onDone: () {
        _isDone = true;
      },
    );
  }

  /// Independent async stream of raw chunks (including thoughts and tool results).
  Stream<dynamic> get chunks async* {
    int index = 0;
    while (true) {
      if (index < _bufferedChunks.length) {
        yield _bufferedChunks[index++];
      } else if (_isDone) {
        if (_error != null) throw _error!;
        break;
      } else {
        await Future.delayed(const Duration(milliseconds: 5));
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
    await text(); // Await full stream consumption
    return _conversation?.lastStructuredOutput;
  }

  /// Accumulated token usage across all model invocations in this turn.
  UsageMetadata? get usage => _conversation?.lastTurnUsage;

  /// The reason why the execution turn stopped.
  StopReason get stopReason =>
      _conversation?.lastTurnStopReason ?? StopReason.unspecified;

  /// Cancels the active execution turn and halts generation.
  Future<void> cancel() async {
    if (!_isDone && _conversation != null) {
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
}
