---
name: flutter-antigravity-integration
description: "Use when integrating the Antigravity SDK into Flutter applications, binding Riverpod/StateNotifier lifecycles, or building agent UI overlays."
---

# Flutter Integration with Antigravity SDK

Pattern guidelines for integrating the Google Antigravity SDK into Flutter apps cleanly.

## 1. Agent Lifecycle Management

-   **State Management (Riverpod)**: Bind `Agent` session startup to state providers and register disposal logic via `ref.onDispose(() => agent.stop())`.
-   **App State Hooks**: Handle app suspension via `AppLifecycleListener` to pause/stop agent connections when paused.

For complete state management code, see [`examples/flutter_ui_patterns.md`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/skills/flutter-antigravity-integration/examples/flutter_ui_patterns.md).

## 2. Reactive UI & Human-in-the-Loop Dialogs

-   **Streaming Outputs**: Separate `thoughtStream` (internal reasoning) and `textStream` (final answer) into dedicated UI components using `StreamBuilder`.
-   **Interactive UI Overlays**: Wire `askUser` policy handlers to `AlertDialog` or modal sheet widgets instead of blocking CLI stdin.

For complete widget implementations, inspect [`examples/flutter_ui_patterns.md`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/skills/flutter-antigravity-integration/examples/flutter_ui_patterns.md).

## Completion Criteria

- [ ] `agent.stop()` is registered on state disposal (`ref.onDispose`) to prevent resource leaks.
- [ ] UI separates streams for thinking process and final text output.
- [ ] Interactive tool policies show non-blocking Flutter UI dialogs.
