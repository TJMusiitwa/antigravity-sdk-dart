# Lifecycle Hooks & Middleware Code Patterns

Disclosed reference file containing implementations for lifecycle hooks and middleware in the Google Antigravity SDK for Dart.

## 1. Custom Pre-Turn Validation & Post-Tool Error Handling Hooks

```dart
import 'package:antigravity/antigravity.dart';

// Validate incoming user prompts before execution
class SecurityPreTurnHook extends PreTurnHook {
  @override
  Future<HookResult> run(HookContext context, ContentPrimitive data) async {
    final text = data.toString();
    if (text.contains("forbidden_keyword")) {
      return HookResult(
        allow: false,
        message: "Prompt violates configured security constraints.",
      );
    }
    return HookResult(allow: true);
  }
}

// Catch tool execution failures and supply a recovery message
class ResilientToolErrorHook extends OnToolErrorHook {
  @override
  Future<dynamic> run(HookContext context, Exception data) async {
    print("[Hook] Intercepted tool error: $data");
    // Return fallback recovery text to the model
    return "The requested tool encountered a temporary error. Please try an alternative approach.";
  }
}

// Intercept context window compaction events
class CompactionTelemetryHook extends OnCompactionHook {
  @override
  Future<void> run(HookContext context, CompactionUpdate data) async {
    print("[Hook] Context compaction event: oldTokens=${data.oldTokenCount}, newTokens=${data.newTokenCount}");
  }
}
```

## 2. Stateful Lifecycle Middleware with HookContext

```dart
import 'package:antigravity/antigravity.dart';

class MetricsPostToolCallHook extends PostToolCallHook {
  @override
  Future<void> run(HookContext context, ToolResult data) async {
    // Store custom metrics in thread-safe context state
    context.set('last_tool_call_id', data.callId ?? data.id);
    context.set('last_tool_name', data.name);
    
    print("[Hook] Completed tool: ${data.name}, result: ${data.result ?? data.error}");
  }
}
```
