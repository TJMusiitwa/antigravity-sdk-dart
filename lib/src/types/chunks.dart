sealed class StreamChunk {
  final int stepIndex;
  StreamChunk({required this.stepIndex});
}

class Thought extends StreamChunk {
  final String text;
  final List<int>? signature;

  Thought({required super.stepIndex, required this.text, this.signature});
}

class Text extends StreamChunk {
  final String text;

  Text({required super.stepIndex, required this.text});
}
