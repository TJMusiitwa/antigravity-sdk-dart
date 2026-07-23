# Flutter UI & State Management Patterns for Antigravity SDK

Disclosed example reference containing patterns for Riverpod agent session management and reactive streaming widgets in Flutter.

## 1. Lifecycle-managed Agent Provider using Riverpod

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
  
  // Clean up resources on disposal
  ref.onDispose(() async {
    await agent.stop();
  });
  
  return agent;
}
```

## 2. Streaming Response UI Component

```dart
Widget buildAgentResponse(ChatResponse response) {
  return Column(
    children: [
      // Thought process block
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
      
      // Final response text block
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

## 3. Flutter Confirmation Dialog Handler for askUser Policies

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
