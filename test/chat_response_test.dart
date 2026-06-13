import 'package:test/test.dart';
import 'package:antigravity/antigravity.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ChatResponse – textStream
  // ---------------------------------------------------------------------------
  group('ChatResponse – textStream', () {
    test('yields text from Text chunks only', () async {
      final stream = Stream.fromIterable([
        Text(stepIndex: 0, text: 'Hello'),
        Thought(stepIndex: 0, text: 'thinking...'),
        Text(stepIndex: 1, text: ' World'),
      ]);
      final response = ChatResponse(stream);
      final tokens = await response.textStream.toList();
      expect(tokens, equals(['Hello', ' World']));
    });

    test('returns empty list when stream has no Text chunks', () async {
      final stream = Stream.fromIterable([
        Thought(stepIndex: 0, text: 'just thoughts'),
      ]);
      final response = ChatResponse(stream);
      final tokens = await response.textStream.toList();
      expect(tokens, isEmpty);
    });

    test('handles empty stream', () async {
      final response = ChatResponse(const Stream.empty());
      final tokens = await response.textStream.toList();
      expect(tokens, isEmpty);
    });

    test('can be iterated multiple times independently', () async {
      final stream = Stream.fromIterable([
        Text(stepIndex: 0, text: 'A'),
        Text(stepIndex: 1, text: 'B'),
      ]);
      final response = ChatResponse(stream);
      final first = await response.textStream.toList();
      final second = await response.textStream.toList();
      expect(first, equals(second));
    });
  });

  // ---------------------------------------------------------------------------
  // ChatResponse – text()
  // ---------------------------------------------------------------------------
  group('ChatResponse – text()', () {
    test('accumulates all text chunks into a single string', () async {
      final stream = Stream.fromIterable([
        Text(stepIndex: 0, text: 'foo'),
        Text(stepIndex: 1, text: 'bar'),
        Text(stepIndex: 2, text: 'baz'),
      ]);
      final response = ChatResponse(stream);
      expect(await response.text(), equals('foobarbaz'));
    });

    test('returns empty string for stream with no text chunks', () async {
      final response = ChatResponse(const Stream.empty());
      expect(await response.text(), isEmpty);
    });

    test('preserves whitespace and newlines', () async {
      final stream = Stream.fromIterable([
        Text(stepIndex: 0, text: 'line1\n'),
        Text(stepIndex: 1, text: '  line2  '),
      ]);
      final response = ChatResponse(stream);
      expect(await response.text(), equals('line1\n  line2  '));
    });
  });

  // ---------------------------------------------------------------------------
  // ChatResponse – thoughts
  // ---------------------------------------------------------------------------
  group('ChatResponse – thoughts', () {
    test('yields only Thought chunk text', () async {
      final stream = Stream.fromIterable([
        Text(stepIndex: 0, text: 'answer'),
        Thought(stepIndex: 0, text: 'deliberation'),
        Thought(stepIndex: 1, text: 'more thinking'),
      ]);
      final response = ChatResponse(stream);
      final thoughts = await response.thoughts.toList();
      expect(thoughts, equals(['deliberation', 'more thinking']));
    });

    test('returns empty list when no Thought chunks', () async {
      final stream = Stream.fromIterable([
        Text(stepIndex: 0, text: 'only text'),
      ]);
      final response = ChatResponse(stream);
      expect(await response.thoughts.toList(), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // ChatResponse – toolCalls stream
  // ---------------------------------------------------------------------------
  group('ChatResponse – toolCalls', () {
    test('yields only ToolCall objects', () async {
      final stream = Stream.fromIterable([
        Text(stepIndex: 0, text: 'I will call a tool'),
        ToolCall(name: 'view_file', args: {'path': '/a'}),
        ToolCall(name: 'run_command', args: {'cmd': 'ls'}),
        Thought(stepIndex: 0, text: 'thinking'),
      ]);
      final response = ChatResponse(stream);
      final calls = await response.toolCalls.toList();
      expect(calls.length, equals(2));
      expect(calls[0].name, equals('view_file'));
      expect(calls[1].name, equals('run_command'));
    });

    test('returns empty list with no ToolCall chunks', () async {
      final stream = Stream.fromIterable([
        Text(stepIndex: 0, text: 'no tools'),
      ]);
      final response = ChatResponse(stream);
      expect(await response.toolCalls.toList(), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // ChatResponse – chunks (raw stream)
  // ---------------------------------------------------------------------------
  group('ChatResponse – chunks', () {
    test('yields all chunk types in order', () async {
      final text = Text(stepIndex: 0, text: 'hi');
      final thought = Thought(stepIndex: 0, text: 'hmm');
      final toolCall = ToolCall(name: 'finish');
      final stream = Stream.fromIterable([text, thought, toolCall]);
      final response = ChatResponse(stream);
      final chunks = await response.chunks.toList();
      expect(chunks.length, equals(3));
    });

    test('preserves chunk order', () async {
      final items = [
        Text(stepIndex: 0, text: 'a'),
        Text(stepIndex: 1, text: 'b'),
        Text(stepIndex: 2, text: 'c'),
      ];
      final response = ChatResponse(Stream.fromIterable(items));
      final chunks = await response.chunks.toList();
      expect((chunks[0] as Text).text, equals('a'));
      expect((chunks[1] as Text).text, equals('b'));
      expect((chunks[2] as Text).text, equals('c'));
    });
  });

  // ---------------------------------------------------------------------------
  // ChatResponse – error propagation
  // ---------------------------------------------------------------------------
  group('ChatResponse – error propagation', () {
    test('textStream re-throws stream error', () async {
      final stream = Stream<dynamic>.error(Exception('stream broke'));
      final response = ChatResponse(stream);
      expect(() => response.textStream.toList(), throwsA(isA<Exception>()));
    });

    test('text() re-throws stream error', () async {
      final stream = Stream<dynamic>.error(StateError('bad state'));
      final response = ChatResponse(stream);
      expect(() => response.text(), throwsA(isA<StateError>()));
    });
  });
}
