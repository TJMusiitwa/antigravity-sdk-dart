---
name: antigravity-multimodal-state-dart
description: "Manage thread-safe state using StateStore, persist sessions via SessionContinuationMode, or handle multimodal payloads in Dart."
---

# StateStore, Session Continuation & Multimodal Payloads in Dart

Guidelines for managing context state hierarchies, persisting agent sessions across application runs, and constructing multimodal input payloads.

## 1. Thread-Safe State Management & Session Continuation

1. **State Store Hierarchy**: Store and query shared context metadata across tools and hooks using `StateStore` with concurrent reentrancy locking.
2. **Session Continuation**: Configure `SessionContinuationMode` in `LocalAgentConfig`:
   - `SessionContinuationMode.RESUME`: Awaits and resumes an existing session ID.
   - `SessionContinuationMode.CREATE_OR_RESUME`: Resumes session if available; creates new session otherwise.
   - `SessionContinuationMode.CREATE_ONLY`: Forces fresh session creation.

For code examples, inspect [`references/state_multimodal_patterns.md`](file://references/state_multimodal_patterns.md).

## 2. Multimodal Payload Construction & Token Telemetry

- **Media Buffers**: Construct `MediaContent` from binary bytes (`Uint8List`), file paths (`fromFile`), or `Uri` endpoints with MIME type detection.
- **Token Usage Arithmetic**: Stream live `UsageUpdate` events and compute trajectory token balances using `UsageMetadata` addition (`+`) and subtraction (`-`) operators.

For implementations, read [`references/state_multimodal_patterns.md`](file://references/state_multimodal_patterns.md).

## Completion Criteria

- [ ] State mutations use `StateStore` or `context.state.set()` safely.
- [ ] `SessionContinuationMode` is declared explicitly when resuming persistent sessions.
- [ ] Multimodal attachments specify supported MIME types (`image/png`, `audio/mp4`, `application/pdf`).
