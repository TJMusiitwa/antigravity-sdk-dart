/// Base class for real-time semantic chunks yielded while a chat response
/// streams.
sealed class StreamChunk {
  /// The index of the step that produced this chunk.
  final int stepIndex;
  StreamChunk({required this.stepIndex});
}

/// A delta chunk holding a piece of the model's internal reasoning.
class Thought extends StreamChunk {
  /// The incremental thought text.
  final String text;

  /// The thought signature bytes, or null if none was provided.
  final List<int>? signature;

  /// Creates a [Thought] chunk.
  Thought({required super.stepIndex, required this.text, this.signature});
}

/// A delta chunk holding a piece of the model's text output.
class Text extends StreamChunk {
  /// The incremental response text.
  final String text;

  /// Creates a [Text] chunk.
  Text({required super.stepIndex, required this.text});
}
