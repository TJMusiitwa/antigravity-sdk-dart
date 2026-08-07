---
name: antigravity-hooks-middleware-dart
description: "Intercept agent turns, validate tool execution, handle errors, or track compaction using HookRouter lifecycle hooks in Dart."
---

# Lifecycle Hooks & Agent Middleware in Dart

Guidelines for registering harness and client-side lifecycle hooks using `HookRouter` to inspect, decide, transform, and intercept agent steps.

## 1. Registering Lifecycle Hooks

1. **Hook Router Setup**: Pass registered hooks to `LocalAgentConfig(hooks: [...])`.
2. **Turn & Tool Interception**:
   - `PreTurnHook`: Pre-validate prompts or reject turns before harness dispatch.
   - `PostTurnHook`: Inspect output tokens, state, or trajectory results.
   - `PostToolHook`: Transform or sanitize tool outputs post-execution.
   - `OnToolErrorHook`: Catch tool execution failures (`ToolExecutionException`) and provide fallback responses.
   - `OnCompactionHook`: Intercept context window compaction events.
3. **Stateless Factories**: Use `.stateless()` constructors (`FunctionInspectHook.stateless`, `FunctionDecideHook.stateless`, `FunctionTransformHook.stateless`) when context tracking is unneeded.

For complete hook implementations, inspect [`references/hooks_patterns.md`](file://references/hooks_patterns.md).

## 2. Correlation & Telemetry Tracking

- Access `callId` across `ToolCall`, `ToolResult`, and hook payloads to correlate tool operations across concurrent step turns.
- Monitor session lifecycle events via `OnSessionStartHook` and `OnSessionEndHook`.

For code patterns, consult [`references/hooks_patterns.md`](file://references/hooks_patterns.md).

## Completion Criteria

- [ ] Lifecycle hooks wrap handlers using `HookRouter` or `.stateless()` factories.
- [ ] `PreTurnHook` decisions return `HookDecision.allow()` or `HookDecision.deny()`.
- [ ] `OnToolErrorHook` catches `ToolExecutionException` without crashing the session loop.
