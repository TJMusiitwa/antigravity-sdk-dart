---
name: antigravity-policy-safety
description: "Use when configuring agent safety policies (allow/deny/askUser), path containment, interactive confirmation handlers, or sandboxing in Dart."
---

# Safety Policies & Sandboxing in Dart

Guidelines for configuring priority-bucketed declarative safety policies to safeguard local files and system processes.

## 1. Declarative Policy Setup

1.  **Top-Down Evaluation**: The SDK evaluates safety rules sequentially. The first matching rule dictates the decision: `allow`, `deny`, or `askUser`.
2.  **Default-Deny Fallback**: Always place a fallback rule denying all unmatched tools (`deny("*")`) at the bottom of the list.

```dart
final policies = [
  allow("view_file"),
  askUser("run_command", handler: customCliHandler),
  deny("*"),
];
```

## 2. Interactive Handlers & Sandboxing

-   **Interactive Prompts**: Implement asynchronous handlers returning `Future<bool>` to prompt users before tool execution. See [`references/safety_patterns.md`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/skills/antigravity-policy-safety/references/safety_patterns.md) for code.
-   **Path Containment**: Verify target file paths lie inside the safe workspace directory using path canonicalization. Read [`references/safety_patterns.md`](file:///Users/jonathanmusiitwa/Desktop/FLUTTER_PROJ/antigravity-sdk-dart/skills/antigravity-policy-safety/references/safety_patterns.md) for the helper function.

## Completion Criteria

- [ ] Policy list ends with an explicit fallback rule (`deny("*")`).
- [ ] Interactive handlers return clean boolean decisions without hanging on stdin.
- [ ] All workspace file operations validate path containment before reads/writes.
