---
name: flutter-antigravity-integration
description: "Integrate Antigravity SDK into Flutter apps, bind Riverpod session lifecycles, or build reactive agent UI overlays."
---

# Flutter Integration with Antigravity SDK

Pattern guidelines for integrating the Google Antigravity SDK into Flutter apps cleanly.

## 1. Agent Lifecycle & Cancellation Management

- **Lifecycle Binding (Riverpod)**: Bind `Agent` session startup to state providers and register disposal cleanup via `ref.onDispose(() => agent.stop())`.
- **Turn Cancellation**: Bind user abort actions (e.g. Stop Button) directly to `agent.cancel()` to cleanly terminate ongoing streaming trajectories without unmounting the agent.
- **App State Hooks**: Intercept app state transitions with `AppLifecycleListener` to pause or stop active connections when backgrounded.

For complete state management code, see [`examples/flutter_ui_patterns.md`](file://examples/flutter_ui_patterns.md).

## 2. Reactive UI, Live Usage & Human-in-the-Loop Dialogs

- **Dual-Stream UI & Token Telemetry**: Separate `thoughtStream` (internal reasoning process) and `textStream` into distinct `StreamBuilder` widgets, and display live trajectory token counts from `UsageUpdate` events.
- **Non-Blocking Confirmation Dialogs**: Wire `askUser` policy confirmation handlers to Flutter `AlertDialog` or modal bottom sheets instead of blocking CLI standard input.

For complete widget implementations, inspect [`examples/flutter_ui_patterns.md`](file://examples/flutter_ui_patterns.md).

## Completion Criteria

- [ ] `agent.stop()` is registered on state disposal (`ref.onDispose`) to prevent socket and resource leaks.
- [ ] User abort actions trigger `agent.cancel()` cleanly during active generation.
- [ ] UI splits streams for internal reasoning (`thoughtStream`) and final text output (`textStream`).
- [ ] Policy confirmation handlers trigger non-blocking Flutter UI dialogs.


