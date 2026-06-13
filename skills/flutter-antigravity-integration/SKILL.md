---
name: flutter-antigravity-integration
description: "Guidelines for integrating the Antigravity SDK into Flutter applications, managing states, and rendering reactive outputs."
---

# Flutter Integration with Antigravity SDK

This skill provides guidelines and pattern libraries for integrating the Google Antigravity SDK into a Flutter application.

## 1. Agent Lifecycle Management

To avoid leaking system resources or binary harness processes, coordinate the `Agent` session with Flutter's state lifecycle.

### State Management Integration (e.g., Riverpod)
Expose the agent state using provider scopes and clean up the connection on disposal:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:antigravity/antigravity.dart';

part 'agent_provider.g.dart';

@riverpod
Future<Agent> activeAgent(Ref ref) async {
  final config = LocalAgentConfig(
    systemInstructions: "You are a helpful UI assistant.",
  );
  
  final agent = Agent(config);
  await agent.start();
  
  // Register cleanup when the provider is no longer watched
  ref.onDispose(() async {
    await agent.stop();
  });
  
  return agent;
}
```

### Application Lifecycle State
If the application goes to the background or is suspended, ensure agent sessions are paused or closed:
*   Use `WidgetsBindingObserver` or `AppLifecycleListener` to detect state transitions.
*   Call `agent.stop()` when the app enters `AppLifecycleState.paused` or `detached`.

---

## 2. Consuming Streaming Responses in Flutter

Antigravity returns real-time streaming deltas. For maximum UI delight, render internal "thinking" tokens and final response tokens separately.

### Reactive UI with StreamBuilder
Feed the `textStream` and `thoughtStream` directly into `StreamBuilder` widgets:

```dart
Widget buildAgentResponse(ChatResponse response) {
  return Column(
    children: [
      // 1. Thinking Process Block (Thoughts)
      StreamBuilder<String>(
        stream: response.thoughtStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          return Container(
            color: Colors.grey[200],
            child: Text("Thinking: ${snapshot.data}"),
          );
        },
      ),
      
      // 2. Final Text Output Block
      StreamBuilder<String>(
        stream: response.textStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          return Text(snapshot.data!);
        },
      ),
    ],
  );
}
```

---

## 3. Human-in-the-Loop Overlay Widgets

When safety policies require user confirmation (via the `askUser` decision) or when the agent asks questions, show interactive overlays instead of blocking on command-line stdin.

### Replacing Stdin Handler with UI Prompts
Configure policy handlers to resolve futures using UI element controllers or overlays:

```dart
Future<bool> showConfirmationDialog(BuildContext context, ToolCall tc) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Allow ${tc.name}?"),
      content: Text("The agent wishes to run a tool with arguments:\n${tc.args}"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Deny"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Allow"),
        ),
      ],
    ),
  );
  return result ?? false;
}
```
Ensure you register this async handler within `policies: [ askUser("run_command", handler: customHandler) ]`.
