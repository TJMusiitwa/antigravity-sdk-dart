# Lifecycle Hooks & Middleware Code Patterns

Disclosed reference file containing implementations for `HookRouter` lifecycle hooks and middleware in Dart.

## 1. Stateless Pre-Turn Validation & Post-Tool Error Handling

```dart
import 'package:antigravity/antigravity.dart';

final hooks = [
  // Validate incoming user prompts before harness dispatch
  PreTurnHook.stateless((prompt) async {
    if (prompt.contains("forbidden_keyword")) {
      return HookDecision.deny(reason: "Prompt violates security constraints.");
    }
    return HookDecision.allow();
  }),

  // Catch tool execution failures gracefully
  OnToolErrorHook.stateless((error) async {
    print("Tool ${error.toolName} failed on callId: ${error.callId}");
    return ToolErrorRecovery(
      fallbackResult: "Tool temporary failure: ${error.message}",
    );
  }),

  // Intercept context compaction events
  OnCompactionHook.stateless((compaction) async {
    print("Context compacted from ${compaction.oldTokenCount} to ${compaction.newTokenCount} tokens.");
  }),
];
```

## 2. Stateful Lifecycle Middleware with HookContext

```dart
final statefulHook = PostToolHook((context, toolResult) async {
  // Store custom metrics in thread-safe context state
  context.state.set('last_tool_call_id', toolResult.callId);
  context.state.set('last_tool_name', toolResult.name);
  
  return toolResult;
});
```
