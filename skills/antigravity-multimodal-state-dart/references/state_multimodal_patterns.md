# State Management & Multimodal Code Patterns

Disclosed reference file containing patterns for `StateStore`, `SessionContinuationMode`, and `MediaContent` in Dart.

## 1. Thread-Safe StateStore Usage

```dart
import 'package:antigravity/antigravity.dart';

final store = StateStore();

// Thread-safe state mutation with lock synchronization
await store.withLock(() async {
  final currentCount = store.get<int>('query_count') ?? 0;
  store.set('query_count', currentCount + 1);
});
```

## 2. Session Continuation Mode Configuration

```dart
final config = LocalAgentConfig(
  conversationId: "persistent-session-uuid-1234",
  sessionContinuationMode: SessionContinuationMode.createOrResume,
  systemInstructions: "You are an expert software developer managing stateful application workflows.",
);
```

## 3. Multimodal Media Content Attachment

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:antigravity/antigravity.dart';

// Create MediaContent from file (MIME type is automatically inferred)
final imageFile = File('example/resources/example_image.png');
final media = MediaContent.fromFile(imageFile, description: 'Workspace architecture diagram');

// Access binary payload or MIME details
final Uint8List bytes = media.bytes;
final String mimeType = media.mimeType;
```

## 4. Live Token Usage Streaming & Arithmetic

```dart
// Record starting usage baseline
final UsageMetadata initialUsage = agent.conversation.usage;

// Send prompt and await full response
final response = await agent.chat("Generate docstring...");
await response.text();

// Compute turn usage difference using the subtraction operator
final UsageMetadata finalUsage = agent.conversation.usage;
final UsageMetadata turnUsage = finalUsage - initialUsage;

print("Turn spent ${turnUsage.totalTokenCount ?? 0} total tokens.");
print("Prompt tokens: ${turnUsage.promptTokenCount ?? 0}, Output tokens: ${turnUsage.candidatesTokenCount ?? 0}");
```
