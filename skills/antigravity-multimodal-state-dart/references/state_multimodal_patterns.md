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
  sessionId: "persistent-session-uuid-1234",
  continuationMode: SessionContinuationMode.CREATE_OR_RESUME,
  systemInstructions: "You are a stateful assistant.",
);
```

## 3. Multimodal Media Content Attachment

```dart
import 'dart:io';
import 'package:antigravity/antigravity.dart';

// Create MediaContent from file
final imageFile = File('example/resources/example_image.png');
final media = MediaContent.fromFile(imageFile, mimeType: 'image/png');

// Access binary payload or URI
final Uint8List bytes = media.bytes;
final Uri? sourceUri = media.uri;
```

## 4. Live Token Usage Streaming & Arithmetic

```dart
// Compute trajectory token diff
final UsageMetadata initialUsage = conversation.lastTurnUsage ?? UsageMetadata.zero();

// Stream response and accumulate
final response = agent.chat("Generate docstring...");
final UsageMetadata finalUsage = await response.usageFuture;

final UsageMetadata turnUsage = finalUsage - initialUsage;
print("Turn spent ${turnUsage.totalTokens} tokens.");
```
